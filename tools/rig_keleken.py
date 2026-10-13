"""Build the editable avian rig and bake its clips. Run with Blender 4.5.

blender --background --factory-startup --python tools/rig_keleken.py
Source axes: +X forward, +Y up, +/-Z sides. Blender: +Y forward, +Z up.
The original GLB is read-only. Walk, run, attack and death are retargeted from
Quaternius' CC0 Velociraptor (source/donor/, see LICENSE.txt); idle, look,
alert, recover and hit stay authored here.
"""
import bpy
import hashlib
import json
import math
import struct
from pathlib import Path
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/models/keleken"
SOURCE = ASSET / "source"
SOURCE.mkdir(exist_ok=True)
EXPECTED_HASH = "1748ed72afc6b5e1f85c2df601afa2a0d5c1790418f0bd3c0655b65b53ee8376"
assert hashlib.sha256((ASSET / "model_base.glb").read_bytes()).hexdigest() == EXPECTED_HASH
GROUND = 0.619631901
SCALE = 2.0
FPS = 30

def point(p):
    x, y, z = p
    return Vector((z * SCALE, x * SCALE, (y + GROUND) * SCALE))

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.import_scene.gltf(filepath=str(ASSET / "model_base.glb"))
mesh = next(o for o in bpy.context.scene.objects if o.type == "MESH")
mesh.name = "KelekenMesh"
# Store world coordinates in the source convention before normalizing the mesh.
original = []
for vertex in mesh.data.vertices:
    p = mesh.matrix_world @ vertex.co
    original.append(Vector((p.x, p.z, -p.y)))
    vertex.co = point(original[-1])
mesh.matrix_world.identity()
mesh.data.update()
# Resolve the embedded JPEG explicitly. The GLB importer can create an empty
# image datablock for this Tripo file; use the original bytes, not a new texture.
glb = (ASSET / "model_base.glb").read_bytes()
json_length = struct.unpack_from("<I", glb, 12)[0]
gltf = json.loads(glb[20:20 + json_length])
image_view = gltf["bufferViews"][gltf["images"][0]["bufferView"]]
image_start = 20 + json_length + 8 + image_view.get("byteOffset", 0)
texture_path = SOURCE / "keleken_color.jpg"
texture_path.write_bytes(glb[image_start:image_start + image_view["byteLength"]])
texture = bpy.data.images.load(str(texture_path), check_existing=False)
texture.pack()
for material in mesh.data.materials:
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = texture

# Specs are source-space head/tail, nearest deformation parent, region.
specs = {}
def bone(name, head, tail, parent=None, region="body"):
    specs[name] = (Vector(head), Vector(tail), parent, region)

bone("root", (0, -GROUND, 0), (0, -GROUND + .12, 0), region="root")
bone("pelvis", (-.18, -.075, 0), (-.12, .025, 0), "root")
bone("spine", (-.12, .025, 0), (0, .065, 0), "pelvis")
bone("chest", (0, .065, 0), (.105, .095, 0), "spine")
bone("neck_01", (.105, .095, 0), (.195, .175, 0), "chest", "neck")
bone("neck_02", (.195, .175, 0), (.245, .285, 0), "neck_01", "neck")
bone("neck_03", (.245, .285, 0), (.295, .375, 0), "neck_02", "neck")
bone("neck_04", (.295, .375, 0), (.375, .410, 0), "neck_03", "neck")
bone("head", (.375, .410, 0), (.510, .410, 0), "neck_04", "head")
bone("jaw", (.405, .360, 0), (.555, .315, 0), "head", "jaw")
bone("tail_01", (-.235, .02, 0), (-.425, -.055, 0), "pelvis", "tail")
bone("tail_02", (-.425, -.055, 0), (-.590, -.165, 0), "tail_01", "tail")
for side, sign in [("L", -1), ("R", 1)]:
    z = sign * .14
    bone(f"thigh.{side}", (-.18, -.075, z), (-.277, -.290, z), "pelvis", side)
    bone(f"shin.{side}", (-.277, -.290, z), (-.202, -.435, z), f"thigh.{side}", side)
    bone(f"tarsus.{side}", (-.202, -.435, z), (-.120, -.550, z), f"shin.{side}", side)
    bone(f"toes.{side}", (-.120, -.550, z), (-.005, -.550, z), f"tarsus.{side}", side)
    bone(f"wing_01.{side}", (-.055, .04, sign * .185), (-.18, -.015, sign * .225), "chest", "wing" + side)
    bone(f"wing_02.{side}", (-.18, -.015, sign * .225), (-.305, -.12, sign * .22), f"wing_01.{side}", "wing" + side)

