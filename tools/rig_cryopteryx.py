"""Rig the reduced Cryopteryx and bake its clips. Run with Blender 4.5.

blender --background --factory-startup --python tools/rig_cryopteryx.py [-- --preview]

Starts from assets/models/cryopteryx/model_base.glb (tools/reduce_cryopteryx.py),
which is caught mid-stride: left leg forward, right leg back. A skeleton laid on
that pose skins it, both legs are then turned to one mirrored standing pose and
the result is frozen as the rest shape. The game rig is built on that neutral
mesh, symmetric, with the leg controls and the motion donor the Keleken uses:
all six clips come from Quaternius' CC0 Velociraptor
(assets/models/keleken/source/donor/, see LICENSE.txt there).
Blender axes: +Y forward, +Z up, -X the animal's left.
"""
import bpy
import bmesh
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/cryopteryx"
SOURCE = ASSET / "source"
BASE = ASSET / "model_base.glb"
ORIGINAL_HASH = "2d71f62374fda23bd9dd5eb040fa71febc6396f06f8667adeae5783c04e4f859"
# Metres per unit of the reduced mesh, which is one unit long: a raptor of
# 3,2 m with its hip about a metre up. Provisional, like the animal itself.
SCALE = 3.2
FPS = 30
PREVIEW = "--preview" in sys.argv
SIDES = (("L", -1.0), ("R", 1.0))
LEG = ("thigh", "shin", "tarsus", "toes")


def metres(p):
    return Vector(p) * SCALE


scene = bpy.context.scene
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.import_scene.gltf(filepath=str(BASE))
mesh = next(o for o in scene.objects if o.type == "MESH")
mesh.name = "CryopteryxMesh"
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# One vertex per place: flat faces came back from the file as three vertices
# each, and weights spread over a surface need the surface joined.
weld = bmesh.new()
weld.from_mesh(mesh.data)
bmesh.ops.remove_doubles(weld, verts=weld.verts, dist=1e-6)
weld.to_mesh(mesh.data)
weld.free()
bpy.ops.mesh.customdata_custom_splitnormals_clear()
for polygon in mesh.data.polygons:
    polygon.use_smooth = False
for vertex in mesh.data.vertices:
    vertex.co *= SCALE
mesh.data.update()
texture = bpy.data.images.load(str(SOURCE / "cryopteryx_color.jpg"), check_existing=False)
texture.name = "cryopteryx_color"
texture.pack()
for material in mesh.data.materials:
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = texture

# --- Landmarks ---------------------------------------------------------------
# Read off gridded orthographic views of the reduced mesh and checked against
# slices of its vertices (docs/CRYOPTERYX_ANIMATION.md), in mesh units.
# Trunk, neck, head and tail lie on the midline.
TRUNK = [
    ("root", (0, 0, 0), (0, 0, .04), None),
    ("pelvis", (0, .04, .335), (0, .125, .335), "root"),
    ("spine", (0, .125, .335), (0, .21, .335), "pelvis"),
    ("chest", (0, .21, .335), (0, .285, .34), "spine"),
    ("neck_01", (0, .285, .34), (0, .31, .375), "chest"),
    ("neck_02", (0, .31, .375), (0, .335, .405), "neck_01"),
    ("head", (0, .335, .405), (0, .495, .395), "neck_02"),
    ("tail_01", (0, .04, .335), (0, -.07, .335), "pelvis"),
    ("tail_02", (0, -.07, .335), (0, -.18, .36), "tail_01"),
    ("tail_03", (0, -.18, .36), (0, -.29, .38), "tail_02"),
    ("tail_04", (0, -.29, .38), (0, -.395, .385), "tail_03"),
    ("tail_05", (0, -.395, .385), (0, -.498, .367), "tail_04"),
]
# The arms are held alike on both sides: shoulder, elbow, wrist, claw tips, for
# the right arm (the left mirrors it).
ARM = [("upper_arm", (.07, .275, .305)), ("forearm", (.082, .26, .236)), ("hand", (.09, .39, .218)), (None, (.09, .428, .135))]
# The legs are not: hip, knee, ankle, ball of the foot, toe tips, as posed.
LEG_POSED = {
    "L": [(-.070, .105, .312), (-.073, .168, .210), (-.073, .168, .097), (-.090, .245, .030), (-.098, .340, .008)],
    "R": [(.070, .100, .312), (.070, .086, .188), (.072, -.008, .100), (.088, .015, .030), (.097, .108, .008)],
}


