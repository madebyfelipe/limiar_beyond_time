# Inventário, baús e mensagens

Data: 13/10/2026. Três peças que trabalham juntas: a **maleta** (grade à moda de
Resident Evil 4), os **baús de suprimentos** espalhados pelos cenários e a
**faixa de mensagens** à moda de Resident Evil 4 / Dino Crisis. A interface é
propositalmente simples (retângulos e rótulos): o visual fica com quem cuida
da UI. As regras moram em `systems/inventory/`; a apresentação, em `ui/`.

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

| Entrada | Efeito |
| --- | --- |
| Setas / direcional | Move o cursor célula a célula |
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
