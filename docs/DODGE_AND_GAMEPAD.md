# Dodge and gamepad controls

The reference is the original **Parasite Eve II** PlayStation manual, printed
pages 6–9: [manual scan](https://dlf.emu-land.net/manuals/psx/Parasite%20Eve%202%20(U).pdf).
It describes directional movement/turning, running and cancelling targeting.
It does not assign a free camera or a dedicated dodge roll. The dedicated timed
dodge here is a modern addition; it is not presented as an original PE II move.

The authored cameras remain fixed. Tank controls keep forward/back movement and
turning; camera-relative controls preserve held movement through camera cuts.
Gamepad aiming defaults to nearest visible target selection, independent of the
mouse aim mode. Right-stick horizontal flicks and shoulder buttons cycle targets.
A held stick cycles once and must return to neutral before another selection.
`Settings > Gameplay > Gamepad Aim` also offers manual right-stick aiming.
In tank mode, the existing auto-target and manual turn/tilt controls remain.

| Action | Keyboard/mouse | Xbox | PlayStation |
| --- | --- | --- | --- |
| Aim | Right mouse | LT | L2 |
| Fire | Left mouse | RT | R2 |
| Reload | R | X | Square |
| Dodge | Q | Y | Triangle |
| Med kit | H | Right-stick press | R3 |
| Cycle targets | Wheel / assigned target key | LB / RB | L1 / R1 |

**Since 2026-10-13 (issue #7) the dodge is always a backstep**: straight away
from where Dylan is facing, whatever the stick or the keys are doing, in camera
and tank controls alike, aiming or not. Its direction is committed in world
space, so a camera cut does not redirect it. Before that it followed the
movement input and only backstepped when neutral. It cancels aim and reload;
release and press aim again to raise the gun. Collision remains on the character
body, with a short invulnerability window and recovery cooldown. Medical kits
restore up to 50 vitality and consume stock only when healing is possible.

All aim modes now hide the pointer and show a red weapon laser with a surface
impact dot, inspired by Ground Zero. Absolute mouse modes still read the hidden
pointer position. Lowering the weapon, pausing, death, scene removal and door
interaction restore the previous pointer mode. Reloading hides the laser.
The beam stops at geometry and its thickness follows the retro pixel setting.
Research and validation: [GROUND_ZERO_CONTROLS.md](GROUND_ZERO_CONTROLS.md).

## Animation provenance

All dodge captures were exported from Mixamo on 2026-10-12 with the user's account,
directly onto the uploaded `dylan_mixamo` rig (FBX Binary, 30 fps, without skin,
no keyframe reduction). No retargeting is needed; the earlier `dodge_right.fbx`
from a public GitHub mirror (SHA-256 `08f94a5b…3059a`) was replaced.

| Clip | File | Mixamo capture | Window kept |
| --- | --- | --- | --- |
| `dodge_forward` | `roll_stand.fbx` | Stand To Roll (*Dive Roll From Standing*) | 0.45–1.95 s: crouch, roll, rise |
| `dodge_back` | `dodge_back.fbx` | Dodging Back (*Jumping Backwards Dodge*) | 0.35–1.75 s: the hop |
| `dodge_right` | `dodge_right.fbx` | Dodging Right (*Dodging To The Right In Place*) | 0.10–1.10 s |
| `dodge_left` | same, mirrored by the build tool | — | 0.10–1.10 s |

The escape always plays `dodge_back`, the hop, with the model turned so the
capture's own travel lines up with the committed world-space direction. The
roll and the two sidesteps (`dodge_forward`, `dodge_left`, `dodge_right`) stay
in the clip library, unused: they are kept in case a directional escape comes
back, and removing them means rebuilding the library from the FBX sources. The build tool removes horizontal hip
travel; physics owns travel and the animation samples the current dodge time,
so each window is compressed into the escape. Since 2026-10-12 the escape lasts
0.55 s instead of 0.32 s, at 4.07 m/s instead of 7, keeping the same 2.24 m:
the captures now play at 2–2.7x instead of 3–4.7x. Invulnerability is 0.41 s
and the cooldown 1.05 s, preserving the previous proportions.

**Back dodge replaced on 2026-10-13.** `dodge_back` now comes from
`dodge_back_v2.fbx`, Mixamo "Backward Jump" (*Jumping While Walking Backwards*),
window 0.15–1.35 s: the gather, the hop and the landing. `dodge_back.fbx` stays as
the fallback when the newer file is absent. See `DYLAN_TRANSITIONS.md`.

Also evaluated and rejected: the four **Standing Dodge** captures of the Pro
Longbow pack (the only matching four-direction set, but recorded side-on in an
archer stance that reads as running beside a forward-aiming pistol) and
**Quick Roll To Run** (ends in a run). Their exports stay outside the project.
`tools/render_dodge_candidates.gd` renders the frame sheets used for the choice.

| File | Bytes | SHA-256 |
| --- | --- | --- |
| `roll_stand.fbx` | 504,848 | `cbda85be5e51424d4f33a14143ad86d2f72fd8a2e272837f88c44e331a7d7b5d` |
| `dodge_back.fbx` | 535,632 | `56b610fc7c29a7efae32f225b26bb2a7616641e25270210270afc1a59132d44f` |
| `dodge_right.fbx` | 379,680 | `00b05012a21ce68d53a0fdd4cb67a48c971d1aa168c0d31dff707d6b2a6342ab` |

Adobe/Mixamo asset terms apply; the captures are not relicensed as project code.

## Validation

The regression suite covers enemy perception/occlusion, pursuit, attack damage,
death, dodge invulnerability/collision, kit stock, save/door persistence, gamepad
target cycling and stick rearming. `check_dodge_presentation.gd` checks full-body
one-shot playback, the backward escape, return to locomotion and cursor reset
on pause. Its graphical run saves images under `.local/dodge-*.png`.

Issue #7, 2026-10-13: `check_dodge_presentation.gd` now drives twenty escapes
(four directions held and none, two facings, camera and tank controls) and one
while aiming, and requires each to be the backward hop travelling within 12° of
straight back for more than a metre. `check_enemy_combat.gd` holds the stick
west while facing west and requires Dylan to go east into the trail bank. Both
were run against the old stick-following code and failed (28 and 1 failures).
Twelve related probes passed afterwards, headless: `esquiva`, `combate-inimigo`,
`combate`, `gamepad`, `unidades`, `transicoes`, `locomocao`, `controles-tanque`,
`dylan-portas`, `shotgun`, `operacao-cenarios`, `rele`.