armature = bpy.data.armatures.new("KelekenAuthorRig")
rig = bpy.data.objects.new("KelekenRig", armature)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
mesh.select_set(False)
rig.show_in_front = True
bpy.ops.object.mode_set(mode="EDIT")
for name, (head, tail, parent, region) in specs.items():
    b = armature.edit_bones.new(name)
    b.head, b.tail = point(head), point(tail)
    if parent:
        b.parent = armature.edit_bones[parent]
    b.use_deform = True

for side in ("L", "R"):
    foot = specs[f"tarsus.{side}"][1]
    hock = specs[f"tarsus.{side}"][0]
    direction = foot - hock
    for name, head, tail, parent in [
        (f"CTRL_foot.{side}", foot, foot + direction, "root"),
        (f"CTRL_hock.{side}", hock, foot, f"CTRL_foot.{side}"),
        (f"CTRL_toes.{side}", foot, specs[f"toes.{side}"][1], f"CTRL_foot.{side}"),
        (f"CTRL_knee.{side}", (-.75, -.25, foot.z), (-.75, -.15, foot.z), "root"),
    ]:
        b = armature.edit_bones.new(name)
        b.head, b.tail = point(head), point(tail)
        b.parent = armature.edit_bones[parent]
        b.use_deform = False
bpy.ops.object.mode_set(mode="POSE")
for side in ("L", "R"):
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
# Match the IK pole angle to the imported leg's bend plane. The fit is evaluated
# in the exact rest pose rather than assuming Blender's bone roll convention.
for side in ("L", "R"):
    constraint = rig.pose.bones[f"shin.{side}"].constraints[0]
    desired = point(specs[f"shin.{side}"][0])
    best = (float("inf"), 0.)
    for step in range(64):
        angle = -math.pi + step * 2. * math.pi / 64.
        constraint.pole_angle = angle
        bpy.context.view_layer.update()
        evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        error = (evaluated.pose.bones[f"shin.{side}"].head - desired).length
        if error < best[0]:
            best = (error, angle)
    constraint.pole_angle = best[1]
    print("POLE_FIT", side, "rest_error", round(best[0], 6), "angle", round(best[1], 4))

# Spatial masks prevent weights jumping between overlapping wings/body or legs.
# Welded UV/normal seam vertices receive exactly the same weights.
def segment_distance(p, head, tail):
    delta = tail - head
    factor = max(0., min(1., (p - head).dot(delta) / delta.length_squared))
    return (p - (head + delta * factor)).length

groups = {name: mesh.vertex_groups.new(name=name) for name in specs if name != "root"}
cache = {}
for vertex, p in zip(mesh.data.vertices, original):
    key = tuple(round(c, 6) for c in p)
    if key not in cache:
        x, y, z = p
        side = "L" if z < 0 else "R"
        if x > .43 and y < .35:
            weights = [("jaw", 1.)]
        elif x > .355 and y > .29:
            weights = [("head", 1.)]
        else:
            if y < -.50 and x > -.35:
                candidates = [f"tarsus.{side}", f"toes.{side}"]
            elif y < -.24 and x > -.40:
                candidates = [f"{part}.{side}" for part in ("thigh", "shin", "tarsus")]
            elif y < -.055 and -.39 < x < .035:
                candidates = ["pelvis", "spine", f"thigh.{side}", f"shin.{side}"]
            elif x > .16:
                candidates = ["chest", "neck_01", "neck_02", "neck_03", "neck_04", "head"]
            elif x < -.34:
                candidates = ["pelvis", "spine", "tail_01", "tail_02"]
            elif abs(z) > .18 and -.35 < x < .04:
                candidates = ["chest", "spine", "pelvis", f"wing_01.{side}", f"wing_02.{side}"]
            else:
                candidates = ["pelvis", "spine", "chest", "neck_01", "tail_01"]
            scores = [(name, 1. / (segment_distance(p, *specs[name][:2]) ** 2 + .0012) ** 2.5) for name in candidates]
            scores.sort(key=lambda item: item[1], reverse=True)
            scores = scores[:4]
            total = sum(score for _, score in scores)
            weights = [(name, score / total) for name, score in scores]
        cache[key] = weights
    for name, weight in cache[key]:
        groups[name].add([vertex.index], weight, "REPLACE")

