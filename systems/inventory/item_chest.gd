class_name ItemChest
extends ApproachPrompt
## A supply crate placed on existing level geometry. E asks whether to open
## it; yes moves everything that fits into the case and reads out each item.
## What does not fit stays inside for a later visit (ChestStore).

signal collected(results: Array[Dictionary])

@export var crate_id: StringName = ChestStore.DELIVERY

func prompt_text() -> String:
	return GamepadControls.shared.interact_label() + " · Supply crate"

func interact() -> void:
	if not can_interact():
		return
	busy = true
	prompt.hide()
	if await MessageBox.say(self, ["A supply crate. Open it?"], ["No", "Yes"]) == 1:
		var results: Array[Dictionary] = ChestStore.collect(crate_id)
		await MessageBox.say(self, report(results))
		collected.emit(results)
	busy = false

## One page per item, in the order the crate held them.
static func report(results: Array[Dictionary]) -> Array:
	if results.is_empty():
		return ["The crate is empty."]
	var pages: Array = []
	for result: Dictionary in results:
		var label: String = MessageBox.item(Inventory.item_name(result["id"]))
		var stack: bool = Inventory.stack_limit(result["id"]) > 1
		if int(result["taken"]) > 0:
			pages.append("You obtained %s%s." % [label, " ×%d" % result["taken"] if stack else ""])
		if int(result["left"]) > 0:
			pages.append("There is no room in the case for %s%s.\nIt stays in the crate." % [label, " ×%d" % result["left"] if stack else ""])
	return pages
