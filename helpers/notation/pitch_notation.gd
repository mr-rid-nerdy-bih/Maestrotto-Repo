class_name PitchNotation
extends Resource
## Notation for a note's pitch, e.g. C4. Stored on an item under the "pitch" key.

## Pitch name, matching the constants in Pitches (C, CS, D ... B).
@export_enum("C", "CS", "D", "DS", "E", "F", "FS", "G", "GS", "A", "AS", "B") var pitch: String = "C"
## Octave (4 = the octave of middle C).
@export_range(0, 8) var octave: int = 4

## Semitone within the octave, 0-11.
func get_semitone() -> int:
	return Pitches.to_semitone(StringName(pitch))

## MIDI note number (C4 = 60).
func get_midi() -> int:
	return (octave + 1) * 12 + get_semitone()

## Readable name like "C4" or "CS4", used in debug output.
func _to_string() -> String:
	return "%s%d" % [pitch, octave]
