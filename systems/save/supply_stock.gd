class_name SupplyStock
extends RefCounted
## Terminal supplies. Purchases change real stock; SAVE records it with progress.
## Combat/use of these supplies is outside the current exploration prototype.
const ITEMS: Array[Dictionary] = [
	{"name": "AMMO", "price": 300, "description": "30 CARTUCHOS", "kind": "ammo"},
	{"name": "MED KIT", "price": 500, "description": "1 KIT MÉDICO", "kind": "med_kits"},
	{"name": "WEAPON", "price": 1800, "description": "PISTOLA", "kind": "weapon"},
]
static var credits: int = 2400
static var ammo: int = 90
static var med_kits: int = 0
static var weapon: bool = false
static var loaded: bool = false

static func ensure_loaded() -> void:
	if not loaded:
		loaded = true
		restore(SaveGame.read().get("supplies", {}))

static func restore(value: Variant) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	credits = clampi(int(data.get("credits", 2400)), 0, 999999)
	ammo = clampi(int(data.get("ammo", 90)), 0, 9999)
	med_kits = clampi(int(data.get("med_kits", 0)), 0, 99)
	weapon = bool(data.get("weapon", false))
	loaded = true

static func snapshot() -> Dictionary:
	ensure_loaded()
	return {"credits": credits, "ammo": ammo, "med_kits": med_kits, "weapon": weapon}

static func reset() -> void:
	restore({})

static func available(index: int) -> bool:
	ensure_loaded()
	if index < 0 or index >= ITEMS.size():
		return false
	if credits < int(ITEMS[index]["price"]):
		return false
	return ammo <= 9969 if index == 0 else (med_kits < 99 if index == 1 else not weapon)

static func buy(index: int) -> bool:
	if not available(index):
		return false
	credits -= int(ITEMS[index]["price"])
	match index:
		0: ammo += 30
		1: med_kits += 1
		2: weapon = true
	return true

static func quantity(index: int) -> String:
	match index:
		0: return "%d CARTUCHOS" % ammo
		1: return "%d KITS" % med_kits
		2: return "ADQUIRIDA" if weapon else "NÃO ADQUIRIDA"
	return ""
