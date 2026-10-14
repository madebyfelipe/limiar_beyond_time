# Cryopteryx — redução, rig novo e cena de estudo

Feito em 13/10/2026 a partir do modelo entregue pelo usuário
(`model-rigged.glb`, gerado no Tripo). Abra **`executar-cryopteryx.cmd`** para
ver: teclas 1–6 ou botões escolhem o clipe, ←/→ giram a câmera, "Move across
the floor" liga o deslocamento e Esc sai. O poste amarelo tem 1,8 m, a altura
do Dylan.

É uma cena de estudo: não há ator, colisão, IA nem dano. Anatomia, escala e
comportamento do animal continuam provisórios, como pede o `PLAN.md`.

## O que chegou

| Propriedade | Verificação direta |
| --- | --- |
| Arquivo | 39.226.348 bytes; SHA-256 `2d71f62374fda23bd9dd5eb040fa71febc6396f06f8667adeae5783c04e4f859` |
| Gerador declarado | `Tripo` 2.0; conta de origem, licença e aprovação não verificadas |
| Geometria | 990.804 triângulos, 511.675 vértices, uma textura JPEG 2048² |
| Forma | Raptor bípede de braços emplumados e cauda longa, 1,0 de comprimento por 0,47 de altura nas unidades do arquivo, parado **no meio de uma passada** |
| Rig | 33 ossos, sem animações |

O rig automático não foi aproveitado. A espinha se chama `Left_Limb` e a cauda
`Spine`; um braço tem dedos e o outro não; uma perna tem dedos e a outra é uma
cadeia de três ossos que não acompanha a malha; não há pelve; cada perna pende
de um osso diferente.

O original não vai para o Git (39 MB): fica em `.local/cryopteryx/`, ignorado.
O que entra no repositório é a malha reduzida.

## Redução — `tools/reduce_cryopteryx.py`

A superfície é de facetas planas desenhadas com milhares de triângulos cada.
O Decimate em modo Collapse pesa cada aresta pelo erro que acrescenta, então
as facetas esvaziam primeiro e sobram os vincos entre elas.

| | Original | Reduzido |
| --- | --- | --- |
| Triângulos | 990.804 | **6.000** |
| Vértices soldados | 511.675 | 3.025 |
| Textura | 2048² (717 KB) | 1024² (169 KB) |
| Arquivo | 39,2 MB | `model_base.glb`, 783 KB |

A malha reduzida é uma ilha só, com 108 arestas abertas (não conferi se as
frestas já estavam no original), e faces planas, como a fonte. Mantém a pose e
a textura, sem esqueleto. Vistas ortográficas da malha reduzida inspecionadas:
silhueta, garras e listras preservadas.

## Rig — `tools/rig_cryopteryx.py`

Eixos do Blender: +Y frente, +Z cima, −X o lado esquerdo do animal.

1. **Marcos.** As articulações foram lidas em vistas ortográficas com grade
   (0,05 por linha) e conferidas contra fatias dos vértices por altura. Tronco,
   pescoço, cabeça, cauda e braços são simétricos na malha; as pernas não: a
   esquerda está à frente e a direita atrás.
2. **Pele sobre a pose em que a malha veio.** Um esqueleto provisório segue
   cada perna onde ela está, e os pesos vêm da solução de calor do Blender
   (todos os 3.025 vértices receberam peso), limitados a quatro influências.
3. **Pôr de pé.** Cada osso das pernas gira até a direção de pé e estica até o
   comprimento médio das duas pernas, e o resultado é congelado como forma de
   repouso. Giros aplicados: coxa 1,9° / 36,4°, canela 38,3° / 29,6°, tarso
   15,7° / 2,2°, dedos 27,3° / 3,5° (esquerda / direita); esticamento entre
   0,86 e 1,19, que é quanto as duas pernas da malha discordavam.
4. **Rig do jogo**, construído sobre essa malha neutra: 26 ossos, com o lado
   esquerdo espelho exato do direito.

A primeira pose de pé usava a direção média das duas pernas e saía quase
reta, a 95 % do alcance: sem folga para a passada, o ajuste reduzia a
caminhada à metade e ainda errava o apoio em 2,3 cm. A pose atual dobra a perna
(coxa 30° à frente, canela 40° para trás, tarso 25° à frente) e a caminhada do
doador cabe inteira.

| Região | Ossos |
| --- | --- |
| Tronco | `root`, `pelvis`, `spine`, `chest` |
| Pescoço e cabeça | `neck_01`, `neck_02`, `head` |
| Cauda | `tail_01` … `tail_05` |
| Braço, por lado | `upper_arm`, `forearm`, `hand` |
| Perna, por lado | `thigh`, `shin`, `tarsus`, `toes` |

Como no Keleken, as pernas têm IK de dois segmentos até o jarrete, o tarso
acompanha o pé e os controles (`CTRL_foot`, `CTRL_knee`, `CTRL_toes`) ficam só
no `.blend`: o GLB leva os 26 ossos de deformação com os clipes assados a 30 fps.

Medidas da cópia de estudo: **3,20 m** de comprimento, 1,51 m de altura, quadril
a 1,01 m, frente −Z. `CryopteryxVisual.target_length` reescala o modelo.

## Clipes