modifier = mesh.modifiers.new("Keleken skin", "ARMATURE")
modifier.object = rig
mesh.parent = rig
mesh["source_sha256"] = EXPECTED_HASH
rig["foot_controls"] = "CTRL_foot.L/R: move in world; CTRL_knee.L/R: bend plane; hock IK and toes follow. Controls remain in source only."
rig["height_m"] = 2.4
rig["animation_origin"] = "Authored idle/look/alert/recover/hit; walk/run/attack/death retargeted from Quaternius' CC0 Velociraptor."

# --- Motion donor ------------------------------------------------------------
# A raptor is a running theropod like the Keleken: same leg chain (thigh,
# shin, tarsus, toes), a long tail and a striking head. Its feet are IK
# targets too, so their paths drive CTRL_foot, scaled from its leg to ours,
# and stay planted. The trunk, neck, head, tail and arms carry over as
# rotations measured against each rig's rest pose, which makes bone rolls and
# rest angles irrelevant. Its one neck bone is spread over our four.
DONOR = SOURCE / "donor" / "velociraptor_quaternius.glb"
DONOR_FPS = 24
DONOR_ACTIONS = {"walk": "Velociraptor_Walk", "run": "Velociraptor_Run",
                 "attack_beak": "Velociraptor_Attack", "death": "Velociraptor_Death"}
# Donor frames each clip uses. The walk's keys run to 58, but its cycle ends
# at 30 and the rest holds the opening pose.
DONOR_RANGES = {"walk": (0, 30)}
# The donor faces -Y in Blender; ours faces +Y.
TURN = Quaternion((0, 0, 1), math.pi)
DONOR_BONES = ["Hips", "Torso", "Shoulders", "Neck", "Head", "Tail2", "Tail4",
               "FrontUpLeg.L", "FrontUpLeg.R", "BackFoot.L", "BackFoot.R"]
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
LEG = point(specs["thigh.L"][0]).z - point(specs["tarsus.L"][1]).z
DONOR_LEG = (donor.matrix_world @ donor.data.bones["BackLeg.L"].head_local).z - donor_matrix("BackFoot.L", True)[0].z
DONOR_SCALE = LEG / DONOR_LEG
print("DONOR leg", round(LEG, 3), "donor leg", round(DONOR_LEG, 3), "scale", round(DONOR_SCALE, 4))
rest_pose = {name: donor_matrix(name, True) for name in DONOR_BONES}


def donor_sample(action, time):
    """World rotation deltas and path offsets of the donor, in our frame."""
    donor.animation_data.action = action
    frame = time * DONOR_FPS
    bpy.context.scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
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


donor_samples = {}


def sample_donor_clip(clip, frames, warp=lambda phase: phase):
    action = donor_action(clip)
    first, last = DONOR_RANGES.get(clip, action.frame_range)
    length = (last - first) / DONOR_FPS
    donor_samples[clip] = [donor_sample(action, warp(frame / frames) * length) for frame in range(frames + 1)]
    return length


