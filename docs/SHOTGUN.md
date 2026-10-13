# Escopeta — segunda arma (13/10/2026)

Pedido: "the rifle should be a new shotgun with 2 rounds". A segunda arma deixou de
ser o rifle e virou uma escopeta de dois canos lado a lado. Continua sendo um
`WeaponDefinition` (`resources/combat/shotgun.tres`) sobre o mesmo `PlayerWeapon`.
O rifle (`rifle.tres`, `assets/models/weapons/rifle/`, `tools/build_rifle.py`) foi
removido; continua no histórico do Git.

| | Pistola | Escopeta |
| --- | --- | --- |
| Dano | 25 por tiro | 14 por chumbo, 8 chumbos (até 112) |
| Dispersão | — | cone de 6° (meio-ângulo) |
| Intervalo entre tiros | 0,32 s | 0,5 s |
| Carga | 15 | **2 cartuchos** |
| Recarga | 1,6 s | 2,2 s |
| Alcance | 30 m | 20 m |

## Tiro em leque

`WeaponDefinition` ganhou `pellets` (raios por disparo) e `spread_degrees`. A pistola
fica com 1 e 0. Em `PlayerWeapon.fire()`, o primeiro chumbo vai exatamente na
direção da mira e é o tiro que o retorno visual mostra (`last_shot`). Os outros se
espalham pelo cone com distribuição uniforme na área, e cada um que acerta um
`Hurtbox` aplica `damage`. `last_shot.pellet_hits` conta os acertos. Com os dois
cartuchos gastos, puxar o gatilho recarrega, como na pistola.

## Como obter e trocar

- **Estande de tiro** (Extras → Firing Range): as duas armas, sempre.
- **Campanha:** no terminal, `buy shotgun` custa 2.200 créditos. A compra é salva
  pelo `save`, no campo `shotgun` de `SupplyStock`. Saves antigos com `rifle: true`
  continuam donos da arma longa. `inventory` e `shop` mostram a escopeta.
- **Trocar:** **roda do mouse** (para baixo: próxima arma; para cima: anterior),
  tecla **X** ou **Misc1** no controle. As ações da roda são `weapon_next` e
  `weapon_previous`, lidas pelo singleton `Input`. Os eventos de roda nunca chegam ao
  `_unhandled_input` do jogador, porque o `Control` raiz de cada fase os consome e o
  jogador vive num `SubViewport`. Com a mira levantada no modo TARGET LOCK, a roda
  continua alternando alvos (`lock_next_target`).
- Cada arma tem a própria carga; a reserva de munição é compartilhada. A arma em
  mãos e as cargas atravessam portas.

## Visual

- Modelo original low-poly gerado por `tools/build_shotgun.py` no Blender portátil:
  736 triângulos, uma malha, seis materiais (aço oxidado, báscula, nogueira). Origem
  na empunhadura, `Muzzle` entre as bocas dos canos e `Support` na telha. Prévia em
  `assets/models/weapons/shotgun/shotgun_preview.png`.
- Dylan usa as capturas de rifle do Mixamo (por isso os clipes continuam `rifle_*`).
- **Empunhadura:** a escopeta segue o osso da mão direita (`SHOTGUN_GRIP` em
  `dylan_visual.gd`, medido na captura de mira e trazido para a palma, onde fica a
  empunhadura da pistola). Antes, a arma seguia a linha entre os dois pulsos. No
  *Two Hand Rifle Idle* as mãos ficam lado a lado, então a arma apontava para o lado
  do corpo.
- **Na palma:** a mão fechava 7–9 cm à esquerda da arma, e o gatilho ficava fora dela.
  `SHOTGUN_PALM_SHIFT` desloca a arma no próprio eixo até a palma (entre o pulso e o
  nó do dedo médio) encostar no lado direito da empunhadura. O polegar passa por
  cima, à esquerda, e o indicador chega ao guarda-mato, no porte baixo e na mira.
- **Mão esquerda na telha:** as capturas de rifle seguram um guarda-mão em outro
  lugar, e os canos ainda giram para a mira, então a mão esquerda ficava solta. O
  modificador `actors/player/support_hand_pose.gd` roda depois dos outros. Ele
  posiciona a escopeta pela mão direita já final, gira a mão esquerda de palma para
  cima sob a telha (dedos fechando pelo lado direito, polegar para a frente pelo
  esquerdo) e leva o braço até lá por IK de dois ossos, mantendo o cotovelo no plano
  do clipe. O encaixe fica em `SHOTGUN_SUPPORT_PALM/FINGERS/THUMB`. A mão entra e sai
  em 0,125 s e larga a arma em portas, cutscenes e na morte. As poses modificadas só
  existem durante `skeleton_updated` (o Godot 4.4+ as desfaz depois), e é lá que
  `check_shotgun.gd` confere a palma a menos de 2 cm da telha, com a arma baixa e
  na mira.
- **Mira e laser:** com a arma levantada, os canos giram em torno da empunhadura até
  o ponto onde o tiro vai acertar (`PlayerWeapon.aim_end()`, o raio do peito). Assim
  o laser sai reto dos canos. Antes, ele saía da boca a 1,55 m e descia torto até a
  linha do peito, a 1,2 m. A menos de 1,5 m do alvo os canos não giram.

## Velocidade das capturas armadas

As velocidades nativas dos ciclos armados (`NATIVE_SPEED`) estavam 20–45 % baixas,
então as pernas giravam rápido demais e os pés escorregavam. O pior caso era a
corrida com a escopeta: `rifle_run` estava em 2,60, mas a captura anda 3,83 m/s, e
o pé de apoio deslizava **1,85 m/s**. `tools/measure_clip_speeds.gd` mede cada clipe
pelo dedo do pé de apoio sob o quadril parado; esse método devolve 1,51 para o
`walk`, cuja tabela diz 1,48. Os valores novos estão na tabela. `rifle_walk` ficou em
1,05, o melhor de uma varredura no jogo. Com a escopeta, o deslize medido por
`check_foot_contact.gd` ficou em cerca de 0,25 m/s andando e 0,35–0,44 m/s correndo.

## Validação

`tests/check_shotgun.gd` (`shotgun` no executor) cobre a definição, a compra, o save
e a compatibilidade com saves do rifle, a troca pela ação e pela roda do mouse (nos
dois sentidos), os dois disparos, a recarga ao puxar o gatilho com os canos vazios,
as cargas separadas, a recarga cancelada na troca, o visual (arma na mão, clipes
`rifle_`, saída pela boca da escopeta, sem a postura da pistola), a travessia de
cena e a posse só da escopeta. `check_foot_contact.gd` também mede o andar e a
corrida com a escopeta.
