# Inventário, baús e mensagens

Data: 13/10/2026. Três peças que trabalham juntas: a **maleta** (grade à moda de
Resident Evil 4), os **baús de suprimentos** espalhados pelos cenários e a
**faixa de mensagens** à moda de Resident Evil 4 / Dino Crisis. A interface usa
um console de equipamento inspirado em Dino Crisis 2, com painéis metálicos,
seleção âmbar, retratos dos itens e textos nativos. As regras moram em
`systems/inventory/`; a apresentação, em `ui/`.

## Maleta — `Inventory` (`systems/inventory/inventory.gd`)

- Grade de **10 × 6** células. Cada item ocupa um retângulo do próprio tamanho
  e pode ser girado 90°:

  | Item | Tamanho | Pilha |
  | --- | --- | --- |
  | PISTOL | 3 × 2 | 1 |
  | SHOTGUN | 8 × 2 | 1 |
  | HANDGUN AMMO | 2 × 1 | 50 |
  | SHOTGUN SHELLS | 2 × 1 | 15 |
  | MED KIT | 1 × 2 | 1 |

- **O que está na maleta é o que Dylan tem.** Uma arma só está na mão se estiver
  na maleta (`PlayerWeapon.owns`). Cada arma recarrega da **própria munição**
  (`WeaponDefinition.ammo_item`): pistola de HANDGUN AMMO, shotgun de SHOTGUN
  SHELLS. Kits médicos (H / R3) saem da maleta.
- Entrada de itens: completa as pilhas existentes e depois procura o primeiro
  espaço livre, linha a linha, em pé antes de deitado. O que não cabe é
  devolvido a quem tentou guardar.
- Um jogo novo começa com a **maleta vazia**.

### Menu da maleta — `InventoryMenu` (`ui/inventory_menu.gd`)

**I** no teclado, **Share / Back** no gamepad (ação `inventory`, remapeável).
Pausa o jogo enquanto aberto.

A abertura reproduz o efeito de TV ligando em 0,52 s: uma linha luminosa
se expande e revela o console. O efeito continua com o jogo pausado,
reinicia a cada abertura e é cancelado imediatamente ao fechar.

A apresentação segue a imagem de referência fornecida: aço escuro texturizado,
molduras chanfradas, parafusos e foco âmbar. A coluna esquerda mostra o retrato
renderizado do modelo de Dylan, condição **FINE / CAUTION / DANGER** com vida
numérica e traçado animado, arma equipada, munição e atributos reais da arma.
O traçado é decorativo; o número e a condição representam a saúde do jogador.
A imagem do cenário atual e os créditos ficam abaixo. O centro contém a grade;
a coluna direita contém ações contextuais e EXIT. A faixa inferior mostra o
retrato do item selecionado e sua descrição.

Abas **ALL ITEMS / WEAPONS / AMMO / RECOVERY** destacam a categoria escolhida.
Itens de outras categorias ficam escurecidos, indicando o espaço que ocupam,
e não oferecem ações até mudar de aba. MOVE retorna a ALL ITEMS; durante a
colocação as abas ficam bloqueadas. A grade continua 10 × 6, com as mesmas regras.
O cursor âmbar indica seleção; ao mover, verde indica que cabe e vermelho
indica conflito. A composição é 1920 × 1080 (16:9), com grade central, abas,
ações e faixa de descrição ampliadas para ocupar a largura da tela. Textos,
retratos e ícones mantêm suas proporções. Em telas 4:3, o ajuste uniforme
adiciona barras acima e abaixo.

Ícones ajustam-se pela área visível, desconsiderando margens transparentes;
armas e suprimentos ocupam melhor as células sem deformação, inclusive girados.
As quantidades usam números maiores para leitura em 720p.

