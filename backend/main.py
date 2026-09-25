"""Run: python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000

Godot's native client uses http://127.0.0.1:8000/api by default. A web
export must reverse-proxy /api to this service on the SAME public origin.
"""

from fastapi import FastAPI

from backend.ai_gateway import AIGateway
from backend.schemas import (ChatRequest, ContextRequest, ImageReply, ImageRequest,
                             NextStepRequest, Quest, QuestRequest, TextReply)

app = FastAPI(title="Variant Zero AI Gateway", version="1.0.0")
gateway = AIGateway()


@app.get("/api/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "mode": gateway.mode, "provider": type(gateway.provider).__name__}


@app.post("/api/professor/chat", response_model=TextReply)
async def chat(request: ChatRequest) -> dict[str, str]:
    return await gateway.text("chat", request.context, request.local_reply, request.message)


@app.post("/api/professor/quest", response_model=Quest)
async def quest(request: QuestRequest) -> dict:
    return await gateway.quest(request.context, request.candidate_quest)


@app.post("/api/professor/analyze", response_model=TextReply)
async def analyze(request: ContextRequest) -> dict[str, str]:
    return await gateway.text("analyze", request.context, request.local_reply)


@app.post("/api/professor/next-step", response_model=TextReply)
async def next_step(request: NextStepRequest) -> dict[str, str]:
    return await gateway.text("next_step", request.context, request.local_reply, quest=request.candidate_quest)


@app.post("/api/organism/generate", response_model=ImageReply)
async def generate(request: ImageRequest) -> dict:
    return await gateway.image(request.organism, request.phenotypes)
