# Handoff — 11/10/2026, sessão Opus 5 → Opus 5.5

Estado em `cc2d4d6`, branch `main`, árvore limpa. **Não foi feito push**: `main`
local está 4 commits à frente de `origin/main`.

---

## 0. Leia isto primeiro: duas mãos no mesmo diretório

Durante a sessão, um **segundo agente (Codex)** passou a escrever neste mesmo
working tree, a pedido do usuário. Ele construiu uma UI com skin gerada por
imagem: `ui/retro_screen.gd`, `ui/retro_button.gd`, `ui/game_hud.gd`,
`ui/terminal_menu.gd`, `systems/save/supply_stock.gd`,
`assets/ui/retro_terminal/*`, `docs/RETRO_UI.md`, `tests/check_terminal_ui.gd`.

**Divisão acordada com o usuário:** Codex fica com `ui/` e `assets/ui/`; eu fico
com gameplay — `actors/`, `systems/` (exceto UI), `environments/`, `tests/`.

**Essa divisão já foi furada nos dois sentidos**, e você precisa saber onde:

| Arquivo | O que tem dentro |
| --- | --- |
| `ui/pause_menu.gd` | As duas mãos. A página com skin PNG é dele; a página de opções de apresentação (`_build_filter_page`) é minha, escrita com a API `RetroScreen` dele. |
| `tests/run_all.gd` | Os dois registramos probes (`operacao-cenarios` meu, `terminal-ui` dele). |
| `tests/check_dylan_doors.gd`, `tests/check_save_persistence.gd` | Os dois mexemos. |
| `systems/interaction/approach_prompt.gd` | Ele adicionou `add_to_group(&"approach_prompts")` no meu arquivo. |
| `environments/technical_route.gd`, `export_presets.cfg` | Alterados por ele. |

O commit `cc2d4d6` carrega o trabalho dele **inacabado e não revisado por mim**.
Commitei porque os dois editaram `ui/pause_menu.gd` e, sem os arquivos dele, o
HEAD não parseava. Não julgue aquele commit como meu.

**Antes de escrever qualquer coisa, confirme com o usuário se o Codex ainda está
ativo.** Um `find . -newermt "-10 minutes" -name "*.gd"` responde rápido.

---

## 1. Custos que essa colisão já cobrou

Registre isto antes de confiar em qualquer execução de suíte:

- Uma execução completa da suíte **morreu em silêncio no probe 21**, código de
  saída 0 e sem linha de resumo. Não é probe reprovado: é o processo pai
  encerrando. Compatível com duas instâncias do Godot competindo. Na reexecução,
  passou.
- `exterior-grafico` reprovou com `Parse Error: Could not find type "RetroScreen"`
  — a classe estava sendo escrita naquele instante.
- `filtro-retro` reprovou e, ao reexecutar, reprovou **mais**: o contrato "pixel
  virtual sem variação interna", verde a sessão inteira, acusou 16 blocos
  desalinhados. Causa: o HUD novo dele passou a ser desenhado dentro da
  composição 16:9, que é a área que o filtro amostra. **Isso se resolveu
  sozinho** quando movi o filtro para cima da interface (ver §2).

Moral: enquanto houver duas mãos, uma suíte verde não prova nada sozinha. Rode
duas vezes.

---

## 2. O que eu entreguei nesta sessão

Tudo abaixo está commitado e verificado. Cada item tem probe e cada probe foi
testado **contra o próprio defeito** quando a asserção era nova.

### `ad6c1ad` Colisor do poste removido
Acabou o poste invisível no canto sudeste do pátio. **Resolve metade**: o poste
segue sendo oclusor de profundidade, então o recorte do personagem contra um
poste pintado fora de lugar permanece até a arte da vista 2 ser corrigida
(material pronto em `docs/calibration/exterior/pole_fix/`).

### `0553207` Salvamento no terminal da guarita
`SaveGame` estático, `user://save.cfg`. Ponto de interação medido, não chutado.
`ApproachPrompt` virou base comum de porta e terminal.

