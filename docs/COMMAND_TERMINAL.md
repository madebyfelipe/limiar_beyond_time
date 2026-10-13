# Terminal de comandos — 11/10/2026

O computador da guarita agora abre uma sessão simulada com prompt `GUARITA>`,
texto verde monoespaçado, cursor piscando e histórico rolável. O menu de botões
SAVE/SHOP e sua arte de fundo foram substituídos por controles nativos do Godot.
Os comandos acionam os sistemas do jogo; o terminal não executa um shell do sistema.

## Usar

Abra `executar-sala.cmd` ou entre na guarita pelo exterior. Aproxime-se da mesa,
pressione **E**, digite um comando e pressione **Enter**. O mundo fica pausado
durante a sessão. Abrir o terminal ou pressionar Enter com a linha vazia não salva.

| Comando | Ação |
| --- | --- |
| `help` / `help buy` | Lista os comandos ou explica um comando. |
| `save` | Grava posição, orientação, objetivo e estoque no registro existente. |
| `shop` | Lista produtos, preços e créditos. |
| `buy ammo` | Compra 30 cartuchos de pistola por 300 créditos. |
| `buy shells` | Compra 10 cartuchos de shotgun por 400 créditos. |
| `buy medkit` | Compra um kit médico por 500 créditos. |
| `buy weapon` | Adquire a pistola por 1800 créditos, uma vez. |
| `buy shotgun` | Adquire a shotgun por 2200 créditos, uma vez. |
| `inventory` | Mostra créditos, a maleta e o que espera no baú. |

Toda compra é **entregue no baú de suprimentos** da sala, não direto na maleta.
Ver [INVENTORY.md](INVENTORY.md).
| `status` | Mostra objetivo e último registro salvo. |
| `clear` | Limpa a tela, mantendo o histórico de comandos. |
| `exit` | Fecha o terminal e retoma a exploração. |

Compras só ficam no registro persistente depois de `save`. Créditos insuficientes,
arma já adquirida, estoque cheio, produto inválido e erro de gravação geram respostas
na própria sessão. Um `save` que falha não avança o objetivo.

Os comandos ignoram maiúsculas/minúsculas e espaços repetidos. Também existem
os aliases `ajuda`, `salvar`, `loja`, `comprar`, `inventario`, `estado`, `limpar`
e `sair`. `buy med kit`, `buy magazine` e `buy recovery` são aceitos.

## Edição e navegação

- **Tab** completa comandos e nomes de produto depois de `buy`; se houver mais
  de uma opção, mostra as sugestões sem executar nada.
- **↑/↓** percorrem o histórico e restauram a linha que estava sendo editada.
- **Ctrl+L** limpa a tela; **PageUp/PageDown** e a roda do mouse percorrem a saída.
- **Esc** fecha a sessão diretamente. A pausa não abre por cima do terminal.
- Mouse, seleção, Backspace, Home/End e edição da linha usam o LineEdit nativo.

A saída mantém até 300 linhas e o histórico até 100 comandos durante a vida dessa
sala. Reabrir o computador preserva essa sessão; trocar de cena cria uma sessão
nova. O estoque continua seguindo o fluxo de save do jogo. O console acompanha
a composição 16:9 com escala uniforme e barras em janelas 4:3, evitando uma faixa
de texto fora do filtro visual.

O HUD de exploração continua somente com VITALITY. Combate e consumo dos
suprimentos permanecem fora do protótipo.

## Implementação e verificação

`ui/terminal_menu.gd` contém a interface, histórico, autocompletar e despacho
dos comandos. `TerminalInteraction.save_progress()` continua sendo a autoridade
da gravação e publica o resultado na saída do console. O transcript usa texto
simples, sem interpretar BBCode. Não há executáveis, comandos de rede nem caminhos
arbitrários expostos ao jogador.

`check_terminal_ui.gd` passou em headless e em renderer OpenGL Compatibility com
eventos reais de teclado: digitação, Enter vazio, ajuda, histórico/draft, Tab para
comando e produto, erro de gravação, argumentos inválidos, aliases, compras,
créditos insuficientes, arma única, save/retomada, clear/Ctrl+L, rolagem, resize
4:3, foco pelo mouse e saída por `exit` e Esc. Nenhuma falha de script. Os testes
de persistência e operação dos cenários também passaram com zero falhas.

Capturas reais:

- [Abertura](evidence/ui/console-boot-v04.png)
- [Sessão com loja, estoque e save](evidence/ui/console-session-v04.png)
- [Console em janela 4:3](evidence/ui/console-4x3-v04.png)