Os cinco ícones usam a arte v06 baseada na referência aproximada enviada:
caixas de munição vermelhas, kit médico verde em estojo rígido e armas com
metal e madeira texturizados. As imagens têm fundo transparente e iluminação
consistente; números, contornos e foco continuam separados da arte.
Prompts e referência estão documentados em `assets/ui/inventory/README.md`.
Capturas: `docs/evidence/ui/inventory-artstyle-v06.png`,
`inventory-artstyle-ammo-720-v06.png` e `inventory-artstyle-recovery-v06.png`.

Captura com ícones ampliados: `docs/evidence/ui/inventory-icons-wide-v05.png`.
Capturas da revisão 16:9: `docs/evidence/ui/inventory-wide-v04.png` e
`inventory-wide-empty-720-v04.png`.
O script `tools/preview_inventory_ui.gd`
também captura inventário vazio, ações, rotação e colocação inválida.

| Entrada | Efeito |
| --- | --- |
| Setas / direcional | Move o cursor célula a célula |
| Tab / Shift+Tab; L1 / R1 (LB / RB) | Troca a aba de categoria |
| Mouse | Clica nas abas, seleciona células e executa ações; duplo clique abre ações |
| Enter / E / ✕ sobre um item | Abre as ações: EQUIP (arma), USE (kit), MOVE, CANCEL |
| MOVE → setas | Carrega o item; contorno verde cabe, vermelho não |
| R / □ carregando | Gira o item |
| Enter / E / ✕ carregando | Larga o item, se couber |
| Esc / ○ / I | Fecha as ações, solta o item de volta ou fecha a maleta |

O filtro de apresentação perdeu o botão Share do gamepad para a maleta; continua
em **F4** e no menu de pausa. Perfis de controle salvos antes desta mudança têm
o Back removido do filtro na primeira leitura.

## Baús — `ItemChest` e `ChestStore`

- `ChestStore` guarda o que **cada baú ainda tem**. Um baú nunca aberto tem o
  conteúdo autorado em `ChestStore.AUTHORED`; o que não coube na maleta fica lá
  para a próxima visita.
- `ItemChest` é uma interação como a porta e o terminal (`ApproachPrompt`):
  **E** no ponto de aproximação pergunta *"A supply crate. Open it?"* com
  Não/Sim; Sim lê cada item recebido numa página: *"You obtained HANDGUN AMMO
  ×30."*, e avisa o que ficou: *"There is no room in the case for … It stays in
  the crate."* Baú vazio diz *"The crate is empty."*
- **Primeiro baú**: sala da guarita, sobre a caixa `SupplyChest` que já existia
  na geometria da sala (centro (−2,5; 0,32; 1,82), 0,75 × 0,64 × 0,9 m).
  Aproximação na face leste, em (−1,7; 0; 1,82), raio 0,6 m, fora do círculo da
  porta. Conteúdo inicial: **30 HANDGUN AMMO e 10 SHOTGUN SHELLS**, a munição das
  duas armas.
- **Compras do terminal vão para esse baú.** `buy weapon` entrega a pistola,
  `buy shotgun` a shotgun, e `ammo`/`shells`/`medkit` entram junto. Comprou a
  arma, abre o baú e ela vai para a maleta. Cada arma é vendida uma vez
  (`SupplyStock.weapon` / `shotgun` registram a compra, não a posse).
- Novo baú em outra sala: uma entrada em `ChestStore.AUTHORED` e um `ItemChest`
  com `crate_id`, `approach` e `radius` montado pela cena, como em
  `environments/save_room.gd`.

## Faixa de mensagens — `MessageBox` (`ui/message_box.gd`)

Faixa escura sobre a parte de baixo da imagem, texto monoespaçado datilografado,
nomes de itens em verde e, quando há pergunta, **No / Yes** embaixo. O jogo para
enquanto a faixa está aberta; nada mais recebe entrada.

```gdscript
await MessageBox.say(self, ["You obtained %s." % MessageBox.item("PISTOL")])
var yes: bool = await MessageBox.say(self, ["Open it?"], ["No", "Yes"]) == 1
```

Confirmar (E / Enter / ✕) mostra a página inteira e depois avança; ←/→ escolhem
a resposta; Esc/○ escolhe a primeira, que é sempre a segura (*No*).

