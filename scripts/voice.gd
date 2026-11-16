class_name VoiceHooks
extends RefCounted
# Optional service boundary. No microphone capture or network transport is active.
var capture_enabled := false
var push_to_talk := false
var muted_peers: Dictionary = {}
var head_positions: Dictionary = {}
const STATUS := "Voice unavailable — hooks only"
func gain_at(distance: float) -> float:
 return clampf((20.0-distance)/18.0,0.0,1.0)
func speaking(_peer: int) -> bool:
 return false
