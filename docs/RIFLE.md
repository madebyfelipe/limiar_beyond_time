# Rifle — segunda arma (13/10/2026)

Pedido: "adicione um rifle como opção". O rifle é um segundo `WeaponDefinition`
(`resources/combat/rifle.tres`) sobre o mesmo `PlayerWeapon`, como o próprio recurso
já previa.

| | Pistola | Rifle |
| --- | --- | --- |
| Dano | 25 | 40 |
| Intervalo entre tiros | 0,32 s | 0,20 s (semiautomático: um tiro por toque) |
| Pente | 15 | 30 |
| Recarga | 1,6 s | 2,4 s |
| Alcance | 30 m | 60 m |

## Como obter e trocar

- **Estande de tiro** (Extras → Firing Range): as duas armas, sempre.
- **Campanha:** no terminal, `buy rifle` custa 2.200 créditos (a pistola custa 1.800,
  e o jogo começa com 2.400). A compra é salva com `save`, no campo `rifle` de
  `SupplyStock`. `inventory` e `shop` mostram o rifle.
- **Trocar:** ação `switch_weapon`, tecla **X** ou botão **Misc1** do controle
  (Share/Capture). Dá para remapear no menu de controles. A troca só vale para armas
  compradas e cancela mira, tiro e recarga em andamento.
- Cada arma tem seu próprio pente: `PlayerWeapon.magazine` é o da arma em mãos, e
  `spare_magazines` guarda o das outras. A reserva de munição (`SupplyStock.ammo`) é
  compartilhada.
- A arma em mãos e os pentes atravessam portas. Se Dylan só tiver o rifle, ele entra
  com o rifle. O estande reinicia com pentes cheios.

## Visual

- Modelo original low-poly, gerado por `tools/build_rifle.py` no Blender portátil
  (1.012 triângulos, uma malha, seis materiais). Origem na empunhadura, `Muzzle` na
  boca do cano e `Support` no guarda-mão. Prévia em `assets/models/weapons/rifle/rifle_preview.png`.
- Com o rifle, `dylan_visual.gd` troca cada clipe pela variante `rifle_` quando ela
  existe. O rifle é posicionado na mão direita, com o cano passando pela mão esquerda,
  então segue a pose de qualquer captura: baixo no idle e no ombro na mira.
- A postura de braço esticado da pistola (`AimPose`) e o fechamento de dedos
  (`grip_pose.gd`) só valem para a pistola; as capturas de rifle já trazem braços e dedos.

| Clipe | Captura Mixamo | Velocidade nativa |
| --- | --- | --- |
| `rifle_idle` | Rifle Idle (*Two Hand Rifle Idle*) | — |
| `rifle_walk` | Rifle Walk (*Walking With Rifle Down*) | 0,92 m/s |
| `rifle_run` | Rifle Run (*Running With Rifle Down*) | 2,60 m/s |
| `rifle_walk_back` | Backwards Rifle Walk | 0,72 m/s |
| `rifle_run_stop` | Rifle Run To Stop | — |
| `rifle_aim_idle` | Rifle Aiming Idle | — |
| `rifle_aim_walk` | Walk Forward (*Rifle Walk Forward*) | 1,46 m/s |
| `rifle_aim_walk_back` | Walk Backward (*Rifle Walk Backward*) | 1,47 m/s |
| `rifle_strafe_left` / `rifle_strafe_right` | Walk Left / Walk Right (*Rifle Walk Left/Right*) | 1,43 / 1,40 m/s |

| Arquivo | Bytes | SHA-256 (início) |
| --- | --- | --- |
| `rifle_aim_idle.fbx` | 596.832 | `adec6b239d28fba5…` |
| `rifle_aim_walk.fbx` | 343.536 | `e5a2006253a5ab3f…` |
| `rifle_aim_walk_back.fbx` | 343.024 | `59c8506e123d4142…` |
| `rifle_idle.fbx` | 717.792 | `04b1c9bbe45d7182…` |
| `rifle_run.fbx` | 316.128 | `087f5f49a56f6cd1…` |
| `rifle_run_stop.fbx` | 428.352 | `85a3341a788bc5f0…` |
| `rifle_strafe_left.fbx` | 343.168 | `19fc88afc4a0c177…` |
| `rifle_strafe_right.fbx` | 343.168 | `752dc7ee636af9c2…` |
| `rifle_walk.fbx` | 365.920 | `f438ea595e32a983…` |
| `rifle_walk_back.fbx` | 357.792 | `ba36610c0c725737…` |

## Validação

`tests/check_rifle.gd` (`rifle` no executor) cobre a definição, a compra e o save,
a troca pela ação, pentes separados, recarga cancelada na troca, o visual (rifle na
mão, clipes `rifle_`, saída do tiro pela boca do rifle, sem postura de pistola), a
travessia de cena com a arma e os pentes, e a posse só do rifle. A suíte headless
inteira (32 conjuntos) passou.

**Limites conhecidos:** sem clipes próprios de recarga, reação ou morte com o rifle
(usam os genéricos). Na mira o corpo não inclina para cima ou para baixo; o tiro
continua indo para onde a mira aponta, e o laser sai da boca do rifle.