# Standing: thigh forward, shin back, tarsus forward, toes almost flat, in
# degrees from straight down towards the head. The mean direction of the two
# posed legs comes out nearly straight, 95 % of the leg's reach, and a leg
# with nothing left to extend cannot take a stride.
NEUTRAL_ANGLES = (30., -40., 25., 80.)


def neutral_leg():
    """Joints of the left leg standing: each segment keeps the mean length and
    the mean sideways lean of the two posed legs, the right one mirrored over,
    at the standing angle."""
    left = [Vector(p) for p in LEG_POSED["L"]]
    right = [Vector((-p[0], p[1], p[2])) for p in LEG_POSED["R"]]
    joints = [(left[0] + right[0]) / 2.]
    for index, angle in enumerate(NEUTRAL_ANGLES):
        a, b = left[index + 1] - left[index], right[index + 1] - right[index]
        length = (a.length + b.length) / 2.
        across = (a.x + b.x) / 2.
        reach = math.sqrt(max(length * length - across * across, 0.))
        joints.append(joints[-1] + Vector((across, reach * math.sin(math.radians(angle)), -reach * math.cos(math.radians(angle)))))
    return joints


def side_point(p, sign):
    """A left-side point for the given side."""
    return Vector((-p[0] * sign, p[1], p[2]))


def build_specs(posed):
    """Bone name -> (head, tail, parent) in metres, legs posed or neutral."""
    result = {name: (metres(head), metres(tail), parent) for name, head, tail, parent in TRUNK}
    neutral = neutral_leg()
    for side, sign in SIDES:
        for index in range(3):
            name, head = ARM[index]
            tail = ARM[index + 1][1]
            parent = "chest" if index == 0 else f"{ARM[index - 1][0]}.{side}"
            result[f"{name}.{side}"] = (metres((head[0] * sign, head[1], head[2])), metres((tail[0] * sign, tail[1], tail[2])), parent)
        joints = [Vector(p) for p in LEG_POSED[side]] if posed else [side_point(p, sign) for p in neutral]
        for index, part in enumerate(LEG):
            parent = "pelvis" if index == 0 else f"{LEG[index - 1]}.{side}"
            result[f"{part}.{side}"] = (joints[index] * SCALE, joints[index + 1] * SCALE, parent)
    return result


def make_armature(name, bones, free_scale=False):
    data = bpy.data.armatures.new(name + "Data")
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone_name, (head, tail, parent) in bones.items():
        b = data.edit_bones.new(bone_name)
        b.head, b.tail = head, tail
        if parent:
            b.parent = data.edit_bones[parent]
        b.use_deform = bone_name != "root"
        if free_scale:
            b.inherit_scale = "NONE"
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


# --- Skin on the pose the mesh came in --------------------------------------
posed = build_specs(True)
fit = make_armature("CryopteryxFit", posed, True)
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
fit.select_set(True)
bpy.context.view_layer.objects.active = fit
bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def segment_distance(p, head, tail):
    delta = tail - head
    factor = max(0., min(1., (p - head).dot(delta) / delta.length_squared))
    return (p - (head + delta * factor)).length


# Four influences a vertex, summing to one. A vertex the heat solver left bare
# takes the nearest bone outright.
bare = 0
for vertex in mesh.data.vertices:
    weights = sorted(((g.group, g.weight) for g in vertex.groups if g.weight > 1e-4), key=lambda item: -item[1])[:4]
    for index in [g.group for g in vertex.groups]:
        mesh.vertex_groups[index].remove([vertex.index])
    if not weights:
        bare += 1
        nearest = min((name for name in posed if name != "root"), key=lambda name: segment_distance(vertex.co, posed[name][0], posed[name][1]))
        weights = [(mesh.vertex_groups[nearest].index, 1.)]
    total = sum(weight for _, weight in weights)
    for index, weight in weights:
        mesh.vertex_groups[index].add([vertex.index], weight / total, "REPLACE")
