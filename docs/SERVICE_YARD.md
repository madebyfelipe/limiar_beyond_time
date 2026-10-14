# Ambiente 5 — pátio de serviço

Geometria básica criada em 14/10/2026: **só obstáculos e trajeto**. Sem placa,
sem cutscene (o roteiro vem do usuário), sem portas novas funcionando. É o hub
que a planta do Episódio 1 (`MAP.md`) pendura atrás do galpão do relé, e
substitui o pátio provisório `perimeter_4` da trilha.

Pedido do usuário: "crie a geometria BÁSICA (somente obstáculos e trajeto) do
próximo espaço. Deve aparecer mais dinossauros nessa parte então seja
estratégico sobre a área. Vai ter uma cutscene scriptada (vou passar depois),
mas adicione uma região espaçada o suficiente estilo dino crisis 2 p combate
e/ou fuga".

Abra `executar-patio-servico.cmd` para entrar direto, ou
`executar-patio-servico.cmd --dinos` para povoar o pátio e testar o espaço
contra os animais. Na continuidade: sala do relé → apagão → porta dos fundos.

## Arquivos

| Arquivo | Papel |
| --- | --- |
| `tools/author_service_yard.gd` | Gera a fonte, as quatro câmeras e, com renderizador, as capturas. Editar o gerador, não a cena. |
| `environments/service_yard_source.tscn` | Fonte espacial gerada (malhas; as sólidas carregam `collision_size`). |
| `environments/service_yard.tscn` / `.gd` | Cena jogável: colisores, enquadramentos, zonas, porta de volta ao relé, kit de cura, animais opcionais. |
| `resources/service_yard/shot_{1..4}.tres` | `service_yard_mid`, `_west`, `_east`, `_arm`. |
| `assets/backgrounds/service_yard/` | `geometry_cam0{1..4}.png`, `plan_top.png` (planta vista de cima) e `cameras.json`. |
| `tests/check_service_yard.gd` | Probe `patio-servico`. |

## Medidas

Coordenadas da trilha: norte é −z, a parede de trás do galpão está em
z = −31,9 e a porta dos fundos em x = 2,4. O pátio é a planta do `AreaMap` a
4/3 dos seus metros esquemáticos, então as portas caem nas marcas do mapa.

- **Pátio**: x −12 … 12, z −50,5 … −32 (24 × 18,5 m).
- **Braço noroeste**: x −12 … −5,5, z −61 … −50,5 (6,5 × 10,5 m), ao longo da
  parede oeste da casa do gerador.
- **Chão caminhável medido**: 396 m², quase quatro vezes a largura da trilha
  (6,4 m).

Os números de projeto vêm do próprio jogo: Dylan corre a 3,8 m/s e o Keleken
persegue a 3,4 m/s; o animal percebe a 8 m, num cone de 120°, e olha de 1,6 m
de altura para o peito do ator (1,2 m). O Cryopteryx tem 3,2 a 4,4 m.

### O trajeto

Faixa de neve batida (só visual), da porta dos fundos do relé até cada porta:

| Porta (id do mapa) | Onde | Aproximação |
| --- | --- | --- |
| `relay_rear` | parede de trás do galpão, sul | (2,4; −32,9) — **a única que funciona** |
| `kennel_north` | bloco do canil, sul, a oeste do galpão | (−9,3; −32,9) |
| `quarters_door` | alojamento, leste | (11,1; −41,9) |
| `generator_front` | casa do gerador, norte | (1,3; −49,6) |
| `generator_side` | casa do gerador, dentro do braço | (−6,4; −55,75) |

### A área de combate e fuga

- **Clareira** de 11,9 × 11,9 m (`CLEARING`, x −2,7 … 9,2, z −50,2 … −38,3),
  vazia de qualquer colisor: é onde a cutscene pode acontecer e onde se luta ou
  se corre depois. A porta do alojamento, a segunda sala segura, fica na borda
  leste dela, então fugir tem destino.
- **Nenhum beco.** Toda peça de cobertura no aberto é ilha, com corredor de pelo
  menos 2,3 m em volta. Um corpo de 2,3 m de largura alcança todo lugar onde o
  ator fica, a no máximo 1,4 m. Isso vale para o Cryopteryx e significa que não
  há canto onde Dylan fique preso sem saída.
- **Cobertura alta quebra a linha de visão**: o caminhão (cabine 2,6 m a oeste,
  carga 2,0 m) e o tanque de combustível (2,0 m). Ficam deitados leste-oeste, de
  topo para as câmeras, para esconderem só uma faixa da própria largura.
- **Cobertura baixa não quebra**: caixotes, paletes, tambores e duas barreiras
  (até 1 m). Param o corpo, não o olho.
- A barreira junto ao alojamento é uma mureta encostada na fachada, ao norte da
  porta. Protege a porta de quem vem da brecha nordeste e não tem nada atrás.

### Os dinossauros

O pátio é autorado **vazio**. A estratégia está nos dados de `service_yard.gd`:

- **Três brechas** na cerca (`BREACHES`): oeste, nordeste e fundo do braço. São
  três lados diferentes da clareira, todos a mais de 12 m da porta dos fundos.
  O painel caído é desenho; o limite invisível atrás dele continua fechado, e
  quem abre é a cena que fizer os animais entrarem.
- **Três territórios** (`PACKS`), com cinco animais ao todo (a trilha tem dois):
  nordeste (2), oeste atrás do caminhão (2) e braço (1). Todo território fica
  a mais de 8 m da porta, então nada está em cima de Dylan quando ele sai.
- `--dinos`, ou `populate = true` antes de a cena entrar na árvore, põe um
  Keleken em cada casa, patrulhando o próprio território.

