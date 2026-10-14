"""Reduce the Cryopteryx as Tripo delivered it to a game mesh. Run with Blender 4.5.

blender --background --factory-startup --python tools/reduce_cryopteryx.py [-- original.glb]

The original is 39 MB and close to a million triangles of flat facets, with an
auto-rig that is not kept (see docs/CRYOPTERYX_ANIMATION.md). It stays out of
Git, in .local/cryopteryx/; this writes assets/models/cryopteryx/model_base.glb,
the same pose and texture on a few thousand triangles and no skeleton, which is
what tools/rig_cryopteryx.py starts from.
"""
import bpy
import bmesh
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/cryopteryx"
SOURCE = ASSET / "source"
SOURCE.mkdir(parents=True, exist_ok=True)
(SOURCE / ".gdignore").write_text("\n", encoding="utf-8")
ORIGINAL = Path(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else ROOT / ".local/cryopteryx/model-rigged.glb"
EXPECTED_HASH = "2d71f62374fda23bd9dd5eb040fa71febc6396f06f8667adeae5783c04e4f859"
TARGET_TRIANGLES = 6000
TEXTURE_SIDE = 1024

data = ORIGINAL.read_bytes()
assert hashlib.sha256(data).hexdigest() == EXPECTED_HASH, "Not the file this reduction was tuned on"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
# Welded positions: the exporter had split every vertex on a UV border, and a
# split border opens into a crack as soon as either side is simplified.
bpy.ops.import_scene.gltf(filepath=str(ORIGINAL), merge_vertices=True)
mesh = max((o for o in bpy.context.scene.objects if o.type == "MESH"), key=lambda o: len(o.data.vertices))
for other in [o for o in bpy.context.scene.objects if o is not mesh]:
    bpy.data.objects.remove(other, do_unlink=True)
mesh.name = "CryopteryxMesh"
mesh.data.name = "CryopteryxMesh"
mesh.parent = None
for modifier in list(mesh.modifiers):
    mesh.modifiers.remove(modifier)
mesh.vertex_groups.clear()
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# Feet on the floor: the import leaves the origin at mid height.
floor = min(v.co.z for v in mesh.data.vertices)
for vertex in mesh.data.vertices:
    vertex.co.z -= floor


def triangles():
    return sum(len(p.vertices) - 2 for p in mesh.data.polygons)


before = triangles()
low, high = (tuple(min(v.co[i] for v in mesh.data.vertices) for i in range(3)),
             tuple(max(v.co[i] for v in mesh.data.vertices) for i in range(3)))

# The surface is flat facets drawn with thousands of triangles each. Collapse
# weighs every edge by the error it adds, so the facets empty out first and the
# creases between them are what is left.
modifier = mesh.modifiers.new("Reduce", "DECIMATE")
modifier.decimate_type = "COLLAPSE"
modifier.ratio = TARGET_TRIANGLES / before
modifier.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier="Reduce")

# Slivers and specks a collapse leaves behind, then flat faces as in the source.
bm = bmesh.new()
bm.from_mesh(mesh.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
loose = [v for v in bm.verts if not v.link_faces]
bmesh.ops.delete(bm, geom=loose, context="VERTS")
bmesh.ops.triangulate(bm, faces=bm.faces)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
islands = 0
seen = set()
for vert in bm.verts:
    if vert.index in seen:
        continue
    islands += 1
    stack = [vert]
    while stack:
        current = stack.pop()
        if current.index in seen:
            continue
        seen.add(current.index)
        stack.extend(e.other_vert(current) for e in current.link_edges)
open_edges = sum(1 for e in bm.edges if len(e.link_faces) != 2)
bm.to_mesh(mesh.data)
bm.free()
for polygon in mesh.data.polygons:
    polygon.use_smooth = False
mesh.data.update()

# The embedded texture, by its own bytes, at a size the PSX frame can show.
json_length = struct.unpack_from("<I", data, 12)[0]
gltf = json.loads(data[20:20 + json_length])
view = gltf["bufferViews"][gltf["images"][0]["bufferView"]]
start = 20 + json_length + 8 + view.get("byteOffset", 0)
original_texture = ROOT / ".local/cryopteryx/color_original.jpg"
original_texture.write_bytes(data[start:start + view["byteLength"]])
image = bpy.data.images.load(str(original_texture), check_existing=False)
original_side = tuple(image.size)
image.scale(TEXTURE_SIDE, TEXTURE_SIDE)
texture_path = SOURCE / "cryopteryx_color.jpg"
image.filepath_raw = str(texture_path)
image.file_format = "JPEG"
bpy.context.scene.render.image_settings.quality = 92
image.save()
texture = bpy.data.images.load(str(texture_path), check_existing=False)
texture.name = "cryopteryx_color"
for material in mesh.data.materials:
    material.name = "CryopteryxSkin"
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = texture

bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
bpy.ops.export_scene.gltf(filepath=str(ASSET / "model_base.glb"), export_format="GLB", use_selection=True,
    export_animations=False, export_skins=False, export_image_format="JPEG", export_jpeg_quality=92)
size = (ASSET / "model_base.glb").stat().st_size
print("CRYOPTERYX_REDUCE", before, "->", triangles(), "triangles,", len(mesh.data.vertices), "vertices,",
      islands, "islands,", open_edges, "open edges, texture", original_side, "->", TEXTURE_SIDE,
      ", bounds", [round(v, 3) for v in low], [round(v, 3) for v in high], ",", size, "bytes")