print("SKIN", len(mesh.data.vertices), "vertices,", bare, "without heat weights")

# --- Stand it up -------------------------------------------------------------
# Each leg bone swings to the neutral direction and stretches to the neutral
# length, so the two legs end as mirror images whatever the pose gave them.
neutral = build_specs(False)
bpy.context.view_layer.objects.active = fit
bpy.ops.object.mode_set(mode="POSE")
for side, _ in SIDES:
    for part in LEG:
        name = f"{part}.{side}"
        pb = fit.pose.bones[name]
        bpy.context.view_layer.update()
        head, tail, _ = neutral[name]
        rotation = pb.matrix.to_quaternion()
        current = (rotation @ Vector((0, 1, 0))).normalized()
        turned = current.rotation_difference((tail - head).normalized()) @ rotation
        stretch = (tail - head).length / pb.bone.length
        pb.matrix = Matrix.Translation(head) @ turned.to_matrix().to_4x4() @ Matrix.Diagonal((1., stretch, 1., 1.))
        print("STAND", name, "turn", round(math.degrees(current.angle((tail - head).normalized())), 1), "deg, stretch", round(stretch, 3))
bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.modifier_apply(modifier=mesh.modifiers[0].name)
bpy.data.objects.remove(fit, do_unlink=True)
mesh.parent = None
mesh.matrix_world.identity()
# Standing is taller than striding: put the soles back on the floor, bones too.
# The two feet are not the same foot, one inner claw hangs a few centimetres
# lower than the other, so the floor goes half-way between their lowest points.
floor = sum(min(v.co.z for v in mesh.data.vertices if v.co.x * sign > 0.) for _, sign in SIDES) / 2.
for vertex in mesh.data.vertices:
    vertex.co.z -= floor
mesh.data.update()
specs = {name: (head - Vector((0, 0, floor)) if name != "root" else head, tail - Vector((0, 0, floor)) if name != "root" else tail, parent)
         for name, (head, tail, parent) in neutral.items()}
# What the two sides of the frozen mesh still disagree by, measured on the feet.
feet = {side: [v.co for v in mesh.data.vertices if v.co.x * sign > .03 * SCALE and v.co.z < .06 * SCALE] for side, sign in SIDES}
for side in ("L", "R"):
    print("FOOT", side, "toe y", round(max(p.y for p in feet[side]), 3), "heel y", round(min(p.y for p in feet[side]), 3), "lowest", round(min(p.z for p in feet[side]), 4))
print("STAND floor shift", round(-floor, 4), "m; height", round(max(v.co.z for v in mesh.data.vertices), 3), "length", round(max(v.co.y for v in mesh.data.vertices) - min(v.co.y for v in mesh.data.vertices), 3))

# --- The rig that is animated ------------------------------------------------
rig = make_armature("CryopteryxRig", specs)
armature = rig.data
rig.show_in_front = True
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for side, sign in SIDES:
    hock, foot = specs[f"tarsus.{side}"][0], specs[f"tarsus.{side}"][1]
    knee = specs[f"shin.{side}"][0]
    for name, head, tail, parent in [
        (f"CTRL_foot.{side}", foot, foot + (foot - hock), "root"),
        (f"CTRL_hock.{side}", hock, foot, f"CTRL_foot.{side}"),
        (f"CTRL_toes.{side}", foot, specs[f"toes.{side}"][1], f"CTRL_foot.{side}"),
        # The knee bends forward: its pole stands ahead of it.
        (f"CTRL_knee.{side}", knee + Vector((0, 2., 0)), knee + Vector((0, 2., .3)), "root"),
    ]:
        b = armature.edit_bones.new(name)
        b.head, b.tail = head, tail
        b.parent = armature.edit_bones[parent]
        b.use_deform = False
