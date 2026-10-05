class_name NareshNote
extends Node3D

## A note Naresh left where he passed, days ahead of you (Milestone G: the
## game's instructions are in his words, `design/PUZZLE_CHANGES.md`, "The
## voice of the game"). A scrap of paper pinned up; E reads it. The story
## keeps every note read, for the journal's "Naresh's notes" page. He writes
## "we" as if his friend were with him.

var note_id := ""
var text := ""


## A note at `pos` (local to `parent`), its face turned to local +Z by
## `rot_y_deg`; readers stand in front of it.
static func make(parent: Node3D, id: String, pos: Vector3, rot_y_deg: float, body: String) -> NareshNote:
	var n := NareshNote.new()
	n.name = "NareshNote_" + id
	n.note_id = id
	n.text = body
	n.position = pos
	n.rotation_degrees = Vector3(0, rot_y_deg, 0)
	parent.add_child(n)
	return n


func _ready() -> void:
	add_to_group("naresh_note")
	var paper := ToonMat.make(Color(0.96, 0.93, 0.80), 0.006)
	add_child(Build.box(Vector3(0.24, 0.3, 0.01), paper, Vector3(0, 0, 0.012), Vector3(0, 0, 4), "Paper"))
	# a few pencil lines, so it reads as a handwritten note from a distance
	var ink := ToonMat.flat(Color(0.25, 0.25, 0.35))
	for k in 5:
		add_child(Build.box(Vector3(0.15 - (k % 2) * 0.04, 0.008, 0.004), ink, Vector3(-0.01, 0.08 - k * 0.04, 0.019), Vector3(0, 0, 4), "Line"))
	add_child(Build.sphere(0.012, ToonMat.flat(Color(0.85, 0.15, 0.12)), Vector3(0, 0.13, 0.02), Vector3.ONE, "Pin"))
	var area := Build.interact_area(Vector3(0.5, 0.5, 0.45), Vector3(0, 0, 0.2), "Read Naresh's note", func(p): read(p), "NoteArea")
	area.set_meta("tag_name", "Naresh's note")
	add_child(area)


func read(p) -> void:
	Sfx.play3d("paper_open", global_position, -6.0)
	p.say("Naresh's note, in his scrawl:\n\n\"%s\"" % text, 9.0)
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.add_note(note_id, text)
