# Health packs flutuantes

Data: 13/10/2026. Issue #3. Estojos de primeiros socorros que pairam e giram em
pontos do cenário e curam ao toque. Abra `executar-perimetro.cmd` para ver os
três da Fase 2.

## Comportamento

A issue deixava duas opções; foi escolhida a **cura imediata ao encostar**.

- Encostar num pack recupera **25 de vida** na hora (uma bicada) e o consome
  para sempre. O aviso na tela diz quanto ele deu: `Health pack · +25 vitality`.
- **Com a vida cheia o pack fica onde está.** Aparece `Vitality is already
  full.` uma vez por visita, e ele continua lá para quando fizer falta. Quem se
  fere parado em cima dele é curado sem precisar sair e voltar.
- Morto, em transição de porta ou sem controle, Dylan não recolhe nada.
- É diferente do kit médico, que é comprado, vai para a maleta, cura 50 e é
  usado com **H / R3**. O pack não ocupa espaço nem pode ser guardado.

## Onde estão

Declarados em `Perimeter.HEALTH_PACKS`, pelo ponto do chão sobre o qual cada um
paira:

| Id | Posição (x; z) | Câmera | Porquê |
| --- | --- | --- | --- |
| `trail_pen` | (2,0; −14,9) | `perimeter_2` | dentro da patrulha dos Keleken, entre o cocho e os sacos de ração: recompensa do lado arriscado |
| `trail_shed` | (−1,5; −24,5) | `perimeter_3` | depois do pinheiro caído, do lado para onde a passagem não leva, junto ao galpão |
| `rear_yard` | (−4,2; −35,4) | `perimeter_4` | canto oeste do pátio atrás do galpão, do outro lado da porta dos fundos |

São três, o número da proposta do mapa do Episódio 1 (três packs de 25). O do
pátio fica onde o pátio de serviço vai existir; muda de lugar quando esse
ambiente for construído.

## Peças

| Arquivo | Papel |
| --- | --- |
| `actors/pickups/health_pack.tscn` / `.gd` | `HealthPack`: estojo verde com cruz branca nas duas faces, halo e luz verde; paira a 0,95 m com ±7 cm a cada 2 s e gira a 1,8 rad/s. Recolhe por distância (0,7 m no plano), sem camadas de física |
| `systems/inventory/pickup_store.gd` | `PickupStore`: quais ids já foram recolhidos |
| `environments/perimeter.gd` | instancia os três e os repõe no Reiniciar |

O estojo é de formas grandes e planas e tem emissão própria, para continuar
legível sobre as placas escuras e através do filtro de baixa resolução. A luz
não projeta sombra.

Novo pack em outro cenário: uma entrada com id único num dicionário como
`HEALTH_PACKS`, um `HealthPack` com `pack_id`, `player` e `position`, e o id na
chamada de `PickupStore.rewind()` do `restart()` daquele cenário.

## Salvamento, portas e Reiniciar

O estado viaja dentro de `SupplyStock.snapshot()` (chave `pickups`), como os
baús, então portas, `save` e LOAD GAME o conservam sem mudar o formato do
arquivo. Um registro anterior aos packs volta com todos no lugar.

**Reiniciar é tentativa nova, não registro.** `PickupStore.rewind()` devolve os
packs recolhidos **desde o último `save`** e mantém recolhidos os que o registro
já guarda. Passar por uma porta não conta como registro. NEW GAME traz todos de
volta, qualquer que seja o arquivo.

O Reiniciar também devolve a vida cheia, como antes: o pack de volta só serve
depois do próximo dano.

## Verificação

`tests/check_health_packs.gd` (probe `health-packs`): **339 ticks, zero falhas**.

- `PickupStore`: lista dentro do snapshot de suprimentos, lista adulterada,
  valor que não é lista, registro antigo, jogo novo.
- Colocação: três packs, cada um num ponto onde o corpo de Dylan cabe sem tocar
  colisor, dentro do quadro da câmera que cobre o trecho (margem de 6 %) e sem
  nada entre a câmera e ele; paira em torno de 0,95 m e gira.
- Coleta: vida cheia não consome e avisa uma vez; ferido, cura 25, some e não
  cura de novo; chegando a pé com o controlador real e 90 de vida, cura só os 10
  que faltam; morto não recolhe.
- Registro: `save` grava; Reiniciar devolve só o que foi pego depois; a porta
  leva o estado mas não o registra; cenário reconstruído mostra o estado;
  primeira leitura do arquivo; jogo novo.

Três asserções testadas contra o próprio defeito: Reiniciar que esquece o
registro (4 falhas), pack consumido com vida cheia (7 falhas) e pack dentro do
cocho (1 falha).

Inspeção visual: os três packs capturados nas câmeras 2, 3 e 4 com a arte
ligada. Regressões na mesma execução, zero falhas: `perimetro`,
`combate-inimigo`, `keleken-wander`, `salvamento`, `inventario`, `dylan-portas`,
`rele`, `terminal-ui`, `mapa`, `operacao-cenarios`, `cenas`, `esquiva`,
`combate`, `gamepad`, `menu-inicial`. Suíte completa e probes gráficos não
rodados.

## Limites

- **Sem som de coleta**: depende da issue #1.
- Só a trilha tem packs. Exterior, guarita e sala do relé não têm.
- O teste de oclusão usa os colisores do cenário. Um elemento só pintado na
  placa, sem colisor, não entra nele; nas três capturas não há nenhum na frente.
- Os packs não aparecem na aba MAP.
- Quantidade, posição e os 25 de cura são valores de partida para ajustar
  jogando.
