"""Author the original low-poly rifle visual and export its GLB, Blender source
and preview. Blender +Y forward/+Z up exports as Godot -Z forward/+Y up.
Same conventions as tools/build_pistol.py: origin at the pistol grip, a
"Muzzle" empty at the bore exit, and a "Support" empty on the handguard where
the left hand holds it. An exterior game prop, with no internal mechanism.
Run with the project's portable Blender --background --python tools/build_rifle.py.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/weapons/rifle"
SOURCE = ASSET / "source"
SOURCE.mkdir(parents=True, exist_ok=True)
(SOURCE / ".gdignore").write_text("", encoding="utf-8")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0

def material(name, color, metallic=0.0, roughness=0.8):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat

steel = material("CharcoalSteel", (0.11, 0.13, 0.15), 0.5, 0.65)
frame = material("DarkFrame", (0.055, 0.064, 0.073), 0.15, 0.85)
polymer = material("Polymer", (0.024, 0.03, 0.032), 0.0, 0.95)
edge = material("EdgeSteel", (0.22, 0.24, 0.25), 0.55, 0.65)
dark = material("Recess", (0.008, 0.011, 0.014), 0.0, 1.0)
sight = material("SightMark", (0.57, 0.60, 0.50), 0.0, 0.8)

root = bpy.data.objects.new("Rifle", None)
bpy.context.collection.objects.link(root)
parts = []

def finish(obj, name, mat):
    obj.name = name
    obj.data.materials.append(mat)
    obj.parent = root
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    parts.append(obj)
    return obj

def box(name, center, size, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("SingleFacetEdges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj, name, mat)

def profile(name, outline, width, mat):
    """Extrude an artistic silhouette in the YZ plane across X."""
    n = len(outline)
    vertices = [(x, y, z) for x in (-width / 2, width / 2) for y, z in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    return finish(obj, name, mat)

def tube(name, y0, y1, z, radius, mat, sides=8):
    """A faceted cylinder along +Y."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=y1 - y0,
                                        location=(0, (y0 + y1) / 2, z), rotation=(math.pi / 2, 0, 0))
    return finish(bpy.context.object, name, mat)

BORE = 0.062  # height of the barrel axis above the grip origin

# Receiver and stock.
box("UpperReceiver", (0, 0.045, 0.072), (0.040, 0.270, 0.042), steel, 0.003)
box("LowerReceiver", (0, 0.035, 0.036), (0.036, 0.200, 0.032), frame, 0.002)
box("TopRail", (0, 0.060, 0.098), (0.022, 0.240, 0.010), frame, 0.001)
for i in range(12):
    box("RailSlot", (0, -0.060 + i * 0.020, 0.1035), (0.024, 0.006, 0.002), dark)
box("BufferTube", (0, -0.140, 0.070), (0.030, 0.110, 0.030), frame, 0.002)
profile("Stock", [(-0.300, 0.095), (-0.180, 0.088), (-0.180, 0.050), (-0.215, 0.010),
                  (-0.300, -0.030)], 0.038, polymer)
box("ButtPad", (0, -0.304, 0.032), (0.040, 0.010, 0.128), dark, 0.002)

# Pistol grip, trigger guard and magazine.
profile("Grip", [(-0.040, -0.090), (-0.008, -0.090), (0.020, 0.024), (-0.018, 0.028)], 0.032, polymer)
profile("GuardBase", [(0.070, 0.020), (0.076, 0.012), (0.014, 0.004), (0.010, 0.012)], 0.014, frame)
profile("Trigger", [(0.040, 0.022), (0.047, 0.019), (0.040, 0.000), (0.030, -0.006), (0.033, 0.004)], 0.006, edge)
profile("Magazine", [(0.090, 0.020), (0.150, 0.020), (0.170, -0.140), (0.115, -0.150)], 0.030, polymer)
for i in range(4):
    box("MagazineRib", (0, 0.120 + i * 0.010, -0.060 - i * 0.022), (0.032, 0.004, 0.006), frame)
