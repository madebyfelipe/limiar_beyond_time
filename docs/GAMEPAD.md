# Gamepad e PS4 / DualShock 4

Implementado em 12/10/2026. O InputMap usa os eixos e botões padronizados do
Godot/SDL, com eventos para qualquer dispositivo (`device = -1`). Teclado e
mouse continuam disponíveis. Basta usar o controle reconhecido pelo sistema;
ele também pode ser conectado depois de abrir o jogo.

O mapeamento abaixo é o padrão. **Options → Configurações → Controle / Gamepad**
permite remapear botões, gatilhos e direções dos analógicos, ajustar zona morta e
inverter a mira Y. As setas das opções são clicáveis e aceitam esquerda/direita.
Detalhes em [SETTINGS.md](SETTINGS.md).

| Ação | PS4 / DualShock 4 | Gamepad com rótulos Xbox |
| --- | --- | --- |
| Mover | Analógico esquerdo ou direcional | Analógico esquerdo ou direcional |
| Correr (segurar) | L3 ou ○ | LS ou B |
| Interagir com porta/terminal | ✕ | A |
| Erguer arma (segurar) | L2 | LT |
| Mirar | Analógico direito | Analógico direito |
| Disparar (segurar) | R2 | RT |
| Recarregar | □ | X |
| Esquivar | △ | Y |
| Usar kit médico | R3 | RS |
| Alvo anterior / próximo | L1 / R1 | LB / RB |
| Pausar / retomar | Options | Menu / Start |
| Diagnóstico | Clique no touchpad | F3 no teclado; remapeável |
| Abrir a maleta | Share | Back / View |
| Navegar no menu | Analógico esquerdo ou direcional | Analógico esquerdo ou direcional |
| Confirmar / voltar no menu | ✕ / ○ | A / B |

## Movimento e combate

- Analógicos têm zona morta de 25%; gatilhos, 20%; navegação dos menus, 50%.
  A inclinação do analógico controla a velocidade de movimento. Segurar uma
  direção conserva a referência de movimento durante cortes; soltar e mover
  de novo usa a câmera atual. Teclas opostas mantêm o contrato anterior.
- **Câmera:** analógico direito indica uma direção na tela, projetada sobre o
  chão ao redor de Dylan. Neutro conserva o rumo mundial. Os modos livre e
  cursor usam essa direção; assistida acrescenta atração por alvos visíveis.
- **Alvo travado:** L2 seleciona o alvo visível mais próximo, sem cursor de
  mouse. L1/R1 percorrem os alvos em ordem horizontal na tela. Soltar L2 libera
  a trava; obstrução e cortes preservam a seleção como na versão com mouse.
- **Tanque:** esquerda/direita giram, cima/baixo avançam/recuam. Com a arma
  erguida, o analógico direito gira e inclina a arma; o esquerdo/direcional
  também pode fazer isso. Entrada manual solta a trava. Mira automática e
  troca de alvos continuam respeitando a opção da pausa.
- R2 mantido dispara conforme o intervalo da arma, sem necessidade de apertar
  repetidamente. Pausa e portas interrompem a mira e exigem soltar os gatilhos
  antes de voltar a mirar/disparar. Desconectar o controle ativo abre a pausa;
  reconectar não retoma o jogo sozinho.

## Terminal sem teclado

✕ junto à mesa abre o terminal. ←/→ selecionam `help`, `save`, `shop`,
`buy ammo`, `buy shells`, `buy medkit`, `buy weapon`, `buy shotgun`, `inventory`, `status`, `clear` e `exit`.
✕ executa o comando exibido. ↑/↓ percorrem o histórico; L1/R1 rolam o texto;
○ ou Options saem. Os atalhos usam o mesmo processamento dos comandos digitados,
incluindo preços, estoque, verificações e salvamento.

Os avisos de interação e as legendas da pausa/terminal acompanham o último
dispositivo usado. Os nomes PS4, DualShock, DualSense, Sony, PlayStation e
Wireless Controller recebem os símbolos PlayStation. Um controle emulado que
se apresenta como Xbox recebe os rótulos Xbox, com o mesmo mapeamento físico.

## Validação

`tests/check_gamepad.gd` envia eventos reais `InputEventJoypadMotion/Button`
ao InputMap e exercita o controlador, arma, pausa e terminal da sala.
Verifica zona morta, velocidade proporcional, corrida, tanque, cortes de
câmera, quatro modos de mira, gatilhos, recarga, troca de alvos, interrupção na
pausa, navegação, desconexão, interação e comandos sem teclado. O salvamento
é interceptado no teste para preservar o registro da pessoa jogando.

Os eventos simulados e seus bindings ficam restritos ao dispositivo 15 naquele
processo, para evitar interferência de um controle físico durante a prova.
Isso não altera o InputMap gravado no projeto.

```powershell
$GodotExe = Join-Path $PWD '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd -- --only=gamepad
& $GodotExe --path $PWD --disable-vsync --fixed-fps 60 --script res://tests/check_gamepad.gd
```

As 11 regressões selecionadas (movimento, referência de câmera, operação, portas,
tanque, gamepad headless e gráfico, terminal, operação dos cenários, combate e
cena principal) passaram sem erros. As capturas da pausa e do terminal foram
inspecionadas em `.local/gamepad-ps4-*.png`. O processo gráfico reconheceu um
controle físico como **PS4 Controller**. Os botões foram exercitados por eventos
simulados; uso manual completo e conexão Bluetooth/USB separadamente continuam
como aceite em hardware, não comprovado pelo teste automático.

Referência do mapeamento: [constantes JoyButton/JoyAxis do Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_@globalscope.html#enum-globalscope-joybutton).