### `7ee7ed0` Apresentação montável, sobre a tela inteira
- O filtro subiu para uma `CanvasLayer` acima da interface e **copia o retângulo
  da composição 16:9 a cada quadro**. Pedido direto do usuário: "o filtro deve
  aplicar para UI tbm".
- Acabaram os presets fixos. Pixelização virou **nível** (desligado / leve /
  médio / PSX — todas as larguras dividem 1280 e 1920, que é o que mantém o
  pixel virtual inteiro) e **cada efeito virou interruptor independente**: cor
  reduzida, linhas de varredura, grade de abertura, tela de tubo, cantos
  escuros. Padrão caiu para **médio**, porque 320×180 destrói o texto do menu
  agora que o filtro o cobre.
- **Tubão não deixa mais moldura.** A imagem estufa e sofre overscan, dividindo
  pelo próprio esticamento dos cantos. Recorta nas bordas em vez de encolher
  dentro de uma borda preta.
- Dois defeitos achados medindo: as linhas de varredura eram **invisíveis** (a
  360 bandas, uma janela de 720 linhas dá um pixel por banda e a reamostragem
  vira cinza — limitado a 240, o degrau de brilho entre linhas vizinhas foi de
  0,0072 para 0,0777); e a métrica antiga do probe contava pixels alterados, que
  uma cena nevada já satura.

### `8840b00` Operação e objetivo da Fase 1 nos cenários autorados
- **Esc abre o menu de pausa** no exterior e na guarita. Antes fechava o jogo na
  hora, sem confirmação.
- F3, avisos passageiros e rede de queda (volta ao último ponto firme).
- `MissionState`: objetivo em quatro etapas (estrada → pátio → terminal →
  cumprido), avançando na cancela, na porta e no terminal. **Só anda para a
  frente.**
- `SaveGame` subiu para **FORMAT 2** e guarda a etapa. Arquivos do formato 1 são
  ignorados inteiros — quem já tinha salvo precisa salvar de novo.
- **Defeito corrigido:** o terminal gravava a etapa *anterior* à do próprio
  salvamento. A etapa virou argumento de `write()` em vez de leitura do global.
- **Defeito pré-existente corrigido:** `ControlScheme.set_mode` gravava em
  `user://settings.cfg` mesmo sob `--script`, então rodar a suíte trocava a
  preferência de controle de quem joga na máquina.

Fichas: `docs/LEVEL_OPERATION.md`, `docs/RETRO_PRESETS.md`, `docs/SAVE_SYSTEM.md`.

---

## 3. Estado de verificação — leia com cuidado

**Última suíte completa: 33 probes, 2 falhas** — e isso é anterior a boa parte do
que está commitado. As duas falhas eram da colisão (§1) e as duas causas já
foram resolvidas, mas **não rodei a suíte inteira depois disso**.

Verificado individualmente após o estado atual:

| Probe | Resultado |
| --- | --- |
| `filtro-retro` (gráfico) | 0 falhas |
| `operacao-cenarios` | 172 ticks, 0 falhas |
| `salvamento` | 136 ticks, 0 falhas |
| `dylan-portas` | 1164 ticks, 0 falhas |
| `exterior-geometria` | 4100 ticks, 55 colisores, 0 falhas |
| `sala-geometria` | 2415 ticks, 0 falhas |
| `unidades` | 0 falhas |

**Primeira coisa a fazer:** rodar a suíte completa duas vezes e comparar.

```
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/run_all.gd
```

Não rodei: `percurso`, `operacao`, `robustez-10min`, `benchmark-funcional`,
`composicao`, `oclusao`, `distancia-*`, `renderizacao`, os gráficos restantes, e
o `terminal-ui` do Codex.

---

## 4. Próxima tarefa: armas

Pedido literal do usuário:

> implemente armas no jogo. Para isso, precisamos definir uma coisa: o controle
> tank segue conforme resident evil e dinocrisis com autotarget e tudo mais. No
> modo moderno, ele segue a direção do mouse ao redor do player. Para isso, use
> assets do mixamo se precisar para o player andar em todas as direções e mirar
> em todas as direções

