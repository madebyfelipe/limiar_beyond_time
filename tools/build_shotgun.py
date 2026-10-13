"""Author the original low-poly double-barrel shotgun visual and export its GLB,
Blender source and preview. Blender +Y forward/+Z up exports as Godot -Z
forward/+Y up. Same conventions as tools/build_rifle.py, so the rifle captures
hold it the same way: origin at the grip, a "Muzzle" empty between the two bore
exits, and a "Support" empty on the forend where the left hand holds it. An
exterior game prop, with no internal mechanism.
Run with the project's portable Blender --background --python tools/build_shotgun.py.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/weapons/shotgun"
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

steel = material("BluedSteel", (0.07, 0.08, 0.10), 0.6, 0.55)
frame = material("CaseFrame", (0.20, 0.19, 0.17), 0.55, 0.6)
wood = material("Walnut", (0.17, 0.075, 0.035), 0.0, 0.7)
edge = material("EdgeSteel", (0.22, 0.24, 0.25), 0.55, 0.65)
dark = material("Recess", (0.008, 0.011, 0.014), 0.0, 1.0)
sight = material("BeadSight", (0.72, 0.66, 0.45), 0.4, 0.5)

root = bpy.data.objects.new("Shotgun", None)
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

BORE = 0.062  # height of the barrel axes above the grip origin
GAUGE = 0.0105  # each barrel's half-spacing across X

# Action (receiver) with its top lever, and the walnut stock behind it.
box("Action", (0, 0.060, 0.058), (0.046, 0.110, 0.050), frame, 0.004)
box("ActionFloor", (0, 0.070, 0.028), (0.040, 0.090, 0.014), frame, 0.002)
box("TopLever", (0, 0.010, 0.088), (0.012, 0.040, 0.006), edge, 0.001)
box("TopTang", (0, -0.020, 0.080), (0.016, 0.060, 0.006), frame, 0.001)
for side in (-1, 1):
    box("Hinge", (side * 0.0235, 0.112, 0.040), (0.002, 0.012, 0.012), edge)
# One walnut piece from the action to the butt: the wrist narrows behind the
# action, the comb drops towards the butt and the semi-pistol grip hangs under.
profile("Stock", [(0.006, 0.082), (-0.060, 0.074), (-0.385, 0.036), (-0.385, -0.074),
                  (-0.120, -0.016), (-0.055, 0.004), (-0.030, -0.058), (-0.004, -0.060),
                  (0.006, 0.034)], 0.038, wood)
box("ButtPlate", (0, -0.389, -0.019), (0.040, 0.008, 0.112), dark, 0.002)
box("GripCap", (0, -0.017, -0.061), (0.030, 0.026, 0.004), dark, 0.001)
profile("GuardBase", [(0.080, 0.022), (0.086, 0.014), (0.014, -0.004), (0.006, 0.010)], 0.014, frame)
for i, y in enumerate((0.036, 0.054)):
    profile("Trigger%d" % i, [(y, 0.022), (y + 0.006, 0.019), (y, 0.002), (y - 0.008, -0.002), (y - 0.006, 0.006)], 0.006, edge)

# Side-by-side barrels with their rib, the forend and the bead.
for side, name in ((-1, "Left"), (1, "Right")):
    tube(name + "Barrel", 0.115, 0.710, BORE, 0.0105, steel, 10)
    tube(name + "Breech", 0.115, 0.160, BORE, 0.0125, steel, 10)
    tube(name + "Bore", 0.7095, 0.7105, BORE, 0.0085, dark, 10)
    parts[-1].location.x = side * GAUGE
    parts[-2].location.x = side * GAUGE
    parts[-3].location.x = side * GAUGE
box("Rib", (0, 0.410, BORE + 0.011), (0.008, 0.590, 0.004), steel, 0.001)
box("UnderRib", (0, 0.410, BORE - 0.010), (0.010, 0.590, 0.006), steel)
box("Forend", (0, 0.250, 0.044), (0.040, 0.190, 0.030), wood, 0.004)
box("ForendIron", (0, 0.160, 0.040), (0.036, 0.020, 0.030), frame, 0.002)
box("Bead", (0, 0.700, BORE + 0.016), (0.004, 0.004, 0.004), sight)

muzzle = bpy.data.objects.new("Muzzle", None)
bpy.context.collection.objects.link(muzzle)
muzzle.parent = root
muzzle.location = (0, 0.712, BORE)
support = bpy.data.objects.new("Support", None)
bpy.context.collection.objects.link(support)
support.parent = root
support.location = (0, 0.260, 0.030)

source_parts = len(parts)
triangles = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts)
bpy.ops.object.select_all(action="DESELECT")
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
joined = bpy.context.object
joined.name = "ShotgunMesh"
parts = [joined]

bpy.ops.object.select_all(action="DESELECT")
for obj in [root, muzzle, support, *parts]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=str(ASSET / "shotgun_lowpoly.glb"),
    export_format="GLB", use_selection=True, export_yup=True, export_cameras=False,
    export_lights=False, export_animations=False)

manifest = {"name": "LIMIAR double-barrel shotgun", "triangles": triangles,
            "mesh_parts": len(parts), "authored_parts": source_parts, "materials": 6, "units": "meters",
            "godot_forward": "-Z", "godot_up": "+Y", "origin": "grip",
            "muzzle_godot": [0, BORE, -0.712], "support_godot": [0, 0.030, -0.260],
            "source": "tools/build_shotgun.py",
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
camera.data.ortho_scale = 1.25
aim_at(camera, (0, 0.17, 0.0))
scene.camera = camera
for location, power, size in [((0.6, 0.3, 0.6), 3.0, 0.8), ((-0.5, -0.2, 0.3), 1.2, 0.5),
                              ((0.2, -0.6, 0.4), 2.0, 0.4)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    lamp = bpy.context.object
    lamp.data.energy = power
    lamp.data.shape = "DISK"
    lamp.data.size = size
    aim_at(lamp, (0, 0.15, 0))

scene.render.filepath = str(ASSET / "shotgun_preview.png")
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "shotgun.blend"))
bpy.ops.render.render(write_still=True)
print("SHOTGUN triangles=%d parts=%d" % (triangles, source_parts))
