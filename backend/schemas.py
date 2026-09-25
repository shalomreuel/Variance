"""The public /api contract. Content is validated before it reaches the game."""

from typing import Any, Literal

from pydantic import BaseModel, Field


class Parent(BaseModel):
    genotype: str = Field(min_length=2, max_length=2, pattern=r"^[A-Za-z]{2}$")


class LabTask(BaseModel):
    type: Literal["inheritance"]
    trait: str = Field(pattern=r"^[a-z_]+$")
    parents: tuple[Parent, Parent]


class Quest(BaseModel):
    concept: str = Field(min_length=2, max_length=40)
    quest_id: str = Field(min_length=2, max_length=64)
    quest_title: str = Field(min_length=2, max_length=100)
    difficulty: int = Field(ge=1, le=10)
    objective: str = Field(min_length=2, max_length=320)
    question: str = Field(min_length=2, max_length=320)
    misconception_target: str = Field(default="", max_length=80)
    lab_task: LabTask
    next_concept: str = Field(default="", max_length=80)
    lesson: str = Field(default="", max_length=500)


class ContextRequest(BaseModel):
    context: dict[str, Any] = Field(default_factory=dict)
    local_reply: str = Field(default="", max_length=1800)


class ChatRequest(ContextRequest):
    message: str = Field(max_length=600)


class QuestRequest(BaseModel):
    context: dict[str, Any] = Field(default_factory=dict)
    candidate_quest: dict[str, Any] = Field(default_factory=dict)


class NextStepRequest(ContextRequest):
    candidate_quest: dict[str, Any] = Field(default_factory=dict)


class TextReply(BaseModel):
    reply: str = Field(min_length=1, max_length=1800)


class ImageRequest(BaseModel):
    organism: Literal["dog"]
    phenotypes: dict[str, str] = Field(min_length=1, max_length=6)


class ImageReply(BaseModel):
    status: Literal["generated", "fallback"]
    image_base64: str | None = None
    reason: str | None = None