bpy.ops.object.mode_set(mode="POSE")
for side, _ in SIDES:
    constraint = rig.pose.bones[f"shin.{side}"].constraints.new("IK")
    constraint.name = "Two segment leg to hock (foot controller)"
    constraint.target = rig
    constraint.subtarget = f"CTRL_hock.{side}"
    constraint.chain_count = 2
    constraint.use_stretch = False
    constraint.pole_target = rig
    constraint.pole_subtarget = f"CTRL_knee.{side}"
    for name in (f"thigh.{side}", f"shin.{side}"):
        rig.pose.bones[name].ik_stretch = 0
    constraint = rig.pose.bones[f"tarsus.{side}"].constraints.new("DAMPED_TRACK")
    constraint.target = rig
    constraint.subtarget = f"CTRL_foot.{side}"
    constraint.track_axis = "TRACK_Y"
    constraint = rig.pose.bones[f"toes.{side}"].constraints.new("COPY_ROTATION")
    constraint.target = rig
    constraint.subtarget = f"CTRL_toes.{side}"
    constraint.target_space = "WORLD"
    constraint.owner_space = "WORLD"
bpy.ops.object.mode_set(mode="OBJECT")
# Match the IK pole angle to the leg's own bend plane, measured in the rest pose
# rather than assumed from Blender's bone roll: a coarse sweep, then a fine one.
for side, _ in SIDES:
    constraint = rig.pose.bones[f"shin.{side}"].constraints[0]
    desired = specs[f"shin.{side}"][0]
    best = (float("inf"), 0.)
    for centre, span, steps in ((0., math.pi, 64), (None, math.pi / 32., 64)):
        centre = best[1] if centre is None else centre
        for step in range(steps + 1):
            angle = centre - span + step * 2. * span / steps
            constraint.pole_angle = angle
            bpy.context.view_layer.update()
            evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
            error = (evaluated.pose.bones[f"shin.{side}"].head - desired).length
            if error < best[0]:
                best = (error, angle)
    constraint.pole_angle = best[1]
    print("POLE_FIT", side, "rest_error", round(best[0], 6), "angle", round(best[1], 4))

modifier = mesh.modifiers.new("Cryopteryx skin", "ARMATURE")
modifier.object = rig
mesh.parent = rig
mesh["original_sha256"] = ORIGINAL_HASH
rig["foot_controls"] = "CTRL_foot.L/R: move in world; CTRL_knee.L/R: bend plane; hock IK and toes follow. Controls remain in source only."
rig["length_m"] = SCALE
rig["animation_origin"] = "Idle, walk, run, attack, jump and death retargeted from Quaternius' CC0 Velociraptor."

# --- Motion donor ------------------------------------------------------------
# The same raptor that lends the Keleken four clips, and here a closer match:
# arms, a five-bone tail and the same leg. Its feet are IK targets, so their
# paths drive CTRL_foot, scaled from its leg to ours, and stay planted. Trunk,
# neck, head, tail and arms carry over as rotations measured against each rig's
# rest pose, which makes bone rolls and rest angles irrelevant.
DONOR = ROOT / "assets/models/keleken/source/donor/velociraptor_quaternius.glb"
DONOR_FPS = 24
DONOR_ACTIONS = {"idle": "Velociraptor_Idle", "walk": "Velociraptor_Walk", "run": "Velociraptor_Run",
                 "attack": "Velociraptor_Attack", "jump": "Velociraptor_Jump", "death": "Velociraptor_Death"}
LOOPS = ("idle", "walk", "run")
# Donor frames each clip uses. The walk's keys run to 58, but its cycle ends
# at 30 and the rest holds the opening pose.
DONOR_RANGES = {"walk": (0, 30)}
# The donor faces -Y in Blender; ours faces +Y.
TURN = Quaternion((0, 0, 1), math.pi)
DONOR_BONES = ["Hips", "Torso", "Shoulders", "Neck", "Head", "Tail1", "Tail2", "Tail3", "Tail4", "Tail5"]
for donor_side in ("L", "R"):
    DONOR_BONES += [f"FrontUpLeg.{donor_side}", f"FrontLowLeg.{donor_side}", f"FrontFoot.{donor_side}", f"BackFoot.{donor_side}"]
before = set(bpy.data.objects)
before_actions = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=str(DONOR))
donor_objects = [o for o in bpy.data.objects if o not in before]
donor = next(o for o in donor_objects if o.type == "ARMATURE")


def donor_matrix(name, rest=False):
    local = donor.data.bones[name].matrix_local if rest else donor.pose.bones[name].matrix
    m = donor.matrix_world @ local
    return m.to_translation(), m.to_3x3().normalized().to_quaternion()


