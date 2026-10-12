"""Author the original low-poly pistol visual and export its GLB, Blender source
and preview. Blender +Y forward/+Z up exports as Godot -Z forward/+Y up.
This is an exterior game prop, with no functional internal mechanism.
Run with the project's portable Blender --background --python tools/build_pistol.py.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/weapons/pistol"
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
grip = material("GripPolymer", (0.024, 0.03, 0.032), 0.0, 0.95)
edge = material("EdgeSteel", (0.22, 0.24, 0.25), 0.55, 0.65)
dark = material("Recess", (0.008, 0.011, 0.014), 0.0, 1.0)
sight = material("SightMark", (0.57, 0.60, 0.50), 0.0, 0.8)

root = bpy.data.objects.new("Pistol", None)
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

box("Slide", (0, 0.055, 0.061), (0.036, 0.232, 0.034), steel, 0.003)
box("LowerFrame", (0, 0.051, 0.032), (0.033, 0.223, 0.024), frame, 0.002)
profile("Grip", [(-0.057, -0.076), (-0.022, -0.076), (0.013, 0.023),
                 (-0.027, 0.029)], 0.032, frame)
for side in (-1, 1):
    panel = profile("GripPanel" + str(side), [(-0.052, -0.068), (-0.026, -0.068),
                    (0.003, 0.010), (-0.023, 0.015)], 0.002, grip)
    panel.location.x = side * 0.0165
    for i in range(6):
        z = -0.056 + i * 0.010
        box("GripRidge", (side * 0.018, -0.020 + 0.32 * z, z),
            (0.001, 0.023, 0.0018), frame)
box("MagazineBase", (0, -0.040, -0.080), (0.037, 0.039, 0.008), frame, 0.001)

# Open trigger guard: individual silhouette segments leave the opening empty.
profile("GuardFront", [(0.083, 0.023), (0.090, 0.016), (0.077, -0.029),
                       (0.069, -0.023)], 0.013, frame)
profile("GuardBase", [(0.069, -0.023), (0.077, -0.029), (0.003, -0.031),
                      (-0.001, -0.023)], 0.013, frame)
profile("GuardRear", [(-0.001, -0.023), (0.003, -0.031), (0.017, 0.025),
                      (0.010, 0.027)], 0.013, frame)
profile("Trigger", [(0.042, 0.020), (0.049, 0.017), (0.041, -0.006),
                    (0.029, -0.016), (0.032, -0.007)], 0.006, edge)

for side in (-1, 1):
    for i in range(5):
        box("SlideSerration", (side * 0.0184, -0.048 + i * 0.007, 0.060),
            (0.0012, 0.002, 0.020), dark)
    box("SlideControl", (side * 0.0175, 0.004, 0.032),
        (0.004, 0.019, 0.006), edge, 0.001)
    box("GripPin", (side * 0.0185, -0.040, -0.049), (0.001, 0.005, 0.005), edge)

box("EjectionRecess", (0.0181, 0.062, 0.062), (0.001, 0.024, 0.012), dark)
box("RearSight", (0, -0.052, 0.083), (0.029, 0.014, 0.011), frame, 0.001)
box("RearSightNotch", (0, -0.060, 0.086), (0.007, 0.001, 0.004), dark)
box("FrontSight", (0, 0.154, 0.081), (0.008, 0.012, 0.008), frame, 0.001)
box("FrontSightMark", (0, 0.1478, 0.082), (0.003, 0.0005, 0.003), sight)

# Only the visible face of the muzzle, without a barrel or internal geometry.
vertices = []
for radius in (0.011, 0.006):
    vertices += [(math.cos(i * math.tau / 12) * radius, 0.172,
                  0.060 + math.sin(i * math.tau / 12) * radius) for i in range(12)]
mesh = bpy.data.meshes.new("MuzzleFace")
mesh.from_pydata(vertices, [], [(i, (i + 1) % 12, (i + 1) % 12 + 12, i + 12) for i in range(12)])
mesh.update()
obj = bpy.data.objects.new("MuzzleFace", mesh)
bpy.context.collection.objects.link(obj)
finish(obj, "MuzzleFace", edge)
box("MuzzleRecess", (0, 0.1715, 0.060), (0.013, 0.0004, 0.013), dark)

muzzle = bpy.data.objects.new("Muzzle", None)
bpy.context.collection.objects.link(muzzle)
muzzle.parent = root
muzzle.location = (0, 0.173, 0.060)

# One mesh with six material surfaces, rather than dozens of draw submissions.
source_parts = len(parts)
triangles = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts)
bpy.ops.object.select_all(action="DESELECT")
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
joined = bpy.context.object
joined.name = "PistolMesh"
parts = [joined]

bpy.ops.object.select_all(action="DESELECT")
for obj in [root, muzzle, *parts]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=str(ASSET / "pistol_lowpoly.glb"),
    export_format="GLB", use_selection=True, export_yup=True, export_cameras=False,
    export_lights=False, export_animations=False)

manifest = {"name": "LIMIAR service pistol", "triangles": triangles,
            "mesh_parts": len(parts), "authored_parts": source_parts, "materials": 6, "units": "meters",
            "godot_forward": "-Z", "godot_up": "+Y", "origin": "grip",
            "muzzle_godot": [0, 0.060, -0.173], "source": "tools/build_pistol.py",
            "status": "original prototype visual; no internal mechanism"}
(ASSET / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

# Preview uses exactly the meshes exported, plus an independent studio setup.
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.render.resolution_x = 1200
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.world.color = (0.08, 0.08, 0.08)
scene.view_settings.view_transform = "Standard"
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False

def aim_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()

bpy.ops.object.camera_add(location=(0.39, 0.41, 0.24))
camera = bpy.context.object
camera.name = "PreviewCamera"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 0.36
aim_at(camera, (0, 0.045, 0.0))
scene.camera = camera
for location, power, size in [((0.3, 0.25, 0.5), 1.5, 0.45),
                              ((-0.3, -0.1, 0.2), 0.7, 0.30),
                              ((0.1, -0.35, 0.35), 1.2, 0.25)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    lamp = bpy.context.object
    lamp.data.energy = power
    lamp.data.shape = "DISK"
    lamp.data.size = size
    aim_at(lamp, (0, 0.04, 0))

scene.render.filepath = str(ASSET / "pistol_preview.png")
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "pistol.blend"))
bpy.ops.render.render(write_still=True)
print("PISTOL triangles=%d parts=%d" % (triangles, len(parts)))