def strike_phase():
    """Where the donor's head reaches furthest forward in its attack."""
    action = donor_action("attack_beak")
    first, last = int(action.frame_range[0]), int(action.frame_range[1])
    best = (-1e9, 0.)
    for frame in range(first, last + 1):
        donor.animation_data.action = action
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        reach = (TURN @ donor_matrix("Head")[0]).y
        if reach > best[0]:
            best = (reach, (frame - first) / (last - first))
    return best[1]


def stance_speed(clip):
    """Planted-foot speed of a donor cycle on our rig, in metres per second at
    the study scale: the linear stance's travel over its time, both feet."""
    duration = CLIPS[clip]["frames"] / FPS
    speeds = []
    for side in ("L", "R"):
        run = planted_frames(clip, side)
        travel = abs(STANCE_PATH[(clip, side, run[-1])][1] - STANCE_PATH[(clip, side, run[0])][1])
        speeds.append(travel / (duration * (len(run) - 1) / CLIPS[clip]["frames"]))
    print("DONOR", clip, "stance speed by foot", [round(v, 3) for v in speeds], "frames", [len(planted_frames(clip, side)) for side in ("L", "R")])
    return sum(speeds) / len(speeds)


scene = bpy.context.scene
scene.render.fps = FPS
controls = [name for name in rig.pose.bones.keys() if name.startswith("CTRL_foot")]
animated = ["pelvis", "spine", "chest", "neck_01", "neck_02", "neck_03", "neck_04", "head", "jaw", "tail_01", "tail_02", "wing_01.L", "wing_01.R", "CTRL_toes.L", "CTRL_toes.R", *controls]

def translate_world(name, vector):
    pb = rig.pose.bones[name]
    pb.location = pb.bone.matrix_local.to_3x3().inverted() @ Vector(vector)

def rotate_world_axis(name, axis, angle):
    pb = rig.pose.bones[name]
    rest = pb.bone.matrix_local.to_quaternion()
    pb.rotation_quaternion = pb.rotation_quaternion @ (rest.inverted() @ Quaternion(Vector(axis), angle) @ rest)

def smooth(t):
    return t * t * (3. - 2. * t)

def gesture(time, keys):
    """Short eased turns separated by held looks, rather than a sine sweep."""
    for (start, a), (end, b) in zip(keys, keys[1:]):
        if time <= end:
            return a + (b - a) * smooth(max(0., (time - start) / (end - start)))
    return keys[-1][1]

def head_bob(phase):
    # Hold/retreat under the moving body, followed by a quicker forward reset.
    if phase < .65:
        return .5 - phase / .65
    return -.5 + smooth((phase - .65) / .35)

CLIPS = {
    "idle": {"frames": 192, "loop": True},
    # Retargeted cycles: 1,25 s and 0,54 s at the donor's 24 fps, kept within
    # a frame at ours. Their speed is the planted foot's, measured below.
    "walk": {"frames": 38, "loop": True, "donor": True},
    "run": {"frames": 16, "loop": True, "donor": True},
    "look": {"frames": 72, "loop": True},
    "alert": {"frames": 36, "loop": False},
    # The donor's strike is retimed so the head is furthest out at 0,5 s,
    # inside the hit window KelekenActor checks from 0,42 s.
    "attack_beak": {"frames": 30, "loop": False, "hit_start": .42, "hit_end": .58, "donor": True},
    "recover": {"frames": 30, "loop": False},
    # Reaction to a round: a sharp recoil that settles back on the rest pose.
    "hit": {"frames": 15, "loop": False},
    # The donor's fall onto its side. Ends lying, not on the rest pose: it is
    # held by the actor once it plays.
    "death": {"frames": 39, "loop": False, "donor": True},
}
STRIKE = strike_phase()


def attack_warp(phase):
    # Piecewise linear: the wind-up fills the first half, the return the rest.
    return STRIKE * phase / .5 if phase < .5 else STRIKE + (1. - STRIKE) * (phase - .5) / .5


for clip in DONOR_ACTIONS:
    CLIPS[clip]["donor_length"] = round(sample_donor_clip(clip, CLIPS[clip]["frames"], attack_warp if clip == "attack_beak" else (lambda phase: phase)), 4)
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
print("DONOR strike at", round(STRIKE, 3), "of the donor attack")
# The donor leaves nothing behind in the rig file or the export.
for obj in donor_objects:
    bpy.data.objects.remove(obj, do_unlink=True)
