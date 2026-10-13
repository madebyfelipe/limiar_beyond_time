# Dylan — transições, reações e mira (Mixamo, 13/10/2026)

Pedido: deixar Dylan fluido ("run to stop, dying etc."), trocar o dash para trás,
trazer o susto da cutscene do relé e baixar do Mixamo o máximo possível de uma vez.

## Biblioteca completa fora do projeto

Todo o catálogo do Mixamo (2.446 animações e 38 packs) está sendo exportado sobre o
rig `dylan_mixamo`, com FBX Binary 2019, 30 fps, sem skin, sem redução de keyframes e
**com root motion** (sem In Place). Destino: `E:\LIMIAR\.local\mixamo_library\`,
ignorado pelo Git e pelo Godot (`.gdignore`).

| Caminho | Conteúdo |
| --- | --- |
| `incoming/NNNNN__<nome>.fbx` | Arquivos na ordem de chegada |
| `motions/<Nome>__<descrição>__<id8>.fbx` | Hardlinks com nome único, criados pela reconciliação |
| `manifests/mxmanifest_*.json` | Log da exportação: id, nome, descrição, duração, quadros, loop e suporte a In Place |
| `index.json` | Índice pesquisável que liga cada arquivo ao seu registro |

Para usar uma captura no jogo, copie-a para `assets/models/dylan_protagonist/mixamo/`
com um nome curto e declare o clipe em `tools/build_dylan_animations.gd`. Use
`tools/render_clip_candidates.gd` para escolher a captura e a janela.

**Escala de importação.** Os FBX do Mixamo estão em centímetros. Toda captura
copiada para o projeto precisa de `nodes/root_scale=100.0` no `.import`, como as
anteriores. Com o padrão (1), a trilha do quadril fica 100 vezes menor e o corpo
afunda no chão (pose em pé a 0,005 em vez de 0,5). Por segurança,
`build_dylan_animations.gd` e o renderizador corrigem essa trilha em `metric()`.

## Clipes novos

| Clipe | Arquivo | Captura Mixamo | Janela | Uso |
| --- | --- | --- | --- | --- |
| `dodge_back` | `dodge_back_v2.fbx` | Backward Jump (*Jumping While Walking Backwards*) | 0,15–1,35 s | Esquiva para trás e esquiva neutra; substitui o *Dodging Back* |
| `run_stop` | `run_stop.fbx` | Run To Stop (*Fast Stop From Full Run*) | inteira | Ao parar depois de correr (até 0,25 s após o último quadro em `run`) |
| `hit` | `hit_front.fbx` | Standing React Large From Front | 0–0,9 s | Ao levar dano |
| `hit_aim` | `hit_pistol.fbx` | Hit Reaction (*While Holding A Pistol*) | 0,7–1,8 s | Ao levar dano com a arma levantada |
| `death` | `death_back.fbx` | Standing React Death Backward | inteira | Cai para trás uma vez e fica deitado; substitui a inclinação do modelo |
| `idle_look` | `idle_look.fbx` | Unarmed Idle Looking Ver. 1 | inteira | Depois de 8 s parado |
| `aim_idle` | `pistol_idle.fbx` | Pistol Idle (*Idle With Aimed Pistol*) | ciclo | Parado com a arma levantada |
| `aim_walk` | `pistol_walk.fbx` | Pistol Walk | ciclo | Mirando e andando para a frente |
| `aim_walk_back` | `pistol_walk_back.fbx` | Pistol Walk Backward | ciclo | Mirando e recuando |
| `strafe_left` / `strafe_right` | `pistol_strafe_left/right.fbx` | Pistol Strafe | ciclo | Mirando e andando de lado |
| `startled` | `startled.fbx` | Terrified (*Being Terrified While Standing*) | 0,6–2,4 s | Susto na janela do relé. O Mixamo não tem "Startled"; o início do Terrified é o tranco com as mãos no rosto |
| `look_over_shoulder` | `look_over_shoulder.fbx` | Look Over Shoulder | inteira (3,77 s) | Cutscene do relé, desde 13/10/2026: olha por cima do ombro direito para a janela quando o animal para; substitui o `startled`, que fica de reserva. A cabeça vira 130° para trás entre 0,5 e 2,0 s e volta até 2,5 s, então a sala gira Dylan com a janela 130° atrás do ombro direito (`LOOK_BACK_DEGREES`) |
| `terminal_type` | `typing_seated.fbx` | Typing (*Sitting At A Computer And Typing*) | 2–10 s, emendado | Console do relé. Só existe digitação sentada; tronco e braços vão sobre quadril e pernas do idle (opção `stand`) |

Velocidade nativa dos ciclos de pistola, medida pelo pé de apoio sob o quadril e
calibrada pelo walk (1,48 m/s): `aim_walk` 2,06, `aim_walk_back` 1,14,
`strafe_left` 1,72 e `strafe_right` 1,76 m/s. Remedidos em 13/10/2026 (ver
`SHOTGUN.md`): 2,51, 1,42, 2,06 e 2,35. Com a mira, Dylan anda a 1,26 m/s,
então esses ciclos tocam entre 0,6x e 1,1x.

## Comportamento em `dylan_visual.gd`

- Transições e reações são *one-shots*. Elas tocam sobre a locomoção e cedem quando
  terminam ou quando o corpo passa de 0,3 m/s. A reação a tiro fica no ar enquanto
  dura o `hit_stun`.
- Esquiva, porta e cutscene continuam com prioridade. Esquiva interrompe um one-shot,
  e `end_interaction()` limpa o estado.
- Morte: `death` toca uma vez e mantém a última pose. Um reset devolve o idle. Sem o
  clipe, volta o comportamento antigo de inclinar o modelo.
- Mirando, cada direção usa o ciclo de pistola correspondente. Se faltar um, cai
  para o ciclo desarmado.

## Parada da corrida (13/10/2026)

Pedido: a corrida fora de sincronia e "esse leve desaceleramento da corrida".

- **Cadência:** `run` foi remedido para 2,91 m/s e `rifle_run` para 4,0 m/s (antes 2,73 e 3,83). O pé de apoio fica a cerca de 0,04 m/s de zero no meio do apoio. A corrida desarmada continua tocando a 1,31x para acompanhar os 3,8 m/s do Dylan.
- **Desaceleração:** antes o corpo parava em 0,1 s (40 m/s²) e o `run_stop` tocava parado no lugar. Agora, ao soltar a corrida, o `run_stop` começa na hora e o corpo freia pela curva de velocidade do quadril da própria captura (`STOP_PROFILES` em `dylan_visual.gd`, medida por `tools/measure_stop_profiles.gd`, na escala de 1,84x do rig). O excesso acima da curva cai na desaceleração normal. O clipe toca na cadência da corrida (até 1,5x).
- Desarmado, Dylan desliza 0,8 m em cerca de 0,6 s. Com a escopeta, desliza 1,3 m em 0,8 s; o `rifle_run_stop` agora começa aos 0,5 s, onde a captura deixa de correr e passa a frear.
- Nova entrada, mira, esquiva, dano, reset ou perda de controle encerram a freada (`PlayerController.brake_along()`, `braking()`, `end_brake()`).
- `check_dylan_transitions.gd` confere que a parada começa na hora, freia, desliza entre 0,5 e 1,2 m, para, e que voltar a andar encerra a freada.

## Pistola sempre na mão

Fora da mira, a pistola continua visível e presa ao osso da mão direita, abaixada.
O encaixe (`PISTOL_GRIP`) é a posição de mira medida no espaço do osso da mão: varia
3 mm entre direções, então baixar a arma a deixa onde a mão já a segurava. Entre as
duas posições, a arma interpola junto com a influência da mira. `grip_pose.gd`
fecha os dedos da mão direita com a pose do primeiro quadro do "Pistol Idle" e é
carregado por `preload`, sem `class_name`, para funcionar antes de o editor
reescanear o projeto.

## Validação

`tests/check_dylan_transitions.gd` (`transicoes` no executor) cobre corrida até
parar, olhar em volta e cancelamento ao andar, reação a tiro, ciclos de pistola nas
quatro direções, morte mantida sem inclinação e retorno ao idle no reset. Também
passaram `locomocao`, `esquiva`, `combate`, `combate-inimigo`, `rele`,
`dylan-portas`, `controles-tanque`, `contato-pes`, `cenas` e `gamepad`.

| Arquivo | Bytes | SHA-256 |
| --- | --- | --- |
| `look_over_shoulder.fbx` | 1.940.368 | `6dbf30e564f4cb91b2392f607c8bd806b8b290087e27f1ee76a71ce32294e722` |
| `startled.fbx` | 1.788.400 | `2013e0552cd95d3af41d805d5778095e11290f39bfe2168ce6fd44f5871aae46` |
| `dodge_back_v2.fbx` | 443.824 | `3ead5a22856d5a4c7705eef56f0240094a8590a97d71e39ed708d4c936fea5e6` |
| `run_stop.fbx` | 354.368 | `4d4fdfd6bdc774add50634651d16f52d4fedb7fad789e51d914b7feb776c3064` |
| `death_back.fbx` | 675.056 | `3bf7b0dcc5feb404f373c58ac4c32b376fdbbe6dadbc2c4e5cd4aac87669ced6` |
| `hit_front.fbx` | 417.008 | `7f46b39ca2a9b3e43bed871e0437a0cbaa49179b78e853e37ee78b35795c2490` |
| `hit_pistol.fbx` | 524.752 | `9df6a3fd4707a8264ec65b2d2ceff1dc98ae51b7d4031425b14ed5e0e5491f2f` |
| `pistol_idle.fbx` | 367.152 | `39fd1e47480ac3961c39d1d0be5051191a4f4dc49f227d581856cd76b3f2b6c8` |
| `pistol_strafe_left.fbx` | 307.920 | `7a80a758c8eb8ccfec011cbaa9133931fdacc63fe4a731dbb00e925b2ef1e171` |
| `pistol_strafe_right.fbx` | 310.624 | `ea5035f5fd46117fc67452de024a4599e9338c29e7cf8fbfe0981e73a5c0d203` |
| `pistol_walk.fbx` | 326.832 | `feb224315a7366eef71b291d22be5c17821ca7291929a97086c82341fad144a8` |
| `pistol_walk_back.fbx` | 345.728 | `f56664ecac9887b6ce197fe5e8940d11b0ac347d25b871ef1928fde2ab933ffb` |
| `idle_look.fbx` | 1.191.616 | `aa3b83c82a9b772cd92c89ef89362adcc2c53a3df1a7ff5f8cbc55e0da4debca` |
| `typing_seated.fbx` | 1.608.000 | `442c0efd33bba97d9939a59e587241b67e41fbda7a3bcae06180d6ccf61dc31d` |

Valem os termos de uso da Adobe/Mixamo; as capturas não são relicenciadas como código do projeto.
