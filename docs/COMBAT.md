# Combate — pistola, mira e alvos

Data: 11/10/2026. Pedido do usuário:

> implemente armas no jogo. [...] o controle tank segue conforme resident evil e
> dinocrisis com autotarget e tudo mais. No modo moderno, ele segue a direção do
> mouse ao redor do player. [...] use assets do mixamo se precisar para o player
> andar em todas as direções e mirar em todas as direções

Decisão do usuário sobre a mira moderna: *"vira opção no menu de jogabilidade pro
player escolher"*. As três alternativas — raio da câmera para o chão, mira livre
em 360° com retículo, híbrido com assistência — são **opções selecionáveis**, não
uma escolha de arquitetura.

Primeira fatia do item **P1 — Combate** do `PLAN.md`: uma arma, mira para câmera
fixa, munição, recarga, dano e saúde. Esquiva e dano ao jogador ficam para depois.

## Onde está

| Arquivo | Papel |
| --- | --- |
| `systems/combat/player_weapon.gd` | `PlayerWeapon`: erguer, mirar, disparar, recarregar. **Único dono da mira.** |
| `systems/combat/aim_settings.gd` | `AimSettings`: modo de mira moderna e mira automática do tanque, persistidos. |
| `systems/combat/aim_solver.gd` | Geometria: mouse da janela → `SubViewport` → raio → chão; rumo ↔ tela. |
| `systems/combat/health.gd`, `hurtbox.gd` | Pontos de vida e onde um tiro pode acertar. Genéricos, para animais e inimigos. |
| `systems/combat/weapon_definition.gd`, `resources/combat/pistol.tres` | Números da arma. Segunda arma = segundo recurso. |
| `systems/combat/weapon_readout.gd` | "PISTOLA 12 \| 90" no canto inferior direito do quadro 16:9. |
| `actors/player/aim_pose.gd` | Pose de pistola com as duas mãos, procedural (ver Limites). |
| `actors/targets/practice_target.gd` | Silhueta de madeira com Health + Hurtbox; cai ao zerar. |
| `environments/firing_range.tscn` | Estande de tiro jogável. `executar-estande.cmd`. |
| `tests/check_combat.gd` | Probe `combate`. |

`PlayerController` e `DylanVisual` **só leem** `aiming`, `heading` e `turn_input` da
arma. A arma processa antes do corpo (`process_physics_priority = -1`), então o
controlador lê a mira do quadro corrente.

## Controles

| Ação | Teclado/mouse |
| --- | --- |
| Erguer a arma (segurar) | Botão direito ou Ctrl |
| Disparar | Botão esquerdo ou Espaço |
| Recarregar | R |
| Próximo alvo (tanque) | Tab |

Sem arma não há mira: a pistola é a que o terminal da guarita vende (`SupplyStock.weapon`,
do trabalho de UI do Codex). O estande empresta a arma (`practice`) e não gasta o
estoque real. A reserva de munição **é** `SupplyStock.ammo`; o carregador é estático
em `PlayerWeapon.magazine` e atravessa portas.

## Esquema tanque — Resident Evil / Dino Crisis

- Erguer a arma **planta os pés**: as teclas de frente/trás deixam de andar.
- Com **mira automática** ligada, Dylan vira para o **alvo vivo mais próximo que ele
  enxerga** — a linha de visada sai do peito e só conta geometria do mundo.
  Um alvo mais próximo atrás de uma parede é ignorado.
- **Tab** percorre os alvos visíveis do mais próximo ao mais distante e dá a volta.
- **←/→** giram à mão na velocidade do tanque e **soltam a trava**; **↑/↓** inclinam a
  arma ±30°, também soltando a trava.
- Quando o alvo travado cai, a arma passa sozinha para o próximo visível.
- Desligada a mira automática, a arma aponta para onde Dylan está virado.

## Esquema câmera — três modos de mira (menu JOGABILIDADE)

Em todos, Dylan **anda em qualquer direção** a 70% da caminhada, nunca corre, e o
corpo encara a mira — é isso que permite andar de lado.

| Modo | Como o mouse vira rumo | Ao andar | No corte de câmera |
| --- | --- | --- | --- |
| **Cursor no chão** | Cursor visível. Raio da câmera pelo cursor: se cai num alvo, mira **nele** (altura incluída); senão, no ponto do chão. | A arma fica presa àquele **ponto do mundo**; o rumo gira conforme Dylan passa por ele. | Segue o cursor na nova câmera. |
| **Livre 360** (padrão) | Cursor escondido e devolvido ao lugar a cada quadro. O rumo vive **no mundo**; o movimento do mouse o empurra ao longo de um círculo de 220 px em volta do Dylan na tela. | O rumo fica **fixo em relação ao Dylan**. | **Não muda.** |
| **Assistida** | O do cursor; se um alvo visível estiver a menos de 20° do rumo, a mira é puxada para ele. | Como cursor. | Como cursor. |