for action in [a for a in bpy.data.actions if a not in before_actions]:
    bpy.data.actions.remove(action)
scene.render.fps = FPS


# Keleken bone <- donor rotation. Neck bones blend from the shoulders' turn to
# the neck's; the arms are half-way between the chest and the donor's arms.
def donor_turns(turns):
    shoulders, neck = turns["Shoulders"], turns["Neck"]
    result = {"pelvis": turns["Hips"], "spine": turns["Torso"], "chest": shoulders,
              "head": turns["Head"], "tail_01": turns["Tail2"], "tail_02": turns["Tail4"]}
    for index, name in enumerate(("neck_01", "neck_02", "neck_03", "neck_04")):
        result[name] = shoulders.slerp(neck, (index + 1) / 4.)
    for side in ("L", "R"):
        result[f"wing_01.{side}"] = shoulders.slerp(turns[f"FrontUpLeg.{side}"], .5)
    return result


# Stride fit per cycle: (centre, scale) applied along the travel to both feet.
# The donor stands with its feet behind the hip and we stand with ours ahead
# of it, and its stride is long for our leg: laid on as it is, the back of the
# stance asks for a foot the leg cannot reach and the foot lifts. The fit
# centres the stance on ours and takes the longest stride the IK still
# reaches everywhere, measured below.
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
# stance while its body is meant to travel on: in place, that foot would skate
# forward with the body. The stance is laid out again at one constant speed
# between the same touch-down and lift-off points.
# The donor's feet also travel 7-9 % apart in speed, which no single playback
# rate can match: both are set to their mean, each about its own midpoint.
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

DRIVEN = ["pelvis", "spine", "chest", "neck_01", "neck_02", "neck_03", "neck_04", "head",
          "tail_01", "tail_02", "wing_01.L", "wing_01.R"]


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
    phase = frame / CLIPS[clip]["frames"]
    if clip == "walk":
        # A raptor holds its head still; a bird pumps it and glances about.
        # The authored head bob and looks ride over the donor's neck.
        bob = head_bob((phase * 2) % 1.)
        rotate_world_axis("neck_01", (1, 0, 0), -.09 * bob)
        rotate_world_axis("neck_02", (1, 0, 0), .03 * bob)
        rotate_world_axis("head", (1, 0, 0), .09 * bob - .03 * bob)
        head_yaw = gesture(phase, [(0, 0), (.10, 0), (.17, .13), (.32, .13), (.42, 0), (.60, 0), (.68, -.10), (.86, -.10), (.96, 0), (1, 0)])
        rotate_world_axis("neck_04", (0, 0, 1), head_yaw * .3)
        rotate_world_axis("head", (0, 0, 1), head_yaw * .7)
    # The donor has no jaw: the beak rests a little open and gapes for the strike.
    gape = math.sin(math.pi * min(1., max(0., (phase - .3) / .35))) if clip == "attack_beak" else 0.
    rotate_world_axis("jaw", (1, 0, 0), .12 + .3 * gape)

def recoil(k, phase):
    """Shared by hit and the first beat of death: thrown back and up."""
    translate_world("pelvis", (.03 * k, -.07 * k, .03 * k))
    rotate_world_axis("chest", (1, 0, 0), .18 * k)
    rotate_world_axis("neck_01", (1, 0, 0), .32 * k)
    rotate_world_axis("neck_02", (1, 0, 0), .12 * k)
    rotate_world_axis("head", (1, 0, 0), -.25 * k)
    # A shake of the head that dies out with the reaction.
    rotate_world_axis("head", (0, 0, 1), .15 * math.sin(3 * math.pi * phase) * (1 - phase))
    rotate_world_axis("jaw", (1, 0, 0), .12 + .3 * k)
    for side, sign in [("L", 1), ("R", -1)]:
        rotate_world_axis(f"wing_01.{side}", (0, 1, 0), sign * .3 * k)
    rotate_world_axis("tail_01", (1, 0, 0), .15 * k)