# Leg length, hip joint to the planted foot, sets the scale for every path.
LEG_LENGTH = specs["thigh.L"][0].z - specs["tarsus.L"][1].z
DONOR_LEG = (donor.matrix_world @ donor.data.bones["BackLeg.L"].head_local).z - donor_matrix("BackFoot.L", True)[0].z
DONOR_SCALE = LEG_LENGTH / DONOR_LEG
print("DONOR leg", round(LEG_LENGTH, 3), "donor leg", round(DONOR_LEG, 3), "scale", round(DONOR_SCALE, 4))
rest_pose = {name: donor_matrix(name, True) for name in DONOR_BONES}


def donor_sample(action, time):
    """World rotation deltas and path offsets of the donor, in our frame."""
    donor.animation_data.action = action
    frame = time * DONOR_FPS
    scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
    bpy.context.view_layer.update()
    turns, offsets = {}, {}
    for name in DONOR_BONES:
        position, rotation = donor_matrix(name)
        rest_position, rest_rotation = rest_pose[name]
        turns[name] = TURN @ (rotation @ rest_rotation.inverted()) @ TURN.inverted()
        offsets[name] = TURN @ ((position - rest_position) * DONOR_SCALE)
    return turns, offsets


def donor_action(clip):
    return next(a for a in bpy.data.actions if a.name.endswith(DONOR_ACTIONS[clip]) and a not in before_actions)


CLIPS = {}
donor_samples = {}
for clip in DONOR_ACTIONS:
    action = donor_action(clip)
    first, last = DONOR_RANGES.get(clip, action.frame_range)
    length = (last - first) / DONOR_FPS
    frames = max(1, round(length * FPS))
    CLIPS[clip] = {"frames": frames, "loop": clip in LOOPS, "donor_length": round(length, 4)}
    donor_samples[clip] = [donor_sample(action, first / DONOR_FPS + length * frame / frames) for frame in range(frames + 1)]


def strike_phase():
    """Where the donor's head reaches furthest forward in its attack."""
    best = (-1e9, 0.)
    for frame, (_, offsets) in enumerate(donor_samples["attack"]):
        if offsets["Head"].y > best[0]:
            best = (offsets["Head"].y, frame / CLIPS["attack"]["frames"])
    return best[1]


def contact_window(clip, side):
    """Phases [start, end] of the longest stretch with the foot planted; start
    can be past end when the stance wraps across the loop."""
    down = [sample[1]["BackFoot." + side].z < .012 for sample in donor_samples[clip][:-1]]
    frames = len(down)
    best = (0, 0)
    for start in range(frames):
        if down[start] and not down[start - 1]:
            length = 0
            while length < frames and down[(start + length) % frames]:
                length += 1
            best = max(best, (length, start), key=lambda item: item[0])
    length, start = best
    return [round(start / frames, 4), round(((start + length - 1) % frames) / frames, 4)]


for clip in ("walk", "run"):
    CLIPS[clip]["contact"] = {side: contact_window(clip, side) for side in ("L", "R")}
    print("DONOR", clip, "contact", CLIPS[clip]["contact"])
# The bite lands when the head is furthest out; an actor times its hit by it.
CLIPS["attack"]["strike"] = round(strike_phase(), 3)
print("DONOR strike at", CLIPS["attack"]["strike"], "of the attack")
# The donor leaves nothing behind in the rig file or the export.
for obj in donor_objects:
    bpy.data.objects.remove(obj, do_unlink=True)
for action in [a for a in bpy.data.actions if a not in before_actions]:
    bpy.data.actions.remove(action)
scene.render.fps = FPS

# Cryopteryx bone <- donor bone. The lower neck sits between the shoulders'
# turn and the neck's.
DIRECT = {"pelvis": "Hips", "spine": "Torso", "chest": "Shoulders", "neck_02": "Neck", "head": "Head",
          "tail_01": "Tail1", "tail_02": "Tail2", "tail_03": "Tail3", "tail_04": "Tail4", "tail_05": "Tail5"}
for side, _ in SIDES:
    DIRECT.update({f"upper_arm.{side}": f"FrontUpLeg.{side}", f"forearm.{side}": f"FrontLowLeg.{side}", f"hand.{side}": f"FrontFoot.{side}"})
