# Presets de apresentação

Data: 11/10/2026. Pedido do usuário: "adicione presets de filtros no menu. Um com
OCR lines, outro com o formato meio olho de peixe de tvs antigas, defina presets".
Lido como linhas de varredura (CRT) e curvatura de tubo. Substitui o ciclo
Original/PSX/PSX+CRT descrito em `RETRO_FILTER.md`, que passa a ser histórico.

## A ideia

Um preset **não é um shader próprio**: é um conjunto nomeado de botões sobre o
mesmo shader. O framebuffer PSX é sempre a base — 320 × 180 virtuais, cor de 5
bits, dithering ordenado Bayer — e cada preset acrescenta o que aquela tela fazia
com ele. Acrescentar um preset é acrescentar uma linha na tabela de
`systems/rendering/retro_filter.gd`.

## Os quatro

| Preset | Varredura | Grade | Curvatura | Vinheta | Ganho | Para quê |
| --- | --- | --- | --- | --- | --- | --- |
| **Original** | — | — | — | — | — | Sem efeito nenhum. É o modo de calibração: medir arte contra geometria exige a imagem como ela foi renderizada. |
| **PSX** | — | — | — | — | — | Só o framebuffer da época. Padrão do jogo. |
| **PSX + linhas** | 0,55 | 0,32 | — | 0,18 | 1,38 | O mesmo visto num monitor: uma banda escura por linha virtual e grade de abertura nas colunas. |
| **TV de tubo** | 0,42 | 0,26 | 0,55 | 0,34 | 1,34 | O mesmo visto numa TV de tubo: vidro curvo, imagem estufada, cantos sem imagem e quinas apagadas. |

**Ganho.** Varredura, grade e vinheta só tiram luz. Sem compensação, trocar de
preset parecia baixar o brilho em vez de trocar de tela. O ganho devolve parte da
luz antes da quantização, para o dithering acontecer sobre o valor exibido. Não é
compensação total — isso estouraria as altas-luzes.

**Grade e varredura seguem o pixel virtual, não a janela.** As listras têm a
largura do framebuffer, então não mudam de espessura quando a janela muda de
tamanho. É também o que mantém o contrato "pixel virtual sem variação interna"
válido no preset PSX, verificado em 1280 × 720, 1920 × 1080 e 1280 × 960.

**A borda do tubo é máscara, não `return`.** `fragment()` do Godot não aceita
`return` antecipado; o que sai do vidro é multiplicado por zero no fim.

## Como se troca

- **F4** em qualquer cena percorre os quatro, com aviso na tela.
- **Esc → FILTRO: …** no menu de pausa percorre a mesma tabela.
- A escolha vai para `user://settings.cfg`, seção `[video]`, e vale entre sessões
  e entre cenas, inclusive no close da porta. Probes rodam com `--script`: não
  leem nem gravam esse arquivo, para não mexer na preferência de quem joga.

## Verificação

`tests/check_retro_filter.gd` (`filtro-retro`), gráfico, **0 falhas**. F4 percorre
os quatro e dá a volta; repetição de tecla não conta; os quatro presets são
**diferentes dois a dois** na imagem (seis comparações); Original restaura a
imagem exatamente; a escolha sobrevive à troca de cena e chega ao shader; e o
botão do menu percorre a mesma tabela.

As duas características pedidas foram medidas, não só olhadas:

| Medida | PSX | Preset | Razão |
| --- | --- | --- | --- |
| Pixels sem imagem (borda do vidro) | 381 | 11 851 (TV de tubo) | 31 × |
| Diferença entre linhas vizinhas (varredura) | 4 673 | 15 505 (PSX + linhas) | 3,3 × |

Capturas dos quatro em `.local/retro-0..3.png`, geradas pelo próprio probe.

## Limites

- É pós-processamento da composição 16:9, não emulação de hardware: não há jitter
  de vértices, nem *warping* de geometria, nem custo reduzido de renderização.
- O HUD e o menu ficam **fora** do filtro, de propósito: texto continua nítido.
- A curvatura não deforma a área clicável nem a física; é só imagem.
- Sem medição de desempenho dos presets novos na máquina de referência.