Usos atuais: baús e o **portão norte trancado** do pátio, que agora diz na faixa
*"The north gate is bolted." / "Record your progress at the GUARDHOUSE TERMINAL
before going on."* em vez do aviso passageiro.

## Salvamento e portas

Créditos, compras, maleta e baús viajam juntos em `SupplyStock.snapshot()`
(chaves `case` e `chests`), então portas, `save` e LOAD GAME conservam tudo sem
mudar o formato do arquivo. Saves de antes da maleta são migrados: armas já
compradas e os cartuchos (pool único antigo, vira HANDGUN AMMO) entram direto na
maleta; o baú da guarita mantém seu conteúdo inicial.

## Verificação

`tests/check_inventory.gd` (probe `inventario` do `run_all.gd`): regras da grade
(pegadas, pilhas, giro, bordas, maleta cheia, snapshot adulterado), entrega das
compras no baú, migração de save antigo pelo arquivo real, caminhada até o baú
com o controlador real, Não/Sim, os três itens anunciados com destaque, compra
posterior no mesmo baú, baú vazio, sobra que fica no baú, recarga da shotgun
tirando só cartuchos de shotgun, arma fora da maleta sai da mão, menu (EQUIP,
MOVE + giro + recusa na borda, USE) e a mensagem do portão. A asserção de
munição foi testada contra o próprio defeito (shotgun sem `ammo_item` → 2
falhas). Resultado: 496 ticks, zero falhas.

`tools/preview_inventory_ui.gd` captura a faixa e a maleta em
`.local/ui-message-box.png` e `.local/ui-inventory.png` para o trabalho de UI.

## UI — 13/10/2026

A maleta usa um forro de espuma grafite, moldura metálica e grade 10×6 à
esquerda. Os retratos da pistola e shotgun são renders dos modelos usados no
jogo, com transparência; munição e kit médico têm ilustrações nativas. Contagem
de munição, indicador E de arma equipada, espaço ocupado e créditos são dados
vivos. À direita ficam o retrato ampliado, descrição, tamanho e ações do item.

A seleção é marcada por cantos verdes. Durante MOVE, o retrato acompanha a
rotação, com verde quando cabe e vermelho quando a posição é inválida. A barra
inferior mostra as teclas de organização e troca para os símbolos PlayStation
ou Xbox conforme o dispositivo ativo. R mostra o bind atual da ação reload.

A faixa de mensagem usa texto creme, itens em verde, uma linha fina e foco
visível em No/Yes. O layout é ajustado uniformemente à composição 16:9,
inclusive em janela 4:3, sem alterar datilografia, pausa ou escolhas.

Arquivos de arte e prompt em `assets/ui/inventory/`. A textura foi criada com
ImageGen integrado; as armas são reproduzíveis com
`tools/render_inventory_icons.gd`. Textos, grade e controles continuam nativos.

A prévia também captura ações, posição inválida, giro, maleta vazia em 720p,
janela 4:3, dicas PS4 e mensagem longa em 4:3. Execute:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --fixed-fps 60 --script res://tools/preview_inventory_ui.gd
```

Verificação desta integração: suíte headless completa com **36 probes, zero
falhas**; inventário em OpenGL Compatibility com **496 ticks, zero falhas**.
As capturas foram inspecionadas em 1920×1080, 1280×720 e 1280×960, com o filtro
retro ativo. Os logs do runner e do probe gráfico foram preservados em
`evidence/ui/inventory-headless-v01.txt` e `evidence/ui/inventory-graphical-v01.txt`.

Capturas: [maleta](evidence/ui/inventory-v01.png),
[mensagem](evidence/ui/message-obtained-v01.png),
[pergunta](evidence/ui/message-question-v01.png),
[giro](evidence/ui/inventory-rotated-v01.png),
[posição inválida](evidence/ui/inventory-invalid-v01.png),
[PS4 em 4:3](evidence/ui/inventory-ps4-4x3-v01.png).
