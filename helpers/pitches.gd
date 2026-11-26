@tool
class_name Pitches
extends RefCounted
## Constants and semitone lookups for musical pitches.

const C: StringName = &"C"
const CS: StringName = &"CS"
const D: StringName = &"D"
const DS: StringName = &"DS"
const E: StringName = &"E"
const F: StringName = &"F"
const FS: StringName = &"FS"
const G: StringName = &"G"
const GS: StringName = &"GS"
const A: StringName = &"A"
const AS: StringName = &"AS"
const B: StringName = &"B"

const ORDER: Array[StringName] = [
	C, CS, D, DS, E, F, FS, G, GS, A, AS, B
]

const SEMITONES: Dictionary = {
	C: 0,
	CS: 1,
	D: 2,
	DS: 3,
	E: 4,
	F: 5,
	FS: 6,
	G: 7,
	GS: 8,
	A: 9,
	AS: 10,
	B: 11,
}

## Converts a pitch StringName to its semitone index (0-11). Returns -1 if invalid.
static func to_semitone(pitch: StringName) -> int:
	return SEMITONES.get(pitch, -1)

## Converts a semitone index to a pitch StringName (wraps octaves automatically).
static func from_semitone(semitone: int) -> StringName:
	return ORDER[posmod(semitone, 12)]
