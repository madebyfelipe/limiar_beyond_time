# Operação básica nos cenários autorados

Data: 11/10/2026. Fecha a pendência de prioridade 2 do `PROJECT_AUDIT.md`:
"Exterior e sala têm R para reiniciar e Esc para sair. Não instanciam o menu de
pausa, F3, objetivos e recuperação presentes no percurso."

## O que mudou para quem joga

- **Esc abre o menu de pausa** no exterior e na guarita. Antes fechava o jogo na
  hora, sem confirmação — era a diferença mais grosseira entre esses cenários e o
  percurso técnico.
- **F3** mostra o mesmo diagnóstico do percurso: quadro, posição, velocidade,
  enquadramento ativo, candidato de corte e referência de movimento.
- **Queda tem rede**: sair da geometria devolve Dylan ao último ponto em que ele
  esteve de pé no chão, com aviso na tela.
- **Objetivo da Fase 1 na tela**, avançando pelo cenário e atravessando a porta.

## O objetivo

`systems/missions/mission_state.gd`. Estático, sem autoload, como `ControlScheme`
e `SaveGame`. Seis etapas, agrupadas em fases por `systems/missions/phase.gd`
(ver `PERIMETER.md`):

| Etapa | Fase | Texto | Avança quando |
| --- | --- | --- | --- |
| `ROAD` | 1 | Siga a estrada nevada até a cancela. | — |
| `YARD` | 1 | Atravesse o pátio e suba até a porta da guarita. | O jogador passa de `z = 9`, ao sul da cancela |
| `TERMINAL` | 1 | Registre o progresso no terminal da mesa. | Ele entra na guarita pela porta |
| `DONE` | 1 | Progresso salvo. Saia do pátio pelo portão norte. | Ele usa o terminal |
| `PERIMETER` | 2 | Siga a trilha do perímetro até o galpão do relé. | Ele atravessa o portão norte |
| `RELAY` | 2 | Galpão do relé alcançado. O conteúdo autoral termina aqui. | Ele passa de `z = −24` na trilha |

As etapas são gravadas no arquivo de salvamento: novas entram **no fim** do
enum e nenhuma muda de lugar, ou um registro antigo retomaria em outro objetivo.

**Só anda para a frente.** Voltar para o norte da cancela não desfaz a etapa:
quem já leu aquele objetivo o cumpriu, e a linha retroceder leria como perda de
progresso. Guardado por asserção.

**Vai para o registro.** `SaveGame` subiu para `FORMAT 2` e guarda a etapa junto
com a sala e a posição, então retomar devolve o objetivo, não só o lugar. Era
exatamente o caso previsto em `SAVE_SYSTEM.md` ("quando esses sistemas existirem,
`FORMAT` sobe e os campos entram junto").

**Reiniciar é tentativa nova, não apagar.** R e o botão Reiniciar voltam ator,
câmera e objetivo ao começo e **não** tocam no arquivo salvo.

## A camada de operação

`systems/operation/level_operation.gd`. Os cenários autorados montam seu runtime
em código, então instanciam essa camada em vez de repetir no `.tscn` o que o
percurso já tinha: menu de pausa, diagnóstico, avisos passageiros e a rede de
queda. A rede fica aqui, e não em cada cena, para não existirem duas versões de
"devolver o jogador".

O menu cobre a janela inteira, barras incluídas; diagnóstico e avisos ficam
dentro do quadro 16:9. Um `Control` com pai que não é `Control` se mede pela
janela — é o que dá esse arranjo sem duas hierarquias.

**Probes e foco.** Perder o foco da janela pausa o jogo. Probes rodam por
`--script` sem janela real, então a camada desliga essa reação ali; o probe que
testa pausa por foco a liga de volta explicitamente, como `check_operation.gd`
já fazia no percurso.

## O menu

Pedido do usuário: "gere o menu estilo dino crisis 2". O painel foi refeito no
idioma daquele jogo — campo escuro translúcido, moldura angular com cantos em
colchete, maiúsculas espaçadas, barra de seleção com marca grossa à esquerda e
linha de teclas no rodapé. É o **idioma visual**, não uma réplica: nada vem do
jogo original, nem imagem, nem fonte, nem texto.

A moldura é `ui/hud_frame.gd`, um `MarginContainer` que se desenha em `_draw()`
em vez de fatiar um bitmap. Duas consequências práticas: a linha fica com um
pixel de espessura em qualquer resolução, sem passagem de arte, e o painel se
mede pelo conteúdo — acrescentar um item do menu faz a moldura crescer em vez de
o texto vazar pela borda, que foi exatamente o defeito da primeira versão.

O espaçamento entre letras usa `FontVariation.spacing_glyph`, não espaços
escritos no texto, então os rótulos continuam sendo frases normais para traduzir
e para o código atualizar.

O contrato dos probes foi preservado: `resume_button`, `restart_button`,
`scheme_button` e `quit_button` continuam sendo `Button` com navegação por
teclado, e `open()` continua focando Continuar. `filter_button` é novo.

## Um defeito que o probe pegou

A primeira versão gravava o registro **antes** de o objetivo avançar, então o
arquivo guardava a etapa anterior: quem salvava e fechava o jogo voltava com
"registre o progresso no terminal", parado na frente do terminal que acabara de
usar. A etapa virou argumento de `SaveGame.write()` em vez de leitura implícita
do estado global, e o estado vivo só anda depois que o arquivo aceitou. Assim não
existe caminho em que um dos dois fica para trás.

## Verificação

`tests/check_level_operation.gd` (`operacao-cenarios`): **172 ticks, 0 falhas**.
Esc pausa em vez de sair nas duas cenas e congela o ator com tecla pressionada;
F3 liga/desliga e o texto nomeia o enquadramento ativo; perda de foco pausa; a
rede devolve o ator de 40 m abaixo do chão ao ponto firme, com aviso; o objetivo
começa na estrada, avança na cancela, **não** retrocede ao voltar, avança ao
entrar e ao salvar, vai para o registro e volta dele numa sessão nova; reiniciar
pelo R e pelo menu zera ator, câmera e objetivo sem apagar o registro.

## Limites

- A cena principal do projeto continua sendo o percurso técnico T07, e o preset
  de exportação continua selecionando os recursos dele. Trocar a entrada para o
  exterior é o próximo item do audit e muda o que o benchmark e o soak medem;
  não foi feito aqui.
- Os objetivos são da Fase 1 e estão no código, não em dados: não há sistema de
  missões, só a sequência acima.
- A rede de queda usa o último ponto firme, não marcas autoradas como o
  `RouteProgress` do percurso. No exterior e na guarita não há buraco conhecido —
  é rede de segurança, não recuperação de rota.