# Parents before children.
DRIVEN = ["pelvis", "spine", "chest", "neck_01", "neck_02", "head", "tail_01", "tail_02", "tail_03", "tail_04", "tail_05"]
for side, _ in SIDES:
    DRIVEN += [f"upper_arm.{side}", f"forearm.{side}", f"hand.{side}"]


def donor_turns(turns):
    result = {name: turns[source] for name, source in DIRECT.items()}
    result["neck_01"] = turns["Shoulders"].slerp(turns["Neck"], .5)
    return result


controls = [name for name in rig.pose.bones.keys() if name.startswith("CTRL_foot")]
animated = [*DRIVEN, *controls]


def translate_world(name, vector):
    pb = rig.pose.bones[name]
    pb.location = pb.bone.matrix_local.to_3x3().inverted() @ Vector(vector)


def reset_pose():
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)


# Stride fit per cycle: (centre, scale) applied along the travel to both feet,
# so the stance is centred under our hip and no longer than our leg reaches.
STRIDE_FIT = {}


def planted_frames(clip, side):
    """Frames of each foot's stance, in order, wrapping across the loop."""
    down = [sample[1]["BackFoot." + side].z < .012 for sample in donor_samples[clip][:-1]]
    frames = len(down)
    start = next(i for i in range(frames) if down[i] and not down[i - 1])
    run = []
    while down[(start + len(run)) % frames] and len(run) < frames:
        run.append((start + len(run)) % frames)
    return run


# The donor's planted foot stands still for a few frames at each end of its
# stance while its body is meant to travel on: in place, that foot would skate.
# The stance is laid out again at one constant speed between the same
# touch-down and lift-off points, and both feet take their mean speed.
STANCE_PATH = {}
for clip in ("walk", "run"):
    stances = {}
    for side in ("L", "R"):
        run = planted_frames(clip, side)
        first = donor_samples[clip][run[0]][1]["BackFoot." + side].y
        last = donor_samples[clip][run[-1]][1]["BackFoot." + side].y
        stances[side] = (run, first, last, (last - first) / max(1, len(run) - 1))
    per_frame = sum(stance[3] for stance in stances.values()) / 2.
    for side, (run, first, last, _) in stances.items():
        middle = (first + last) / 2.
        half = per_frame * (len(run) - 1) / 2.
        # Sideways, a planted foot holds its mean place instead of rocking.
        across = sum(donor_samples[clip][frame][1]["BackFoot." + side].x for frame in run) / len(run)
        for index, frame in enumerate(run):
            STANCE_PATH[(clip, side, frame)] = (across, middle - half + per_frame * index)


def pose_donor(clip, frame):
    turns, offsets = donor_samples[clip][frame]
    world = donor_turns(turns)
    translate_world("pelvis", offsets["Hips"])
    for name in DRIVEN:
        parent = specs[name][2]
        local = world.get(parent, Quaternion()).inverted() @ world[name]
        rest = rig.pose.bones[name].bone.matrix_local.to_quaternion()
        rig.pose.bones[name].rotation_quaternion = rest.inverted() @ local @ rest
    centre, scale = STRIDE_FIT.get(clip, (0., 1.))
    for side in ("L", "R"):
        offset = offsets[f"BackFoot.{side}"].copy()
        key = (clip, side, frame % CLIPS[clip]["frames"])
        if key in STANCE_PATH:
            offset.x, offset.y = STANCE_PATH[key]
            offset.z = 0.
        offset.y = (offset.y - centre) * scale
        # A planted foot never dips under the floor it stands on.
        offset.z = max(offset.z, 0.)
        translate_world(f"CTRL_foot.{side}", offset)
        if clip != "death":
            # Falling, the donor's feet roll over and would tip our toes into
            # the floor; the dying feet only move.
            rest = rig.pose.bones[f"CTRL_foot.{side}"].bone.matrix_local.to_quaternion()
            rig.pose.bones[f"CTRL_foot.{side}"].rotation_quaternion = rest.inverted() @ turns[f"BackFoot.{side}"] @ rest


