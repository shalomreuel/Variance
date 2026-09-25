"""Legitimate deterministic offline provider implementing the production contract."""

from typing import Any


class MockProvider:
    async def text(self, operation: str, context: dict[str, Any], local_reply: str,
                   message: str, quest: dict[str, Any] | None) -> dict[str, str]:
        if local_reply.strip():
            return {"reply": local_reply}
        if operation == "chat":
            if "stronger" in message.lower() and "not stronger" not in message.lower():
                return {"reply": "Dominance is about expression in a heterozygote, not biological strength. Let's test Bb × Bb."}
            return {"reply": "An allele is a variant of a gene. In our simplified model, Bb looks dark but can still pass on b."}
        if operation == "analyze":
            latest = context.get("last_experiment", {})
            assessment = latest.get("assessment", {}) if isinstance(latest, dict) else {}
            gap = assessment.get("gap", "Review the four allele combinations with the Professor.")
            return {"reply": str(gap)[:1000]}
        if operation == "next_step" and quest:
            return {"reply": f"Next investigation: {quest['quest_title']}. {quest['objective']}"}
        return {"reply": "Let's investigate the evidence together. Start by predicting, then test the four allele combinations."}

    async def quest(self, context: dict[str, Any], safe: dict[str, Any]) -> dict[str, Any]:
        result = dict(safe)
        mastery = context.get("mastery", {})
        if isinstance(mastery, dict) and result["concept"] in mastery and mastery[result["concept"]] < 0.65:
            result["objective"] = ("Revisit a concept that needs more evidence: " + result["objective"])[:320]
        return result

    async def image(self, prompt: str) -> dict[str, str]:
        return {"status": "fallback", "reason": "Mock provider; local phenotype renderer is active"}
