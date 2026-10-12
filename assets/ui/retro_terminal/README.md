# UI de terminal CRT — v01

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

As imagens v01 são os conceitos originais com textos gravados. As versões `*_skin_v02.png`, editadas com image_gen, retiram botões e dados fixos para receber controles reais no Godot. Terminal, loja, HUD e pausa agora consomem essas skins. O HUD preserva alpha fora dos painéis. Os prompts das edições estão em `*_skin_v02.prompt.txt`.

SHOP compra suprimentos com créditos reais do protótipo, e SAVE guarda o estoque junto do registro único de progresso. O HUD apresenta créditos, kits, munição em estoque, aquisição da pistola, objetivo e interação próxima. Combate, disparo e consumo de kits ainda não existem. A pausa conserva controles e filtro, com cinco opções ao todo.

Fluxo, scripts, verificação e capturas reais: [RETRO_UI.md](../../../docs/RETRO_UI.md). A navegação aceita mouse, setas/Tab, Enter e Esc, mantendo a mesma escala para arte e áreas clicáveis em 16:9 e 4:3.