def reach_error(clip):
    """Worst gap between a foot target and the hock-to-foot end the IK reaches."""
    worst = 0.
    for frame in range(CLIPS[clip]["frames"]):
        reset_pose()
        pose_donor(clip, frame)
        bpy.context.view_layer.update()
        evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        for side in ("L", "R"):
            worst = max(worst, (evaluated.pose.bones[f"CTRL_foot.{side}"].head - evaluated.pose.bones[f"tarsus.{side}"].tail).length)
    return worst


def stance_speed(clip):
    """Planted-foot speed of a cycle on our rig, in metres per second: the
    linear stance's travel over its time, both feet."""
    duration = CLIPS[clip]["frames"] / FPS
    speeds = []
    for side in ("L", "R"):
        run = planted_frames(clip, side)
        travel = abs(STANCE_PATH[(clip, side, run[-1])][1] - STANCE_PATH[(clip, side, run[0])][1])
        speeds.append(travel / (duration * (len(run) - 1) / CLIPS[clip]["frames"]))
    return sum(speeds) / len(speeds)


for clip in ("walk", "run"):
    planted = [sample[1]["BackFoot." + side].y for sample in donor_samples[clip] for side in ("L", "R") if sample[1]["BackFoot." + side].z < .012]
    centre = (max(planted) + min(planted)) / 2.
    for step in range(11):
        scale = round(1. - step * .05, 2)
        STRIDE_FIT[clip] = (centre, scale)
        if reach_error(clip) < .01:
            break
    CLIPS[clip]["speed"] = round(stance_speed(clip) * scale, 3)
    CLIPS[clip]["stride_fit"] = [round(centre, 4), scale]
    print("DONOR", clip, "stride centre", round(centre, 3), "scale", scale, "reach error", round(reach_error(clip), 4), "speed", CLIPS[clip]["speed"], "m/s")
for clip in ("idle", "attack", "jump", "death"):
    print("DONOR", clip, "reach error", round(reach_error(clip), 4))
reset_pose()

rig.animation_data_create()
source_actions = {}
for clip, info in CLIPS.items():
    action = bpy.data.actions.new("CTRL_" + clip)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(info["frames"] + 1):
        reset_pose()
        pose_donor(clip, frame)
        if clip == "death":
            # The donor falls on its side through our wider body; raise the
            # pelvis by however far the skin would sink under the floor.
            bpy.context.view_layer.update()
            evaluated = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
            lowest = min((mesh.matrix_world @ v.co).z for v in evaluated.data.vertices)
            if lowest < 0.:
                pelvis = rig.pose.bones["pelvis"]
                pelvis.location = pelvis.location + pelvis.bone.matrix_local.to_3x3().inverted() @ Vector((0, 0, -lowest))
        for name in animated:
            pb = rig.pose.bones[name]
            pb.keyframe_insert("location", frame=frame + 1)
            pb.keyframe_insert("rotation_quaternion", frame=frame + 1)
    for curve in action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = "LINEAR"
    source_actions[clip] = action

rig.animation_data.action = source_actions["idle"]
scene.frame_end = CLIPS["idle"]["frames"] + 1
scene.frame_set(1)
# Authoring file keeps IK controls and original control actions for editing.
for image in bpy.data.images:
    if image.source == "FILE":
        image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "cryopteryx_rig.blend"))

# Bake evaluated matrices into a clean deformation rig; no constraints in GLB.
export_rig = make_armature("Cryopteryx", specs)
export_rig.data.name = "CryopteryxSkeleton"
# The root carries no skin, but the export keeps deform bones only and the
# game wants it at the top of the skeleton.
export_rig.data.bones["root"].use_deform = True
export_rig.animation_data_create()
baked_actions = []
for clip, info in CLIPS.items():
    rig.animation_data.action = source_actions[clip]
    action = bpy.data.actions.new(clip)
    action.use_fake_user = True
    export_rig.animation_data.action = action
    for frame in range(info["frames"] + 1):
        scene.frame_set(frame + 1)
        bpy.context.view_layer.update()
        evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        for name in specs:
            src = evaluated.pose.bones[name]
            pb = export_rig.pose.bones[name]
            pb.rotation_mode = "QUATERNION"
            kwargs = {}
            if pb.parent:
                kwargs["parent_matrix"] = evaluated.pose.bones[pb.parent.name].matrix
                kwargs["parent_matrix_local"] = pb.parent.bone.matrix_local
            pb.matrix_basis = pb.bone.convert_local_to_pose(src.matrix, pb.bone.matrix_local, invert=True, **kwargs)
            pb.keyframe_insert("location", frame=frame + 1)
            pb.keyframe_insert("rotation_quaternion", frame=frame + 1)
            pb.keyframe_insert("scale", frame=frame + 1)
    for curve in action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = "LINEAR"
    baked_actions.append(action)

