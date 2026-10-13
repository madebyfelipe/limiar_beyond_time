# Fase 3 — sala do relé

Implementada em 12/10/2026. Entrada pela porta do galpão do relé, no fim da trilha
do perímetro; `executar-rele.cmd` abre a sala direto.

## Fluxo

1. Na trilha, ao passar de z −24 a etapa vira `RELAY` e a porta do galpão abre
   (prompt ao pé do degrau, em `RELAY_APPROACH`; o degrau de 0,2 m não é subível pela cápsula).
2. A cinemática de porta mostra **RELAY ROOM**. Dentro, a etapa vira
   `RELAY_ROOM`: "Check the relay terminal for the operator's last log."
3. **E** no terminal (parede leste) abre o console, que só reproduz:
   BIOS, boot do Arch Linux com linhas `[  OK  ]` e uma `[FAILED]` do uplink,
   login `operator`, `journalctl -u relay-log` e as cinco entradas do operador.
   E/Enter/disparo terminam o bloco em curso; nada é pulado sem aparecer.
4. Depois do log o UPS acaba e as barras pretas (`CinematicBars`, 12 % em cima e
   embaixo, dentro da composição 16:9 e portanto sob o filtro) descem; o HUD sai de cena: o console colapsa como tubo, a etapa vira `OUTAGE`,
   a luz pisca e apaga, a tela e os LEDs morrem e a lâmpada vermelha de emergência
   pulsa.
5. Corte por cima do ombro para a janela: um Keleken passa lá fora sob a lâmpada do
   pátio, para, olha para dentro e segue. Aviso: "Something is circling the shed."
6. De volta à câmera da sala, as barras sobem, o HUD volta e o controle é do jogador,
   com o objetivo "Leave by the rear door". A porta dos fundos destrava; **E** nela
   leva para fora e a cinemática mostra **BEHIND THE RELAY SHED**.
7. Na trilha, atrás do galpão: etapa `REAR_YARD`, fim do conteúdo autorado por ora.
   A porta dos fundos leva de volta à sala, que continua sem energia.

O texto do log é **provisório** e mantém indefinida a causa do desaparecimento,
como pede o plano: equipe AURORA atrasada, câmera do cercado disparada, evacuação,
uplink caído, "do not open the rear door after dark".

## Geometria

`tools/build_relay_room_source.gd` gera `environments/relay_room_source.tscn`
(48 nós, 20 colisores). Rodar de novo substitui o arquivo: editar o gerador, não a cena.

Sala de equipamentos de 6 × 4,4 m, pé-direito 2,8 m, dentro dos 6,6 × 5 m do galpão.
Diferente da guarita (uma caixa vista de um canto): racks na parede norte,
banco de baterias a oeste e transformador baixo diante dos racks formam um L;
terminal na parede leste; janela alta ao norte; duas portas (frente ao sul e fundos ao norte).
Uma câmera fixa no canto sudoeste. Sem placa pintada: a sala é iluminada pelas próprias
luzes (teto, brilho da tela, emergência), para que o corte de energia apareça.

Primeira versão tinha uma coluna de conduítes no centro; as capturas mostraram que ela
escondia a porta dos fundos e o caminho até ela, e foi trocada pelo transformador.

## Atrás do galpão (provisório)

`perimeter.gd` ganhou o enquadramento `perimeter_4` (só geometria, sem placa),
a porta dos fundos na parede traseira do galpão e limites invisíveis do pátio
(laterais, fundo, os dois vãos ao lado do galpão e troncos dos três pinheiros).
A versão final sai para uma área externa nova; este pátio é só a saída provisória.
Reiniciar no pátio mantém o pátio e a etapa.

## Cadeia e salvamento

Fase 3 `relay` em `Phase.chain()`: abre em `RELAY`, começa em `RELAY_ROOM`, fecha em
`OUTAGE`. As três etapas novas foram acrescentadas ao fim do enum, então registros
antigos continuam válidos. Não há terminal de salvamento na trilha nem no relé.

## Animações

A sala pede por nome `terminal_type` (ao teclado) e `startled` (o susto, quando o
animal para e olha pela janela) por `DylanVisual.play_scripted()`, que cai para
`idle` enquanto o clipe não existe. `startled` já está declarado em
`tools/build_dylan_animations.gd` como opcional: basta exportar do Mixamo "Startled"
(In Place, FBX Binary, 30 fps, sem skin, no rig `dylan_mixamo`) para
`assets/models/dylan_protagonist/mixamo/startled.fbx` e reconstruir a biblioteca.

## Verificação

`tests/check_relay_room.gd` (`rele` e `rele-grafico` no executor): porta do galpão,
colisores nomeados, paredes, banco de baterias e porta dos fundos trancada antes da
queda; textos do console; etapa só muda depois do log; luzes apagadas e emergência
acesa; a cabeça do animal projetada dentro do vão da janela pela câmera da cutscene;
saída automática, chegada atrás do galpão no enquadramento 4; limites do pátio nos
quatro lados; volta pela porta dos fundos para a sala escura; reinício.
Capturas gráficas em `.local/relay-*.png`, inspecionadas.

Limites: sem áudio (nem queda de energia nem o animal), sem placa pintada da sala e do
pátio, cutscene sem clipes próprios do Dylan, log em inglês e provisório.