Todos vêm do Velociraptor CC0 da Quaternius, o mesmo doador do Keleken
(`assets/models/keleken/source/donor/`, licença ao lado). Aqui o encaixe é
melhor: mesma perna, braços e cauda de cinco ossos, que passam um a um.
Tronco, pescoço, cabeça, cauda e braços recebem as rotações do doador medidas
contra a pose de repouso de cada rig; os pés seguem os alvos de IK dele,
escalados pela perna (0,303).

| Clipe | Duração | Loop | Observação |
| --- | --- | --- | --- |
| `idle` | 2,5 s | sim | respiração e cauda |
| `walk` | 1,267 s | sim | apoio a **1,236 m/s**, passada inteira do doador |
| `run` | 0,533 s | sim | apoio a **3,315 m/s**, passada a 80 % |
| `attack` | 0,833 s | não | ergue e investe; a cabeça chega mais longe a 48 % (0,40 s) |
| `jump` | 1,133 s | não | salto no lugar |
| `death` | 1,3 s | não | cai de lado e fica |

Para referência: Dylan corre a 3,8 m/s e o Keleken persegue a 3,4 m/s.

## No Godot

| Arquivo | Papel |
| --- | --- |
| `assets/models/cryopteryx/cryopteryx_animated.glb` | malha, textura, pele e os seis clipes (1,5 MB) |
| `assets/models/cryopteryx/animation_manifest.json` | ossos, medidas, clipes, janelas de apoio, velocidades e hashes |
| `assets/models/cryopteryx/source/cryopteryx_rig.blend` | fonte editável com os controles |
| `actors/cryopteryx/cryopteryx_visual.gd` | `CryopteryxVisual`: toca os clipes, cadência ligada à velocidade, volta a `idle` depois de um gesto (a morte fica) |
| `environments/cryopteryx_animation_study.tscn` | a cena de estudo |
| `tools/capture_cryopteryx_pose.gd` | renderiza poses escolhidas para revisão |

## Reproduzir

```powershell
& '.tools/blender-4.5.3/blender-4.5.3-windows-x64/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/reduce_cryopteryx.py
& '.tools/blender-4.5.3/blender-4.5.3-windows-x64/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/rig_cryopteryx.py -- --preview
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --import
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_all.gd -- --only=cryopteryx-animacao
```

A redução precisa do original em `.local/cryopteryx/model-rigged.glb` (ou do
caminho passado depois de `--`) e confere o hash. O rig só precisa do
`model_base.glb`. `--preview` grava quadros de cada clipe em `.local/cryopteryx/`.
Executar o gerador reconstrói o `.blend`: edições manuais nele se perdem.

## Verificação

`tests/check_cryopteryx_animation.gd` (probe `cryopteryx-animacao`): **zero
falhas**, medindo o GLB exportado.

- 6.000 triângulos, textura presente, 3,20 m.
- 26 ossos, nenhum do rig descartado, frente −Z, sete pares por lado espelhados
  a menos de 1 mm, tronco e cauda na linha média, pesos normalizados.
- De pé, os dois pés no chão a menos de 3 cm.
- Seis clipes com a duração e o loop do manifesto; `idle`, `walk` e `run`
  fecham sem emenda; `NATIVE_SPEED` igual ao manifesto.
- Apoio: deslize do pé plantado de 0,08 m/s na caminhada e 0,27 m/s na corrida,
  altura de contato a 1,3 mm e 3,2 mm, pele no máximo 3,2 cm abaixo do chão.
- Ataque avança a cabeça 0,26 m no instante registrado; o salto sobe o quadril
  0,64 m e os pés 0,84 m; a morte termina com cabeça a 0,33 m, quadril a 0,48 m
  e pele 2 cm abaixo do chão.
- Na cena de estudo, com o deslocamento ligado: deslize de 0,02 m/s (caminhada)
  e 0,12 m/s (corrida); um gesto volta a `idle`.

Duas asserções testadas contra o próprio defeito: velocidade nativa errada
(3 falhas) e gesto que não volta a `idle` (2 falhas).

Inspeção visual: quadros dos seis clipes no Blender, doze capturas no Godot
(lado e três quartos) e a cena de estudo em execução.

Regressões na mesma execução, zero falhas: `keleken-animacao`, `cenas`
(29 cenas), `mapa`, `inventario`. Suíte completa e probes gráficos não rodados.

## Limites

- **Mesmo doador do Keleken.** Caminhada, corrida, ataque e morte dos dois
  animais saem dos mesmos clipes; o que distingue o Cryopteryx hoje é o corpo,
  os braços, a cauda e o salto. Clipes próprios (golpe de cauda, rugido, reação
  a tiro) ainda não existem.
- **Sem mandíbula.** A boca da malha é uma linha na textura; abrir exigiria
  geometria nova.
- **Mãos e pés de um osso cada.** Garras e dedos acompanham rígidos.
- **Os dois pés não são iguais.** Uma garra interna pende 2,8 cm mais que a
  outra; o chão ficou no meio, então uma afunda e a outra flutua 1,4 cm.
- **Marcos lidos à mão**, com erro da ordem de 1 cm nas unidades do arquivo
  (3 cm no jogo). O tornozelo é o ponto mais incerto, como mostram os
  esticamentos do passo 3.
- **Pele automática**, sem pintura manual: a dobra do quadril e do ombro não foi
  revisada pose a pose.
- Escala, velocidades e nomes dos clipes são de estudo; nenhum ator os usa.