rig.animation_data.action = None
for action in source_actions.values():
    bpy.data.actions.remove(action)
modifier.object = export_rig
mesh.parent = export_rig

if PREVIEW:
    # Stills for review, in .local: the rest pose and four moments of each clip.
    out = ROOT / ".local/cryopteryx"
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x, scene.render.resolution_y = 1100, 620
    scene.world = bpy.data.worlds.new("Preview")
    scene.world.color = (.06, .07, .08)
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    ground = bpy.data.meshes.new("PreviewFloor")
    ground.from_pydata([(-6, -6, 0), (6, -6, 0), (6, 6, 0), (-6, 6, 0)], [], [(0, 1, 2, 3)])
    ground_object = bpy.data.objects.new("PreviewFloor", ground)
    bpy.context.collection.objects.link(ground_object)
    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 5.2
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
    aim = bpy.data.objects.new("PreviewAim", None)
    bpy.context.collection.objects.link(aim)
    aim.location = (0, 0, .8)
    track = camera.constraints.new("TRACK_TO")
    track.target = aim
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    rig.hide_render = True
    shots = [("rest", None, 0)] + [(clip, action, round(CLIPS[clip]["frames"] * phase)) for clip, action in zip(CLIPS, baked_actions) for phase in (0., .25, .5, .75, 1.)]
    for clip, action, frame in shots:
        export_rig.animation_data.action = action
        if action is None:
            for pb in export_rig.pose.bones:
                pb.matrix_basis.identity()
        scene.frame_set(frame + 1)
        for view, place in (("side", (-9, 0, 1.)), ("front", (5, 8, 2.2))):
            camera.location = place
            scene.render.filepath = str(out / f"rig_{clip}_{frame:02d}_{view}.png")
            bpy.ops.render.render(write_still=True)
    for obj in (ground_object, camera, aim):
        bpy.data.objects.remove(obj, do_unlink=True)

export_rig.animation_data.action = baked_actions[0]
scene.frame_set(1)
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
export_rig.select_set(True)
bpy.context.view_layer.objects.active = export_rig
bpy.ops.export_scene.gltf(filepath=str(ASSET / "cryopteryx_animated.glb"), export_format="GLB",
    use_selection=True, export_animations=True, export_animation_mode="ACTIONS",
    export_def_bones=True, export_force_sampling=True, export_frame_step=1,
    export_anim_slide_to_zero=True, export_image_format="JPEG", export_jpeg_quality=92,
    export_optimize_animation_size=False, export_skins=True, export_extras=True)

bounds = [v.co for v in mesh.data.vertices]
metadata = {
    "length_m": round(max(p.y for p in bounds) - min(p.y for p in bounds), 3),
    "height_m": round(max(p.z for p in bounds), 3),
    "hip_height_m": round(specs["thigh.L"][0].z, 3),
    "forward_godot": "-Z", "fps": FPS, "bones": list(specs),
    "triangles": sum(len(p.vertices) - 2 for p in mesh.data.polygons),
    "origin": "Idle, walk, run, attack, jump and death retargeted in tools/rig_cryopteryx.py from Quaternius' Velociraptor (CC0 1.0, assets/models/keleken/source/donor/LICENSE.txt). Baked IK.",
    "original_sha256": ORIGINAL_HASH,
    "base_sha256": hashlib.sha256(BASE.read_bytes()).hexdigest(),
    "clips": CLIPS,
}
(ASSET / "animation_manifest.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
print("CRYOPTERYX_BUILD", len(specs), "bones", len(CLIPS), "clips", len(bounds), "vertices", metadata["triangles"], "triangles")
