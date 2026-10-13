# Ground Zero: controles e aplicação no LIMIAR

Levantamento de 12/10/2026 sobre **Ground Zero, da Malformation Games**.

## Funcionamento confirmado

A [página oficial](https://store.steampowered.com/app/2340130/Ground_Zero/) confirma câmeras fixas e controles tanque opcionais. O [guia oficial de combate](https://steamcommunity.com/games/2340130/announcements/detail/540004715080974379) descreve aquisição automática do alvo mais próximo ao erguer a arma, acompanhamento inicial breve, botão **Lock** mantido para continuar acompanhando, ajuste manual para atingir pontos específicos e troca de alvo, incluindo perigos do cenário. **Focus** inicia o disparo crítico com temporização.

O [patch da demo](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1814942955096383) documenta seleção entre Tank/Modern, remapeamento, direcional digital habilitável e sensibilidade de mira mais fina. Naquela versão, **Shift/B** mantidos durante a mira travam o alvo; fora da mira, correm. **E/A** acionam o crítico. Os rótulos de gamepad usados aqui são Xbox.

## Teclado, mouse e gamepad

A tabela abaixo resume o [levantamento de bindings publicado em 28/04/2026](https://www.magicgameworld.com/ground-zero-controls-guide-pc-gamepad-keybinds/). É fonte secundária: os botões devem ser conferidos no menu da versão instalada antes de copiar o esquema inteiro. O artigo contém duplicações ambíguas, destacadas abaixo.

| Ação | Teclado / mouse | Gamepad Xbox |
| --- | --- | --- |
| Correr | Shift | B |
| Interagir / crítico | E | A |
| Erguer arma | Botão direito | LT |
| Atacar / executar caído | Botão esquerdo | RT |
| Recarregar | R | X |
| Bloquear | Ctrl | Y |
| Trocar alvo automático | T | LB |
| Escanear | G | LB, dependente de contexto |
| Esquiva direcional | Espaço | Artigo atribui R3; não confirmado |
| Usar soro | C | Artigo também atribui R3; não confirmado |
| Inventário | Tab | View/Select |
| Mapa | M | Artigo também atribui View/Select; conferir versão |
| Lanterna | F | L3 |

O [patch de abril](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770242520) alterou a relação entre mapa e pausa: mapa deixou de exigir botão mantido, e o pressionamento longo passou para a pausa. Portanto, a antiga instrução de segurar inventário para abrir o mapa não deve ser tratada como atual.

O guia de teclas consultado não lista os eixos de movimento. Não foi possível confirmar em fonte oficial consultada se o mouse usa deslocamento relativo ou posição absoluta para a mira manual, nem a curva do analógico direito, zonas mortas ou velocidade angular do tanque. Não atribuímos valores do LIMIAR ao Ground Zero. A referência oficial confirma os comportamentos de aquisição, trava, ajuste manual e troca; o laser pedido pelo usuário foi implementado como apresentação da trajetória existente.

## Alterações no LIMIAR

- Giro tanque: **1,5 → 3 rad/s**, cerca de 172°/s. Meia-volta passa de 2,09 s para **1,05 s**, com entrada máxima. Teclado, direcional, analógico e giro manual da mira compartilham a configuração. A inclinação do analógico continua modulando o giro.
- Animação de pivô acompanha a velocidade: aproximadamente 3,38x em entrada máxima. Marcha, corrida e ré preservam as velocidades existentes.
- Mira visual: **laser vermelho saindo do cano**, com pequeno ponto apenas quando há impacto. Substitui o retículo circular e oculta a mira do mouse durante a mira; baixar a arma restaura o modo anterior do ponteiro.
- O laser usa o impacto calculado pela balística e verifica também o percurso a partir do cano. Paredes interrompem o feixe; cano atravessando uma parede não projeta laser do outro lado. Há teste de profundidade e espessura ajustada à resolução do filtro retrô.
- O laser desaparece na recarga e nas interrupções de mira. Os modos de mira, seleção de alvo e botões do LIMIAR continuam definidos em [COMBAT.md](COMBAT.md) e [GAMEPAD.md](GAMEPAD.md).

## Validação

Sete probes headless passaram: unidades, locomoção, controles tanque, gamepad, contato dos pés, combate e esquiva. Combate inclui verificações do laser no cano, alvo, parede, espaço vazio, recarga e interrupção; também compara ponto do laser com impacto do tiro. Execução gráfica de combate: **1508 ticks, zero falhas**, com capturas de alvo e parede inspecionadas em `.local/lock-laser-target.png` e `.local/lock-laser-wall.png`.

Sensação com mouse físico e gamepad nas mãos ainda depende de avaliação jogando; os testes usam entradas simuladas. A velocidade nova é uma escolha de ajuste do LIMIAR, não uma medição do Ground Zero.
