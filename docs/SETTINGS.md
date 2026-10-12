# Configurações

Implementado em 12/10/2026. Abra **Esc / Options → Configurações** na pausa.
O menu reúne **Geral / Vídeo e Áudio**, **Jogabilidade**, **Teclado e Mouse**,
**Controle / Gamepad** e **Apresentação**. Jogabilidade e apresentação também
continuam acessíveis diretamente na pausa.

## Setas e navegação

Cada opção ajustável tem dois botões reais: **‹** diminui/volta, **›** aumenta/
avança. Clique nas setas ou pressione **←/→** com a linha selecionada. No
gamepad, use esquerda/direita no direcional ou analógico esquerdo. Enter/✕/A
também avança um passo. Os seletores de listas dão a volta nos dois sentidos;
percentuais e sensibilidade param nos limites.

↑/↓ ou o direcional navegam. Esc/○/B voltam uma página, mantendo o jogo pausado;
Esc/Options na pausa principal retoma. Ao abrir jogabilidade ou apresentação
pela categoria Configurações, voltar retorna à categoria de origem.

## Geral / Vídeo e Áudio

| Opção | Valores | Padrão |
| --- | --- | --- |
| Modo de tela | Janela, tela cheia, exclusiva | Janela |
| Resolução da janela | 960×540, 1280×720, 1600×900, 1920×1080, 2560×1440 | 1280×720 |
| VSync | Ligado / desligado | Ligado |
| Limitador de FPS | Sem limite, 30, 60, 90, 120, 144, 165, 240 | Sem limite |
| Volume geral | 0–100%, passos de 10% | 100% |

As alterações são aplicadas imediatamente e salvas automaticamente. VSync
pode limitar os FPS à taxa do monitor mesmo com o limitador em “Sem limite”.
Tela cheia e exclusiva usam a resolução atual do monitor; o seletor de
resolução da janela fica desabilitado nesses modos. A janela volta com bordas,
centrada e limitada à área disponível do monitor. O seletor controla a janela;
o framebuffer 3D e os filtros continuam obedecendo à apresentação do projeto.

“Restaurar padrões” afeta apenas as opções dessa página. A configuração do
volume atua no bus Master, com mute ao chegar em zero.

## Teclado e mouse / controle

As duas páginas exibem **ação**, **entrada principal** e **alternativa**.
Clique ou confirme em uma entrada e pressione o novo botão.

- Teclado/mouse: teclas físicas, combinações como Ctrl+K, botões do mouse e
  roda. Modificadores sozinhos são capturados ao soltar, para também permitir
  combinações sem gravar apenas a primeira tecla.
- Gamepad: botões, gatilhos e direções dos analógicos. Um eixo precisa chegar
  a 65% para ser capturado, evitando registrar o analógico em repouso.
- Se outra ação já usa a entrada, a tela pede confirmação para trocar as
  entradas. Ao preencher um slot vazio, explica que a ação anterior perderá
  aquela entrada. A confirmação usa Enter/✕/A ou o botão “Trocar”.
- Esc ou “Cancelar” cancela a captura; Options/Menu também cancela, exceto ao
  remapear a própria pausa. Após dez segundos sem concluir, a captura cancela.
- **Delete**, clique direito na entrada ou **□/X** no gamepad limpam a entrada
  selecionada. Durante a captura, Backspace também limpa. Ao remover a
  principal, uma alternativa existente passa a ser a principal.
- Restaurar padrões repõe apenas as binds e ajustes daquela família. Alterar
  teclado/mouse preserva gamepad, e vice-versa.

Os menus mantêm sua navegação padrão. Esc e Options continuam abrindo a pausa
mesmo ao remapear a ação de pausa, para preservar um caminho até Configurações.
Essas entradas reservadas não são transferidas para outra ação em conflitos;
o aviso explica que a entrada escolhida será retirada da ação anterior.
A captura consome os eventos antes da interface/jogo; registrar um novo botão
não retoma a simulação ou dispara a arma. As dicas de interação e de combate
usam os bindings atuais. Controles Sony detectados usam os rótulos PlayStation,
inclusive na tela de controles quando a navegação atual é feita pelo mouse.

| Ajuste | Valores | Padrão |
| --- | --- | --- |
| Sensibilidade do mouse (mira livre) | 0,2×–3,0×, passos de 0,1× | 1,0× |
| Inverter mouse Y (mira livre) | Ligado / desligado | Desligado |
| Zona morta dos analógicos | 10–40%, passos de 5% | 25% |
| Zona morta dos gatilhos | 5–50%, passos de 5% | 20% |
| Inverter mira Y do gamepad | Ligado / desligado | Desligado |

Sensibilidade e inversão do mouse afetam a mira livre 360°. O modo de cursor
continua seguindo a posição absoluta do mouse. A zona morta dos analógicos
afeta movimento e mira; a inversão do gamepad afeta a mira, incluindo a
inclinação no tanque. Ajustes da interface têm sua própria zona morta de 50%.

## Persistência e implementação

`user://settings.cfg` continua sendo compartilhado com `ControlScheme`,
`AimSettings` e `RetroFilter`, sem apagar suas seções ou o save do jogo.
`GeneralSettings` guarda a seção `[general]`; `InputBindings` guarda
`[bindings_keyboard]` e `[bindings_gamepad]` como dicionários de eventos.
Os padrões são capturados do InputMap original. Valores inválidos de arquivo
são ignorados ou limitados às faixas válidas.

- `ui/retro_option.gd`: seletores com setas nativas e entrada bidirecional.
- `ui/settings_menu.gd`: categorias, vídeo/áudio, tabelas e captura de bindings.
- `ui/pause_menu.gd`: entrada e retorno das páginas durante a pausa.
- `systems/settings/general_settings.gd`: aplicação e persistência das opções.
- `systems/input/input_bindings.gd`: eventos, conflitos, restauração e rótulos.
- `systems/input/gamepad_input.gd`: inicialização das preferências, detecção do
  dispositivo e dicas conforme o mapeamento.

## Validação

Os probes `configuracoes` e `configuracoes-grafico` exercitam os eventos reais
da interface e usam um arquivo temporário próprio. Verificam cliques nas
setas, os dois sentidos no teclado/direcional/analógico, retorno de submenus,
fullscreen e exclusiva, bordas e tamanho de janela, VSync, limitador, volume,
remapeamento de teclas/mouse/modificadores/botões/gatilhos/eixos, conflitos,
alternativas, limpeza, cancelamento e timeout, persistência, arquivo inválido,
disparo com a bind nova, recuperação por Esc e padrões por família.

Foram aprovadas **14 regressões**: configurações headless e gráfica, gamepad
headless e gráfico, terminal headless e gráfico, pausa, operação dos cenários,
combate, tanque, locomoção, referência de câmera, filtro retro e cena principal.
Capturas inspecionadas: `.local/settings-hub.png`, `settings-video.png`,
`settings-keyboard.png`, `settings-ps4.png`, `settings-binding-conflict.png` e
`settings-ps4-4x3.png`.

```powershell
$GodotExe = Join-Path $PWD '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd -- --only=configuracoes,configuracoes-grafico
```
