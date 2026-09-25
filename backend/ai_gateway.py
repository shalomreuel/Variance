"""Central boundary: validate provider output, preserve deterministic lab settings.

No LLM response is allowed to supply probabilities, genotypes or phenotype rules.
"""

import json
import logging
import os
from pathlib import Path
from typing import Any

from pydantic import ValidationError

from backend.providers.mock_provider import MockProvider
from backend.schemas import ImageReply, Quest, TextReply

LOG = logging.getLogger(__name__)
ROOT = Path(__file__).resolve().parent.parent
QUESTS: dict[str, Any] = json.loads((ROOT / "data" / "quests.json").read_text(encoding="utf8"))
GENES: dict[str, Any] = json.loads((ROOT / "data" / "genes.json").read_text(encoding="utf8"))


def safe_quest(candidate: dict[str, Any]) -> dict[str, Any]:
    """Allow only a known, valid quest. The science fields come from disk."""
    identifier = candidate.get("quest_id", "dominance_intro")
    template = QUESTS.get(identifier, QUESTS["dominance_intro"])
    try:
        original = Quest.model_validate(template)
        supplied = Quest.model_validate(candidate)
        if (supplied.quest_id != original.quest_id or
                supplied.concept != original.concept or
                supplied.difficulty != original.difficulty or
                supplied.lab_task != original.lab_task):
            return original.model_dump(mode="json")
        # Valid client copy: allow its previously approved wording, never its biology.
        safe = original.model_dump(mode="json")
        for field in ("quest_title", "objective", "question"):
            safe[field] = getattr(supplied, field)
        return safe
    except ValidationError:
        return Quest.model_validate(template).model_dump(mode="json")


def safe_image_prompt(organism: str, phenotypes: dict[str, str]) -> str | None:
    if organism != "dog":
        return None
    traits = {item["id"]: item for item in GENES["traits"]}
    if set(phenotypes) != set(traits):
        return None
    for trait_id, value in phenotypes.items():
        if value not in traits[trait_id]["phenotypes"].values():
            return None
    # This is an art instruction. The provided phenotypes were already determined
    # by the Godot genetics engine; the image provider cannot alter them.
    descriptors = ", ".join(phenotypes[key].lower() for key in traits)
    return (f"single centered dog sprite, {descriptors}, retro educational genetics game, "
            "crisp pixel art, clean silhouette, plain background, one character, no text")


class AIGateway:
    def __init__(self) -> None:
        self.mock = MockProvider()
        mode = os.getenv("AI_MODE", "mock").lower()
        if mode not in {"mock", "huggingface", "production"}:
            LOG.warning("Unknown AI_MODE; using local mock")
            mode = "mock"
        selected = os.getenv("VZ_PRODUCTION_PROVIDER", "mock").lower() if mode == "production" else mode
        if selected == "huggingface":
            try:
                from backend.providers.huggingface_provider import HuggingFaceProvider
                self.provider = HuggingFaceProvider()
            except ImportError:
                LOG.warning("Hugging Face SDK not installed; running with mock provider")
                self.provider = self.mock
        else:
            self.provider = self.mock
        self.mode = mode

    async def text(self, operation: str, context: dict[str, Any], local_reply: str, message: str = "", quest: dict[str, Any] | None = None) -> dict[str, str]:
        safe = safe_quest(quest or {}) if quest else None
        fallback = await self.mock.text(operation, context, local_reply, message, safe)
        try:
            result = await self.provider.text(operation, context, local_reply, message, safe)
            return TextReply.model_validate(result).model_dump()
        except (Exception,):
            LOG.warning("AI text provider unavailable/invalid; returning local lesson", exc_info=False)
            return TextReply.model_validate(fallback).model_dump()

    async def quest(self, context: dict[str, Any], candidate: dict[str, Any]) -> dict[str, Any]:
        safe = safe_quest(candidate)
        try:
            result = await self.provider.quest(context, safe)
            proposed = Quest.model_validate(result)
            # An AI can edit prose ONLY. A valid-looking but changed cross is rejected.
            if (proposed.quest_id != safe["quest_id"] or proposed.concept != safe["concept"] or
                    proposed.difficulty != safe["difficulty"] or proposed.lab_task.model_dump(mode="json") != safe["lab_task"]):
                raise ValueError("Provider attempted to change a scientific quest field")
            answer = dict(safe)
            for key in ("quest_title", "objective", "question"):
                answer[key] = getattr(proposed, key)
            return answer
        except (Exception,):
            LOG.warning("AI quest provider unavailable/invalid; returning safe predefined quest", exc_info=False)
            return safe

    async def image(self, organism: str, phenotypes: dict[str, str]) -> dict[str, Any]:
        prompt = safe_image_prompt(organism, phenotypes)
        if prompt is None:
            return ImageReply(status="fallback", reason="Invalid phenotype selection").model_dump(exclude_none=True)
        try:
            result = await self.provider.image(prompt)
            response = ImageReply.model_validate(result)
            if response.status == "generated" and (not response.image_base64 or len(response.image_base64) > 6_000_000):
                raise ValueError("Missing or oversized image")
            return response.model_dump(exclude_none=True)
        except (Exception,):
            LOG.warning("Image provider unavailable; Godot will display its local dog", exc_info=False)
            return ImageReply(status="fallback", reason="Local phenotype preview available").model_dump(exclude_none=True)