O **livre 360** guarda o rumo em espaço de mundo de propósito: num jogo de câmeras
fixas, um rumo guardado na tela mudaria a cada corte. `AimSolver.screen_heading`
projeta o rumo atual na tela e o movimento do mouse é somado ali; a volta para o
chão devolve exatamente o mesmo rumo quando o mouse está parado.

## Tiro

- Hitscan 3D do **peito** — dois terços da altura de colisão: 1,2 m no Dylan de 1,8 m
  dos níveis (e do estande), 1,6 m no rig de 2,4 m dos estudos —, não da mão: encostado numa parede, a mão atravessa a
  parede, o peito não — e o tiro não passa.
- Máscara: mundo (camada 1, "mundo") + hurtboxes (camada 3, "alvos"). A arte não
  participa.
- Com alvo travado, o tiro vai **ao centro do alvo** só depois que o corpo virou até
  0,2 rad dele; antes disso sai na direção do corpo, como a arma desenhada.
- Cadência: um disparo por toque, 0,32 s entre disparos. Gatilho em vazio recarrega
  se houver reserva. Recarga leva 1,6 s e tira do estoque exatamente o que coube.
- Retículo: anel onde o tiro acertaria **agora** — vermelho sobre alvo, âmbar sobre
  qualquer outra coisa. Uma parede no caminho aparece antes do disparo.
- Traçador de 0,06 s a partir do cano e clarão de luz.

## Pose e animação

Não há capturas de mira no projeto. Até elas existirem, `AimPose`
(`SkeletonModifier3D`) monta a pose sobre qualquer clipe das pernas: braço direito
reto ao longo do tiro, braço esquerdo levado à empunhadura. A pistola é uma caixa
escura posicionada na mão no sinal `skeleton_updated`, alinhada ao tiro.

Pernas durante a mira: parado → `idle`; para trás → `walk_back`; de frente ou de
lado → `walk`. O seletor já procura `aim_idle`, `strafe_left` e `strafe_right` na
biblioteca: **quando essas capturas forem adicionadas ao `tools/build_dylan_animations.gd`
com esses nomes, passam a ser usadas sem mudar código.**

## Verificação

`tests/check_combat.gd` (`combate`), headless, **808 ticks, 0 falhas**. Cada asserção
nova foi verificada contra o próprio defeito, reintroduzindo-o (dez defeitos):

| Defeito reintroduzido | O probe acusou |
| --- | --- |
| Linha de visada ignora paredes | Auto-mira pegou o alvo escondido; Tab chegou nele |
| Tanque anda com a arma erguida | Pés não plantados: 0,817 m |
| Alvo abatido segue mirável | Alvo caído ainda atrai a mira; a arma não passou ao próximo |
| Recarga não desconta do estoque | 5 balas recarregadas e 5 ainda no estoque |
| Livre 360 guardado em espaço de tela | Rumo derivou andando; corte de câmera mexeu a mira |
| Livre 360 tratado como cursor | Mouse para a direita não girou a mira |
| Braço direito fora da pose | Antebraço a 48,4° do tiro (com a pose: 0,00°) |
| Assistência sem limite de cone | Puxou um alvo a 40° do cursor |
| Cadência ignorada | Dois disparos no mesmo quadro |
| Altura do tiro fixa em 1,6 m | Tiro saindo de 1,60 m num corpo de 1,8 m |

Também medidos: corpo travado no alvo a < 0,02 rad; giro à mão = `tank_turn_speed`
± 0,05 rad; caminhada mirada a 1,26 m/s, perpendicular ao corpo (|cos| < 0,25) e
encarando o ponto do cursor a < 0,03 rad; a página de jogabilidade percorre os três
modos e dá a volta; o probe não altera `user://settings.cfg`.

Duas armadilhas do Godot 4.7 encontradas no caminho, registradas no probe:
`Input.action_press` só aparece como *just pressed* no quadro físico **seguinte**; e
o resultado de um `SkeletonModifier3D` só é legível em `modification_processed` /
`skeleton_updated` — lido depois, `get_bone_global_pose` devolve a pose sem o
modificador.

## Limites

- **Pose procedural, não captura.** Lê como "pistola com as duas mãos", mas sem
  recuo, sem inclinação do tronco e sem transição de sacar. Andar de lado usa o clipe
  de caminhada para frente: as pernas não acompanham o deslize. Faltam do Mixamo:
  `aim_idle`, `strafe_left`, `strafe_right`, caminhada mirada para frente/trás,
  disparo e recarga.
- Sem som de disparo, sem cápsulas, sem marca de impacto.
- O carregador não vai para o salvamento; uma sessão retomada começa com o
  carregador cheio. A reserva vai (é o `SupplyStock`).
- Não há inimigos: os alvos de treino são o único consumidor de `Hurtbox`/`Health`.
  Dano ao Dylan, esquiva e morte do jogador não existem.
- Gamepad sem mapeamento.
- No estande, o HUD do terminal mostra "PISTOLA: NÃO" e o objetivo da estrada,
  porque a arma é emprestada e o estande não tem objetivo próprio.