### Câmeras

Quatro enquadramentos, **todos olhando para leste**: "para cima" no direcional é
leste em todos, então o comando não troca de sentido nos cortes. Cada câmera
fica a oeste da própria faixa, de frente para os prédios do fundo. As poses
foram escolhidas por varredura: pés e cabeça dentro do quadro com margem em todo
o chão da faixa, maximizando a menor altura do ator.

| Enquadramento | Posição | Alvo | FOV | Ator |
| --- | --- | --- | --- | --- |
| `service_yard_mid` | (−21,25; 10,5; −41,25) | (−5,75; 0,9; −41,25) | 32° | 121 … 160 px |
| `service_yard_west` | (−27,8; 9,5; −41,725) | (−12,8; 0,9; −41,725) | 35° | 117 … 153 px |
| `service_yard_east` | (−13,25; 10,5; −41,25) | (2,25; 0,9; −41,25) | 32° | 124 … 160 px |
| `service_yard_arm` | (−19,8; 11; −55,275) | (−9,8; 0,9; −55,275) | 30° | 177 … 196 px |

As zonas se sobrepõem em 1,5 m e têm **a mesma prioridade**, então o diretor
mantém o enquadramento atual enquanto o ator estiver na faixa dele. Assim um
combate na borda não fica cortando de um lado para o outro.

A cerca é desenhada por postes e trilhos finos, com o limite sólido escondido.
Uma cerca maciça ficaria entre as câmeras do oeste e o chão.

### Kit de cura

`rear_yard` veio do pátio provisório **com o mesmo id**, então um registro que já
o pegou continua com ele pego. Fica no braço, em (−10,6; −56,5), passando os
paletes, no território de um animal: o kit vale o risco.

## Ligação com o resto

- A porta dos fundos do relé leva aqui (cinemática **SERVICE YARD**); a porta do
  pátio volta à sala escura. Chegar dá a etapa `REAR_YARD`, agora "Service yard
  reached. The authored content ends here for now."
- O pátio **não é uma fase** em `Phase.chain()`: nada o fecha ainda. A etapa
  continua pertencendo à Fase 3, como antes.
- `AreaMap`: o ambiente `service_yard` aponta para esta cena, com as duas partes
  (pátio e braço) projetadas sobre os retângulos da planta. A prévia é
  `geometry_cam01.png` até haver placa.
- A trilha perdeu o pátio provisório: o quarto enquadramento, a porta dos fundos
  do lado de fora, os limites invisíveis e o kit. Reiniciar a trilha depois do
  apagão põe Dylan diante da porta da frente do galpão.
- Preset de exportação: cena, script, fonte, enquadramentos e a prévia.

## Verificação

`tests/check_service_yard.gd` (`patio-servico`): **2701 ticks, zero falhas**.
Mede, em vez de olhar:

- O chão é amostrado a cada 25 cm por inundação a partir da porta, com o raio
  do ator e com um corpo de 2,3 m.
- Nenhuma célula fora da cerca, todas as portas e brechas alcançáveis, nenhum
  beco e cada peça de cobertura com corredor nos quatro lados.
- Clareira sem colisor.
- Linhas de visão por raio: as coberturas altas cortam, as baixas não.
- Brechas, casas e territórios além do alcance de percepção a partir da porta.
- Nas quatro câmeras, em todo o chão: ator dentro do quadro e entre 100 e
  200 px; cobertura escondendo até a cintura em ≤ 5 % e o ator inteiro em ≤ 1 %
  das células. Medido: 3,6 % / 0,4 % no meio, 5,0 % / 0,6 % no leste, zero nos
  outros dois.
- Uma volta com Input real por todas as portas, conferindo o quadro a cada tick
  e os seis cortes esperados.
- Reinício, porta de volta e povoamento com cinco animais em patrulha.

Testado contra o próprio defeito:
- Sem o limite sudeste da cerca, o probe acusou 1192 células fora do pátio.
- O primeiro traçado foi reprovado por três motivos: corredores de 2,05 a 2,35 m
  junto às barreiras e paletes; o contêiner de 2,6 m escondendo o ator inteiro
  em 2,8 % da faixa leste; e câmeras com ator de 98 px, às vezes fora do quadro.

Probes ajustados e verdes: `rele` (sai para o pátio e volta), `perimetro` (três
enquadramentos), `health-packs` (dois kits na trilha), `mapa` (o pátio e o braço
na planta, as portas do pátio sobre as marcas), `cenas`, `operacao-cenarios`,
`salvamento`, `dylan-portas`, `combate-inimigo`, `keleken-wander`,
`exterior-geometria`.

**Suíte completa** (`run_all.gd`, headless e gráficos, RTX 4050 Laptop):
**58 probes, zero falhas**, incluindo `rele-grafico`, `perimetro-grafico`,
`robustez-10min` e `benchmark-funcional`.

## Limites

- **Só geometria.** Sem placa, sem áudio, sem a cutscene. Os enquadramentos são
  de trabalho: a vista do meio olha o caminhão de topo bem no centro do quadro,
  o que é medido como aceitável para oclusão mas não é composição final.
  Reposicionar câmeras ao pintar as placas é esperado.
- As quatro portas novas são só desenho; nenhuma tem prompt. As brechas estão
  fechadas pelo limite invisível.
- Os animais de `--dinos` são Keleken: o Cryopteryx ainda não tem ator, só
  visual. O território do braço tem um único animal; o pátio inteiro tem cinco.
- A porta dos fundos na planta (`relay_rear`, x = 2,4) fica 0,6 m a leste de
  onde a escala 4/3 põe a porta do pátio (x = 1,8); a seta de Dylan não coincide
  exatamente com a marca ao sair.
