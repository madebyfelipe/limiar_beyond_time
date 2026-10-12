# Salvamento persistente — terminal da guarita

Data: 11/10/2026. Pedido do usuário: "persistencia de salvamento". Fecha a pendência
anotada em `PROJECT_AUDIT.md` (item 2) e nas fichas da sala.

## O que existe

- `systems/save/save_game.gd` (`SaveGame`): leitor/escritor estático, sem autoload,
  no mesmo padrão de `ControlScheme`. Arquivo em `user://save.cfg`.
- `systems/interaction/terminal_interaction.gd` (`TerminalInteraction`): a ação **E**
  junto à mesa grava o registro e confirma na tela.
- `systems/interaction/approach_prompt.gd` (`ApproachPrompt`): base comum da porta e
  do terminal. Existe uma única definição de "estar perto" — distância horizontal
  dentro do raio e diferença de altura < 0,25 m — e o aviso na tela aparece
  exatamente enquanto a tecla faria algo.
- `environments/save_room.gd`: instala o terminal e, ao abrir, retoma do registro.

## O registro

| Campo | Conteúdo |
| --- | --- |
| `format` | 1. Um arquivo de outro formato é **ignorado inteiro**, não lido pela metade. |
| `scene` | A sala onde se salvou. Um registro de outra cena não reposiciona esta. |
| `position` | Onde o jogador estava, em metros. |
| `facing` | Guinada do corpo, em radianos. |
| `saves` | Contador, mostrado como "REGISTRO n" na confirmação e na lista de teclas. |
| `saved_at` | Horário Unix da gravação, exibido em hora local. |

O registro é deliberadamente pequeno: **onde** o jogador estava e **em que sala**.
Nada mais no jogo tem estado hoje — não há inventário, portas trancadas, itens
coletados nem progresso de roteiro — e gravar campos que o jogo não sabe restaurar
seria um salvamento que mente. Quando esses sistemas existirem, `FORMAT` sobe e os
campos entram junto.

## Ponto de interação

`(−0,05; 0; −1,25)`, raio de 0,8 m, de frente para o monitor. **Não** foi escolhido
a olho: é o ponto livre mais próximo do teclado para a cápsula de 1,8 m / raio 0,3 m,
medido contra os colisores da própria sala (varredura de 5 cm em toda a planta). A
cadeira, que é sólida, impede chegar mais perto que 0,64 m do teclado; por isso
Dylan fica à esquerda do monitor, e não centrado nele.

## Como se comporta

- **Salvar**: andar até a mesa, **E**. A confirmação aparece sobre o aviso da tecla e
  some sozinha. Se o arquivo não puder ser escrito, a mensagem diz isso em vez de
  fingir que o progresso está seguro.
- **Retomar**: abrir `executar-sala.cmd` com um registro gravado começa na posição e
  orientação salvas, e a lista de teclas mostra "· retomado". Sem registro, a sala
  usa o spawn da porta e avisa "SEM REGISTRO".
- **Entrar pela porta** não retoma: quem chega do exterior fica na porta.
- **R** volta ao spawn e deixa de contar como sessão retomada; não apaga o registro.

## Limites conhecidos

- Só a sala de salvamento grava. O exterior não tem ponto de salvamento, de propósito
  (convenção do gênero). A guarda por cena já está no lugar para quando houver outro.
- Um único registro, sem slots, sem tela de título e sem menu de carregar: o projeto
  ainda abre cada cena por um `.cmd` próprio, e a retomada acontece ao abrir a sala.
- Não há tempo de jogo acumulado no registro. Faltaria um relógio que sobreviva à
  troca de cena, e nenhuma tela mostra esse número hoje.
- O arquivo é texto simples em `user://`, sem assinatura: é editável à mão. Para um
  protótipo isso é conveniente, não seguro.

## Verificação

`tests/check_save_persistence.gd` (`salvamento` no executor T09): **124 ticks, 0
falhas**. Cobre o alcance do terminal (silencioso na porta e no meio da sala, E fora
de alcance não grava), repetição de tecla não duplica a gravação, ida e volta de
posição/orientação/contador/horário, confirmação na tela, retomada em sessão nova,
chegada pela porta ignorando o registro, e três registros que **não** devem ser
obedecidos: de outra sala, de formato desconhecido e apontando para uma cena
inexistente. Usa `user://save_probe.cfg` — nenhum probe lê ou sobrescreve o
salvamento de quem joga na máquina.

As asserções foram provadas contra o próprio defeito, não só pela aprovação:

| Defeito reintroduzido | Reprovação |
| --- | --- |
| `resume()` nunca restaura | 4 falhas, incluindo "Resumed at (−2,4; …; 0,55) instead of the stored (−0,05; …; −1,25)" |
| sem guarda de cena | 2 falhas; o registro do exterior derrubava o jogador para `y = −2,04` dentro da sala |
| sem guarda de formato | 1 falha, "A record in an unknown format was read anyway" |
