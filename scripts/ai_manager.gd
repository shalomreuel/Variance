extends Node
## The ONLY Godot gateway for optional text/image requests. No provider SDK, token or model here.
## Local science/quest selection is always authoritative; network responses are advisory.

var last_source: String = "local"

func _base_url() -> String:
	var configured: String = OS.get_environment("VZ_BACKEND_URL").strip_edges()
	if not configured.is_empty():
		return configured.trim_suffix("/")
	if OS.has_feature("web"):
		# This singleton exists on web builds only. Keep native GDScript parseable.
		# Web exports must use their public origin and reverse-proxy /api.
		if Engine.has_singleton("JavaScriptBridge"):
			return str(Engine.get_singleton("JavaScriptBridge").call("eval", "window.location.origin")) + "/api"
		return "/api" # Fail locally; NEVER try the visitor's localhost.
	return "http://127.0.0.1:8000/api"

func request_chat(context: Dictionary, answer: String, local_reply: String, done: Callable) -> void:
	_send("/professor/chat", {"context": context, "message": answer, "local_reply": local_reply}, {"reply": local_reply}, done, "text")

func request_quest(context: Dictionary, safe_quest: Dictionary, done: Callable) -> void:
	_send("/professor/quest", {"context": context, "candidate_quest": safe_quest}, safe_quest, done, "quest")

func request_analyze(context: Dictionary, local_reply: String, done: Callable) -> void:
	_send("/professor/analyze", {"context": context, "local_reply": local_reply}, {"reply": local_reply}, done, "text")

func request_next_step(context: Dictionary, safe_quest: Dictionary, local_reply: String, done: Callable) -> void:
	_send("/professor/next-step", {"context": context, "candidate_quest": safe_quest, "local_reply": local_reply}, {"reply": local_reply}, done, "text")

func request_image(phenotypes: Dictionary, done: Callable) -> void:
	_send("/organism/generate", {"organism": "dog", "phenotypes": phenotypes}, {"status": "fallback"}, done, "image")

func _send(path: String, payload: Dictionary, fallback: Dictionary, done: Callable, kind: String) -> void:
	var request := HTTPRequest.new()
	request.timeout = 16.0 if kind == "image" else 5.0
	add_child(request)
	request.request_completed.connect(_on_response.bind(request, fallback, done, kind))
	var error: Error = request.request(_base_url() + path, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		last_source = "local"
		if done.is_valid():
			done.call(fallback)

func _on_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, fallback: Dictionary, done: Callable, kind: String) -> void:
	request.queue_free()
	var value: Dictionary = fallback
	last_source = "local"
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Dictionary:
			match kind:
				"quest":
					var checked: Dictionary = GameState.quest_manager.validate_response(parsed, fallback, GameState.genetics)
					value = checked
					last_source = "gateway" if checked != fallback else "local"
				"text":
					if parsed.get("reply") is String and not str(parsed["reply"]).strip_edges().is_empty() and str(parsed["reply"]).length() <= 1800:
						value = {"reply": str(parsed["reply"])}
						last_source = "gateway"
				"image":
					if parsed.get("status") == "generated" and parsed.get("image_base64") is String and str(parsed["image_base64"]).length() < 6000000:
						value = parsed
						last_source = "gateway"
	if done.is_valid():
		done.call(value)
