# UI — referências Dino Crisis 2

## Pausa e configurações — correção de 12/10/2026

`pause_menu_skin_v03.png` é a skin ativa de pausa, apresentação, jogabilidade,
configurações e remapeamento. Image_gen removeu os textos gravados e ampliou a
moldura da v02 mantendo a textura CRT; prompt em
`pause_menu_skin_v03.prompt.txt`. Cabeçalhos e instruções são labels reais em
faixas vazias da imagem. Os retângulos sólidos que cobriam títulos e rodapé
foram removidos. `RetroScreen.heading()` e `footer()` mantêm as mesmas margens
e alinhamento nas páginas, com escala uniforme em 16:9 e 4:3.

## Versão ativa v04 — console de comandos

O terminal atual é desenhado no Godot: texto verde, prompt, cursor e transcript
rolável. Nenhuma imagem de fundo é consumida pela sessão de comandos. `help`,
`save`, `shop` e `buy` substituem o menu anterior. O HUD continua com VITALITY.
Fluxo e capturas: [COMMAND_TERMINAL.md](../../../docs/COMMAND_TERMINAL.md).

## Histórico v03

Direção corrigida conforme as duas capturas fornecidas pelo usuário: HUD com apenas
a barra verde angular e VITALITY; terminal azul quase preto com SHOP/SAVE e categorias
em texto verde, sem molduras, diagramas ou painéis de dados.

- [service_background_v03.png](service_background_v03.png): fundo 4:3 do terminal,
  gerado pela ferramenta integrada image_gen. [Prompt completo](service_background_v03.prompt.txt).
- O HUD é desenhado no Godot por `ui/vitality_gauge.gd`, com fundo transparente,
  e usa o valor `PlayerController.vitality`. Não há HUD bitmap na versão ativa.
- A versão anterior usava opções verdes com foco nativo; agora usa uma linha de comandos.
- A pausa e a página de apresentação conservam suas opções existentes.

Fluxo e capturas da versão ativa: [RETRO_UI.md](../../../docs/RETRO_UI.md).

## Histórico v01/v02

Artes geradas em 11/10/2026 com a ferramenta integrada image_gen, pela skill imagegen, para LIMIAR. Direção solicitada: computador antigo inspirado nos menus de Dino Crisis 2. O terminal de salvamento foi usado como referência visual nas outras três gerações.

## Entregas

| Arquivo | Uso | Prompt |
| --- | --- | --- |
| [save_terminal_v01.png](save_terminal_v01.png) | Menu do terminal com SAVE selecionado, SHOP e EXIT | [Prompt completo](save_terminal_v01.prompt.txt) |
| [shop_v01.png](shop_v01.png) | Conceito da loja, lista de itens e BUY/BACK | [Prompt completo](shop_v01.prompt.txt) |
| [hud_overlay_v01.png](hud_overlay_v01.png) | HUD com transparência, vida, munição, objetivo e interação | [Prompt completo](hud_overlay_v01.prompt.txt) |
| [pause_menu_v01.png](pause_menu_v01.png) | Pausa com Continuar, Reiniciar, Controles e Sair | [Prompt completo](pause_menu_v01.prompt.txt) |

## Direção visual

Tela carvão/teal, contornos ciano dessaturado, seleção verde-fósforo, tipografia monoespaçada pixelada, botões angulares, cantos em colchetes, dithering e linhas CRT discretas. Formato panorâmico 16:9.

## Uso na implementação

As imagens v01 são os conceitos originais com textos gravados. As versões `*_skin_v02.png`, editadas com image_gen, retiravam botões e dados fixos para receber controles reais. As skins de terminal, loja e HUD v02 foram substituídas pela direção v03 acima; continuam como histórico. A pausa conserva a skin própria. Os prompts das edições estão em `*_skin_v02.prompt.txt`.

SHOP compra suprimentos com créditos reais do protótipo, e SAVE guarda o estoque junto do registro único de progresso. Créditos e preço aparecem apenas ao escolher um produto para comprar. Combate, disparo e consumo de kits ainda não existem.

Fluxo, scripts, verificação e capturas reais: [RETRO_UI.md](../../../docs/RETRO_UI.md). A navegação aceita mouse, setas/Tab, Enter e Esc, mantendo a mesma escala para arte e áreas clicáveis em 16:9 e 4:3.