def pose_clip(clip, phase, info):
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)
    wave = math.sin(2. * math.pi * phase)
    if info.get("donor"):
        pose_donor(clip, round(phase * info["frames"]))
    elif clip in ("walk", "run"):
        run = clip == "run"
        duration = info["frames"] / FPS
        stance = info["stance"]
        stride = info["speed"] * duration * stance
        # Pelvis stays below the straight-leg limit throughout the stance.
        step_wave = math.sin(4 * math.pi * phase)
        pelvis_pitch = -.11 if run else -.025 + .009 * step_wave
        chest_pitch = -.07 if run else -.018 - .012 * step_wave
        translate_world("pelvis", (.012 * wave, .025 if run else 0, (-.12 if run else -.040) + (.018 if run else .017) * math.cos(4 * math.pi * phase)))
        rotate_world_axis("pelvis", (1, 0, 0), pelvis_pitch)
        rotate_world_axis("pelvis", (0, 1, 0), .015 * wave)
        rotate_world_axis("chest", (1, 0, 0), chest_pitch)
        rotate_world_axis("chest", (0, 1, 0), -.012 * wave)
        for side, offset in [("L", 0), ("R", .5)]:
            t = (phase + offset) % 1.
            if t < stance:
                forward = stride * (.5 - t / stance)
                lift = 0.
                pitch = 0.
                toe_curl = 0.
            else:
                swing = (t - stance) / (1. - stance)
                # Hermite tangents match the backward support velocity at both
                # ends, eliminating the abrupt stop/reversal at foot lift-off.
                tangent = -info["speed"] * duration * (1. - stance)
                forward = stride * (-.5 + smooth(swing)) + tangent * (2 * swing ** 3 - 3 * swing ** 2 + swing)
                lift = info["lift"] * math.sin(math.pi * swing) ** 1.4
                pitch = -.14 * math.sin(2 * math.pi * swing)
                toe_curl = -.25 * math.sin(math.pi * swing) ** 2
            translate_world(f"CTRL_foot.{side}", (0, forward, lift))
            rotate_world_axis(f"CTRL_foot.{side}", (1, 0, 0), pitch)
            rotate_world_axis(f"CTRL_toes.{side}", (1, 0, 0), toe_curl)
        bob = head_bob((phase * 2) % 1.)
        neck_pitch = .07 + .025 * step_wave if run else .045 - .19 * bob
        neck_pitch_02 = -.015 * step_wave if run else .065 * bob
        rotate_world_axis("neck_01", (1, 0, 0), neck_pitch)
        rotate_world_axis("neck_02", (1, 0, 0), neck_pitch_02)
        # Counter the torso/neck rotations so the beak stays directed ahead
        # while the neck advances/retracts and the body rises over each step.
        rotate_world_axis("head", (1, 0, 0), -pelvis_pitch - chest_pitch - neck_pitch - neck_pitch_02 + .012 * step_wave)
        head_yaw = .025 * wave if run else gesture(phase, [(0, 0), (.10, 0), (.17, .13), (.32, .13), (.42, 0), (.60, 0), (.68, -.10), (.86, -.10), (.96, 0), (1, 0)])
        rotate_world_axis("neck_04", (0, 0, 1), head_yaw * .3)
        rotate_world_axis("head", (0, 0, 1), head_yaw * .7)
        rotate_world_axis("head", (0, 1, 0), .025 * wave)
        rotate_world_axis("jaw", (1, 0, 0), .12)
        for side, sign in [("L", 1), ("R", -1)]:
            rotate_world_axis(f"wing_01.{side}", (0, 1, 0), sign * (.035 + .025 * wave))
        rotate_world_axis("tail_01", (0, 0, 1), .025 * wave)
    elif clip in ("idle", "look"):
        rotate_world_axis("chest", (1, 0, 0), .007 * wave)
        time = phase * info["frames"] / FPS
        if clip == "idle":
            head_yaw = gesture(time, [(0, 0), (.25, 0), (.38, .22), (.85, .22), (.97, 0), (1.7, 0), (1.83, -.28), (2.55, -.28), (2.67, -.1), (3.25, -.1), (3.38, 0), (4.05, 0), (4.18, .12), (4.75, .12), (4.9, 0), (6.4, 0)])
            tilt = gesture(time, [(0, 0), (.45, 0), (.60, -.10), (.85, -.10), (1.0, 0), (2.0, 0), (2.15, .09), (2.55, .09), (2.7, 0), (6.4, 0)])
        else:
            head_yaw = gesture(time, [(0, 0), (.15, 0), (.32, .35), (.95, .35), (1.1, 0), (1.45, 0), (1.62, -.30), (2.1, -.30), (2.27, 0), (2.4, 0)])
            tilt = head_yaw * -.32
        rotate_world_axis("neck_02", (1, 0, 0), -.01 * wave)
        rotate_world_axis("neck_04", (0, 0, 1), head_yaw * .3)
        rotate_world_axis("head", (0, 0, 1), head_yaw * .7)
        rotate_world_axis("head", (0, 1, 0), tilt)
        rotate_world_axis("head", (1, 0, 0), .025 * wave)
        rotate_world_axis("jaw", (1, 0, 0), .12 + .012 * wave)
        rotate_world_axis("tail_01", (0, 0, 1), .012 * wave)
    elif clip == "alert":
        amount = math.sin(math.pi * phase) ** 2
        rotate_world_axis("neck_01", (1, 0, 0), .12 * amount)
        rotate_world_axis("head", (1, 0, 0), -.12 * amount)
        for side, sign in [("L", 1), ("R", -1)]:
            rotate_world_axis(f"wing_01.{side}", (0, 1, 0), sign * .18 * amount)
    elif clip in ("attack_beak", "recover"):
        if clip == "attack_beak":
            # Pull back, thrust, then return. Shared start/end pose avoids jumps.
            amount = (-.35 * math.sin(math.pi * phase / .35) if phase < .35 else
                      math.sin(math.pi * (phase - .35) / .65) ** 2)
        else:
            amount = .14 * math.sin(math.pi * phase) ** 2
        rotate_world_axis("chest", (1, 0, 0), -.13 * amount)
        rotate_world_axis("neck_01", (1, 0, 0), -.25 * amount)
        rotate_world_axis("neck_02", (1, 0, 0), -.12 * amount)
        rotate_world_axis("head", (1, 0, 0), .18 * amount)
        rotate_world_axis("jaw", (1, 0, 0), .18 * max(amount, 0))
    elif clip == "hit":
        # Two thirds of the death's stagger: a flinch, not a knock-back.
        k = .65 * (smooth(phase / .2) if phase < .2 else 1. - smooth((phase - .2) / .8))
        recoil(k, phase)
    elif clip == "death":
        # Stagger: the hit's recoil, held a moment before the body goes.
        k = (smooth(phase / .12) if phase < .12 else 1.) * (1. - smooth(min(1., max(0., (phase - .2) / .3))))
        recoil(k, min(phase / .3, 1.))
        # Collapse: the pelvis sinks to sitting height over the planted feet,
        # pitches forward and rolls a little onto its right side.
        c = smooth(min(1., max(0., (phase - .2) / .5)))
        translate_world("pelvis", (.06 * c, .05 * c, -.54 * c))
        rotate_world_axis("pelvis", (1, 0, 0), -.15 * c)
        rotate_world_axis("pelvis", (0, 1, 0), .35 * c)
        rotate_world_axis("chest", (0, 1, 0), .15 * c)
        # The neck falls last and the head comes to rest on its side.
        n = smooth(min(1., max(0., (phase - .45) / .55)))
        for name, angle in [("neck_01", -.55), ("neck_02", -.35), ("neck_03", -.25), ("neck_04", -.2)]:
            rotate_world_axis(name, (1, 0, 0), angle * n)
        rotate_world_axis("head", (1, 0, 0), .4 * n)
        rotate_world_axis("head", (0, 1, 0), .9 * n)
        rotate_world_axis("jaw", (1, 0, 0), .35 * n)
        for side, sign in [("L", 1), ("R", -1)]:
            # Toes stay flat: curling them on planted feet drives them underground.
            rotate_world_axis(f"wing_01.{side}", (0, 1, 0), sign * .25 * c)
        rotate_world_axis("tail_01", (1, 0, 0), -.2 * c)

