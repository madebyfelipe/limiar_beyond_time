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

Dodge follows the movement input, or backsteps when neutral. Its direction is
committed in world space, so a camera cut does not redirect it. It cancels aim and reload;
release and press aim again to raise the gun. Collision remains on the character
body, with a short invulnerability window and recovery cooldown. Medical kits
restore up to 50 vitality and consume stock only when healing is possible.

Ground-cursor, assisted and mouse target-lock aiming use the custom 48px cursor.
Lowering the weapon, pausing, death, scene removal and door interaction restore
the normal pointer. Free mouse aiming retains its hidden-pointer behavior.
The smaller world reticle shows the actual shot endpoint; red indicates a target.

## Animation provenance

`dodge_right.fbx` is the Mixamo **Dodging Right** capture, obtained from the public
[three.ws source mirror](https://github.com/nirholas/three.ws/blob/main/animation-sources/Dodging%20Right.fbx).
The repository records Mixamo provenance in its
[animation licensing notes](https://github.com/nirholas/three.ws/blob/main/public/animations/LICENSES.md).
It was not downloaded through the user's authenticated browser session.
SHA-256: `08f94a5b98102958c6631b72dc0ce73651f590edb50f271e7cd62867ebf3059a`.

The build tool retargets rest-relative rotations to Dylan, scales hip height,
removes horizontal root travel, and creates a mirrored `dodge_left` variant.
Forward/back escapes orient these sidesteps into the requested direction; they
are adapted captures, not four separately recorded directional animations.
Physics owns travel; animation samples the current dodge time, including pause.
Adobe/Mixamo asset terms apply; the source is not relicensed as project code.

## Validation

The regression suite covers enemy perception/occlusion, pursuit, attack damage,
death, dodge invulnerability/collision, kit stock, save/door persistence, gamepad
target cycling and stick rearming. `check_dodge_presentation.gd` checks full-body
one-shot playback, four escape directions, return to locomotion and cursor reset
on pause. Its graphical run saves images under `.local/dodge-*.png`.
