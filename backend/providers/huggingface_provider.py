"""Authorized Hugging Face integration. Credentials and models live ONLY here/env."""

import asyncio
import base64
import io
import json
import os
from pathlib import Path
from typing import Any

from huggingface_hub import InferenceClient

PROMPT = (Path(__file__).resolve().parents[1] / "prompts" / "professor.txt").read_text(encoding="utf8")


class HuggingFaceProvider:
    def __init__(self) -> None:
        self.token = os.getenv("HF_TOKEN", "")
        self.text_model = os.getenv("HF_TEXT_MODEL", "")
        self.image_model = os.getenv("HF_IMAGE_MODEL", "")

    def _text_response(self, system: str, details: dict[str, Any]) -> dict[str, Any]:
        if not self.token or not self.text_model:
            raise RuntimeError("HF_TOKEN and HF_TEXT_MODEL must be set on the backend")
        client = InferenceClient(token=self.token)
        response = client.chat_completion(
            model=self.text_model,
            messages=[{"role": "system", "content": system},
                      {"role": "user", "content": json.dumps(details, ensure_ascii=False, default=str)}],
            max_tokens=420,
            temperature=0.2,
        )
        content = response.choices[0].message.content
        if not isinstance(content, str):
            raise ValueError("No text from Hugging Face")
        # JSON fences are common despite the JSON-only instruction.
        clean = content.strip()
        if clean.startswith("```"):
            clean = clean.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
        parsed = json.loads(clean)
        if not isinstance(parsed, dict):
            raise ValueError("Expected JSON object")
        return parsed

    async def text(self, operation: str, context: dict[str, Any], local_reply: str,
                   message: str, quest: dict[str, Any] | None) -> dict[str, Any]:
        details = {"purpose": operation, "learner_state": context,
                   "student_answer": message, "local_science_grounded_reply": local_reply,
                   "next_safe_quest": quest}
        return await asyncio.wait_for(asyncio.to_thread(self._text_response, PROMPT, details), timeout=14)

    async def quest(self, context: dict[str, Any], safe: dict[str, Any]) -> dict[str, Any]:
        instruction = (PROMPT + "\nFor this request ONLY, return a JSON object with exactly three string keys: "
                       "quest_title, objective, question. Reword the supplied safe quest for this learner; "
                       "do NOT change which parents, alleles, trait or cross the lab will use.")
        details = {"learner_state": context, "quest_to_reword": safe}
        words = await asyncio.wait_for(asyncio.to_thread(self._text_response, instruction, details), timeout=14)
        if not all(isinstance(words.get(key), str) and words[key].strip() for key in ("quest_title", "objective", "question")):
            raise ValueError("Malformed quest wording")
        result = dict(safe)
        for key in ("quest_title", "objective", "question"):
            result[key] = words[key].strip()
        return result

    def _image_response(self, prompt: str) -> dict[str, str]:
        if not self.token or not self.image_model:
            raise RuntimeError("HF_TOKEN and HF_IMAGE_MODEL must be set on the backend")
        client = InferenceClient(token=self.token)
        image = client.text_to_image(prompt, model=self.image_model)
        image.thumbnail((512, 512))
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        return {"status": "generated", "image_base64": base64.b64encode(buffer.getvalue()).decode("ascii")}

    async def image(self, prompt: str) -> dict[str, str]:
        return await asyncio.wait_for(asyncio.to_thread(self._image_response, prompt), timeout=15)