def reset_pose():
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)


def reach_error(clip):
    """Worst gap between a foot target and the hock-to-foot end the IK reaches."""
    worst = 0.
    for frame in range(CLIPS[clip]["frames"]):
        reset_pose()
        pose_donor(clip, frame)
        bpy.context.view_layer.update()
        evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        for side in ("L", "R"):
            target = evaluated.pose.bones[f"CTRL_foot.{side}"].head
            reached = evaluated.pose.bones[f"tarsus.{side}"].tail
            worst = max(worst, (target - reached).length)
    return worst


for clip in ("walk", "run"):
    planted = [sample[1]["BackFoot." + side].y for sample in donor_samples[clip] for side in ("L", "R") if sample[1]["BackFoot." + side].z < .012]
    centre = (max(planted) + min(planted)) / 2.
    for step in range(11):
        scale = round(1. - step * .05, 2)
        STRIDE_FIT[clip] = (centre, scale)
        if reach_error(clip) < .01:
            break
    print("DONOR", clip, "stride centre", round(centre, 3), "scale", scale, "reach error", round(reach_error(clip), 4))
    # The planted speed follows the stride.
    CLIPS[clip]["speed"] = round(stance_speed(clip) * scale, 3)
    CLIPS[clip]["stride_fit"] = [round(centre, 4), scale]
    print("DONOR", clip, "fitted speed", CLIPS[clip]["speed"], "m/s")
