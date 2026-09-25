# Variant Zero

A local-first Godot 4.6 genetics learning game. Walk to a Professor, make a hypothesis, accept a quest, walk to the workstation, build two dogs, predict offspring, run a deterministic four-cell cross, compare results, then return to the Professor for a targeted follow-up.

## Play

1. Open `project.godot` in **Godot 4.6** and press **F5** to run the project (or `godot --path .`). Press **Enter** or click **ENTER THE LAB**.
2. **WASD** to move, **E** near the Professor or computer to interact, **Esc** to close an overlay. Furniture and walls have collision.
3. Answer the Professor's question (type or use a suggested answer). Read and **accept** the generated quest.
4. Walk to the computer and press **E**. Use the six-gene library to modify the parent dog and the second-parent selector to edit the active quest gene. The displayed phenotype and locally rendered dog update immediately.
5. Move the prediction slider, **LOCK PREDICTION**, then **RUN SIMULATION**. Read all four offspring slots, exact genotype/phenotype distributions, your prediction, scoring rubric and any evidence-supported concept gap.
6. Return to the floor, walk back to the Professor, discuss the evidence, plan/accept a deeper or remedial quest and repeat.

**No backend or AI account is necessary.** If the backend is down, the Professor uses local lessons/quests, the dog uses a local renderer and all genetics, scoring and persistence continue to work. Saves are in Godot's `user://variant_zero_profile.json`.

## Science and learning design

`data/genes.json` defines six paired alleles, phenotype labels and visual descriptors. `scripts/genetics_engine.gd` validates genotypes and enumerates the four equally likely allele pairings. `scripts/learner_model.gd` scores a prediction as `100 − half the total absolute percentage error`, then uses an explicit rubric: **70% prediction accuracy + 20% assigned-cross adherence + 10% valid alleles**. Only attempts at the assigned cross update concept mastery; untested concepts display **—**, not fabricated percentages. A 0% recessive prediction despite a possible recessive offspring is recorded only as a **possible** misconception. Explicit written answers provide stronger evidence. Quest progression in `scripts/quest_manager.gd` uses these observations, while `scripts/concept_graph.gd` declares prerequisites through evolution.

**Important:** This is a *simplified fictional single-gene dog model for teaching*, not a claim that real canine fur, ears, eyes, etc. each follow one Mendelian locus. Many such traits are polygenic or environmentally influenced. Each simulation crosses **one quest trait**; other visual traits are held constant. Punnett-square percentages express probabilities, not guaranteed litter counts.

## Optional AI gateway

Godot calls only `AIManager → /api/...`. It never talks to Hugging Face directly and never contains an API credential. The optional FastAPI gateway validates JSON, locks quest biology to the local quest catalog and falls back to the mock provider when responses fail validation or a provider is unavailable. AI supplies only mentor wording / optional dog artwork, **never** the genetic outcome or score.

```bash
python3 -m venv .venv
.venv/bin/pip install -r backend/requirements.txt
AI_MODE=mock .venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
# Optional: GET http://127.0.0.1:8000/api/health
```

Provider selection is **backend-only**: `AI_MODE=mock` (default), `AI_MODE=huggingface`, or `AI_MODE=production` with `VZ_PRODUCTION_PROVIDER=huggingface`. For authorized Hugging Face inference, set `HF_TOKEN` and `HF_TEXT_MODEL` in your **private backend environment**, and optionally `HF_IMAGE_MODEL` for a pixel-art preview. Without these, fallback remains fully playable. There is **no hardcoded model**. Never commit a populated `.env` file; `backend/.env.example` documents variable names only.

A native Godot client defaults to `http://127.0.0.1:8000/api`; set `VZ_BACKEND_URL` if running elsewhere. A web export uses its **own public origin** and expects `/api` to be reverse-proxied to the backend. Never point browser-side requests at localhost. Backend endpoints:

- `POST /api/professor/chat`
- `POST /api/professor/quest`
- `POST /api/professor/analyze`
- `POST /api/professor/next-step`
- `POST /api/organism/generate`
- `GET /api/health`

## Verify

```bash
.venv/bin/pip install pytest httpx gdtoolkit
.venv/bin/python -m pytest -q backend/tests
.venv/bin/gdparse scripts/*.gd tests/*.gd
# With Godot 4.6 installed:
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/genetics_test.gd
# Isolate user:// before running a destructive automated loop test:
XDG_DATA_HOME=/tmp/vz-smoke godot --headless --path . --script tests/smoke_loop.gd
XDG_DATA_HOME=/tmp/vz-smoke godot --headless --path . --script tests/persistence_test.gd
```

See [`docs/PROJECT_AUDIT.md`](docs/PROJECT_AUDIT.md) for the original repository audit. No generated images, model output, save profiles or credentials are committed.