**Decisão já tomada pelo usuário** quando perguntei como a mira moderna deveria
se comportar: *"vira opção no menu de jogabilidade pro player escolher"*. Ou
seja: as três alternativas que apresentei — raio da câmera para o chão, mira
livre em 360° com retículo, e híbrido com assistência — **viram opções
selecionáveis**, não uma escolha de arquitetura. Projete o sistema de mira com
essa estratégia parametrizada desde o início.

O menu de jogabilidade ainda não existe; hoje há só a linha `CONTROLES:
CÂMERA/TANQUE` no menu de pausa. A página de opções que criei
(`PauseMenu._build_filter_page`) é um modelo pronto de como fazer outra.

Infraestrutura que você já tem:
- `ControlScheme` (câmera-relativa / tanque), estático e persistido.
- `PlayerController.facing()` e `turn_input`, já usados pelo modo tanque.
- `dylan_visual.gd` escolhe clipe por movimento e velocidade — é ali que entram
  os clipes de mira.
- `tools/build_dylan_animations.gd` monta `dylan_clips.res` a partir dos FBX do
  Mixamo. **Leia-o antes de capturar qualquer coisa nova**: ele documenta
  janelamento, plantio de quadril, cancelamento de guinada absoluta e costura em
  loop, e `docs/DYLAN_ANIMATION.md` registra as armadilhas (escala 100× no
  import, clipes de giro que vieram trocados entre si, cadência medida pelo pé
  plantado e não pela amplitude da passada).
- `tools/glb_to_obj.py` converte o modelo para upload no Mixamo sem Blender.

Para andar em oito direções e mirar em 360° vão faltar capturas: strafe
esquerda/direita, diagonais, e as poses de mira/tiro/recarga. O usuário já
autorizou dirigir o Chrome para baixar do Mixamo numa sessão anterior —
**confirme de novo antes de abrir o navegador**, a autorização era daquela vez.

`systems/combat/` está previsto em `PLAN.md` e ainda não existe.

---

## 5. Pendências abertas de antes

- **Cena principal e preset de exportação** continuam no percurso técnico T07.
  Trocar a entrada para o exterior muda o que o benchmark e o soak medem, e
  exige os templates de exportação, que **não estão instalados nesta cópia**
  (`%APPDATA%/Godot/export_templates/` está vazio). É o próximo item de
  prioridade 2 do `PROJECT_AUDIT.md`.
- **Arte do poste da vista 2** (`pole_fix/`). O usuário disse ter pedido a imagem
  ao Codex — confirme antes de mexer.
- **Gate de desempenho** (p95 ≤ 16,7 ms na RTX 5060) e abrir o `.exe` no Windows:
  dependem da máquina do usuário.
- **Alinhamento fino da arte da sala**: nunca medido.
- Resíduos cosméticos: primeiro quarto do ciclo de pivô é mais mole; captura de
  marcha à ré com quadril girado ~27°.

---

## 6. Como esta sessão trabalha (vale manter)

O usuário valoriza — e cobrou — três coisas:

1. **Medir em vez de olhar.** Toda asserção nova nasce verificada contra o
   próprio defeito: reintroduza o bug, veja o probe reprovar, restaure. Foi
   assim que peguei o pivô de 72,6°, a guarda de cena do salvamento e a borda do
   tubão.
2. **Relatar o que de fato aconteceu.** Suíte que morre em silêncio não é suíte
   verde. Probe que passa pelo motivo errado é falha — tive um: o teste de "E
   fora de alcance" estava no spawn da sala, que *é* o ponto da porta.
3. **Commits separados por assunto**, mensagem explicando o *porquê*, terminando
   com as linhas de atribuição.

Documentação é parte da entrega: `KNOWN_ISSUES.md`, `TEST_REPORT.md`,
`ARCHITECTURE.md` e `PROJECT_AUDIT.md` são mantidos a cada mudança, separando
estado atual de histórico.