reset_pose()

rig.animation_data_create()
source_actions = {}
for clip, info in CLIPS.items():
    action = bpy.data.actions.new("CTRL_" + clip)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(info["frames"] + 1):
        phase = frame / info["frames"]
        pose_clip(clip, phase, info)
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
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "keleken_rig.blend"))

# Bake evaluated matrices into a clean deformation rig; no constraints in GLB.
export_data = bpy.data.armatures.new("KelekenSkeleton")
export_rig = bpy.data.objects.new("Keleken", export_data)
bpy.context.collection.objects.link(export_rig)
bpy.context.view_layer.objects.active = export_rig
bpy.ops.object.mode_set(mode="EDIT")
for name, (head, tail, parent, region) in specs.items():
    b = export_data.edit_bones.new(name)
    b.head, b.tail = point(head), point(tail)
    if parent:
        b.parent = export_data.edit_bones[parent]
bpy.ops.object.mode_set(mode="OBJECT")
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
export_rig.animation_data.action = baked_actions[0]
scene.frame_set(1)
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
export_rig.select_set(True)
bpy.context.view_layer.objects.active = export_rig
bpy.ops.export_scene.gltf(filepath=str(ASSET / "keleken_animated.glb"), export_format="GLB",
    use_selection=True, export_animations=True, export_animation_mode="ACTIONS",
    export_def_bones=True, export_force_sampling=True, export_frame_step=1,
    export_anim_slide_to_zero=True,
    export_optimize_animation_size=False, export_skins=True, export_extras=True)

metadata = {"height_m": 2.4, "forward_godot": "-Z", "fps": FPS, "bones": list(specs),
    "origin": "Idle, look, alert, recover and hit authored in tools/rig_keleken.py; walk, run, attack_beak and death retargeted from Quaternius' Velociraptor (CC0 1.0, source/donor/LICENSE.txt). Baked IK.",
    "source_sha256": EXPECTED_HASH, "clips": CLIPS}
(ASSET / "animation_manifest.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
assert hashlib.sha256((ASSET / "model_base.glb").read_bytes()).hexdigest() == EXPECTED_HASH
print("KELEKEN_BUILD", len(specs), "bones", len(CLIPS), "clips", len(original), "vertices")