box("MagazineWell", (0, 0.120, 0.012), (0.038, 0.074, 0.024), frame, 0.002)
box("EjectionPort", (0.0205, 0.060, 0.074), (0.001, 0.060, 0.018), dark)
box("ChargingHandle", (0, -0.088, 0.088), (0.030, 0.014, 0.010), edge, 0.001)

# Handguard, barrel and sights.
box("Handguard", (0, 0.300, BORE), (0.044, 0.240, 0.050), frame, 0.004)
for side in (-1, 1):
    for i in range(6):
        box("HandguardVent", (side * 0.0225, 0.210 + i * 0.036, BORE), (0.001, 0.018, 0.022), dark)
box("Foregrip", (0, 0.330, 0.010), (0.026, 0.034, 0.060), polymer, 0.003)
tube("Barrel", 0.420, 0.585, BORE, 0.010, steel)
tube("GasBlock", 0.430, 0.455, BORE, 0.015, edge)
tube("FlashHider", 0.585, 0.625, BORE, 0.013, frame, 6)
box("FrontSight", (0, 0.440, 0.100), (0.010, 0.016, 0.040), frame, 0.001)
box("FrontSightMark", (0, 0.432, 0.118), (0.003, 0.0005, 0.004), sight)
box("RearSight", (0, -0.050, 0.112), (0.030, 0.020, 0.018), frame, 0.001)
box("RearSightNotch", (0, -0.060, 0.118), (0.008, 0.001, 0.006), dark)
box("MuzzleRecess", (0, 0.6255, BORE), (0.012, 0.0004, 0.012), dark)

muzzle = bpy.data.objects.new("Muzzle", None)
bpy.context.collection.objects.link(muzzle)
muzzle.parent = root
muzzle.location = (0, 0.627, BORE)
support = bpy.data.objects.new("Support", None)
bpy.context.collection.objects.link(support)
support.parent = root
support.location = (0, 0.330, 0.020)

source_parts = len(parts)
triangles = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts)
bpy.ops.object.select_all(action="DESELECT")
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
joined = bpy.context.object
joined.name = "RifleMesh"
parts = [joined]

bpy.ops.object.select_all(action="DESELECT")
for obj in [root, muzzle, support, *parts]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=str(ASSET / "rifle_lowpoly.glb"),
    export_format="GLB", use_selection=True, export_yup=True, export_cameras=False,
    export_lights=False, export_animations=False)

manifest = {"name": "LIMIAR service rifle", "triangles": triangles,
            "mesh_parts": len(parts), "authored_parts": source_parts, "materials": 6, "units": "meters",
            "godot_forward": "-Z", "godot_up": "+Y", "origin": "pistol grip",
            "muzzle_godot": [0, BORE, -0.627], "support_godot": [0, 0.020, -0.330],
            "source": "tools/build_rifle.py",
            "status": "original prototype visual; no internal mechanism"}
(ASSET / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.render.resolution_x = 1400
scene.render.resolution_y = 700
scene.render.resolution_percentage = 100
scene.world.color = (0.08, 0.08, 0.08)
scene.view_settings.view_transform = "Standard"
scene.render.image_settings.file_format = "PNG"

def aim_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()

bpy.ops.object.camera_add(location=(0.9, 0.35, 0.30))
camera = bpy.context.object
camera.name = "PreviewCamera"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 1.05
aim_at(camera, (0, 0.16, 0.0))
scene.camera = camera
for location, power, size in [((0.6, 0.3, 0.6), 3.0, 0.8), ((-0.5, -0.2, 0.3), 1.2, 0.5),
                              ((0.2, -0.6, 0.4), 2.0, 0.4)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    lamp = bpy.context.object
    lamp.data.energy = power
    lamp.data.shape = "DISK"
    lamp.data.size = size
    aim_at(lamp, (0, 0.15, 0))

scene.render.filepath = str(ASSET / "rifle_preview.png")
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "rifle.blend"))
bpy.ops.render.render(write_still=True)
print("RIFLE triangles=%d parts=%d" % (triangles, source_parts))
