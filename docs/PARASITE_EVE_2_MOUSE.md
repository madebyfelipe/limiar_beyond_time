# Parasite Eve II — levantamento e proposta de mira pelo mouse

Data: 11/10/2026. Estado: opção implementada, com validação automatizada e inspeção gráfica.

Decisões do usuário: referência é Parasite Eve II, com alvo travado e disparos em tempo real. Deve ser uma opção de jogabilidade.

## Funcionamento da referência

No controle padrão, quadrado seleciona o inimigo mais próximo; novos acionamentos percorrem os alvos. Segurar quadrado e usar esquerda/direita permite alternar rapidamente. R1 executa o ataque principal; R2, o secundário quando disponível. O combate ocorre em tempo real. O tiro pode sair mesmo com obstáculo ou alvo fora de alcance; distância, arma e munição influenciam o dano. Com carregador vazio, R1 inicia recarga se houver munição compatível.

Fonte primária: [manual original, seções Battle System e Attacking with Equipped Weapons, páginas impressas 12–15](https://dlf.emu-land.net/manuals/psx/Parasite%20Eve%202%20%28U%29.pdf).

O [guia de controles](https://gamefaqs.gamespot.com/ps/198266-parasite-eve-ii/faqs/76979/controls-tips-and-tricks) complementa: a personagem gira para o inimigo selecionado; segurar R1 repete os disparos; cancelar libera a mira. O ponto central da inspiração é escolher um inimigo e mantê-lo selecionado, enquanto posicionamento, cadência e munição continuam relevantes.

## Opção proposta para o projeto

Adicionar **Alvo travado** ao seletor de mira moderna em **Esc → Jogabilidade**. As escolhas seriam cursor no chão, livre 360, assistida e alvo travado. Manter o padrão atual; persistir a preferência junto às demais configurações. O controle tanque mantém sua configuração própria. Esta proposta acrescenta uma alternativa ao mouse.

| Entrada | Comportamento proposto |
| --- | --- |
| Mouse | Aponta o candidato a alvo antes de erguer a arma. |
| Segurar botão direito | Ergue a arma e trava no candidato sob/próximo do cursor. |
| Mover mouse durante a trava | Mantém o inimigo selecionado. |
| Roda do mouse / Tab | Roda alterna nos dois sentidos; Tab avança. Ordem pela posição horizontal na tela, com retorno ao início. |
| Botão esquerdo | Dispara; segurar repete respeitando a cadência da arma. |
| Soltar botão direito | Baixa a arma e libera a trava. Para selecionar diretamente outro inimigo, apontar e pressionar novamente. |
| R | Recarrega. |
| WASD/setas | Conserva o movimento do esquema moderno e sua velocidade reduzida durante a mira. |

A movimentação pelo teclado e a seleção pelo cursor são adaptações propostas, não uma reprodução dos controles originais.

## Regras propostas para uma trava previsível

- Aquisição considera alvos vivos, dentro do alcance, na tela e sem parede entre arma e alvo. Prioridade pela proximidade do cursor na tela, com tolerância pequena para facilitar apontar em baixa resolução. Se não houver candidato, permite mira livre pelo cursor.
- A trava acompanha a posição 3D do inimigo. Passar o mouse sobre outro inimigo não substitui o selecionado.
- Um corte de câmera conserva a identidade do alvo e o rumo no mundo. Se ele ficar fora da tela, usar indicação na borda.
- Uma obstrução temporária conserva a seleção e exibe aviso de bloqueio. O tiro continua colidindo com a parede. Não confundir alvo selecionado com acerto garantido.
- Alvo morto, removido ou fora de alcance libera a trava. A próxima escolha fica com o jogador, evitando consumir munição num inimigo escolhido sem sua intenção.
- Pausa, terminal, transição de porta e mudança do modo interrompem a mira e o disparo mantido. Retomar exige novo acionamento do gatilho.
- Marcador no inimigo selecionado e retículo no impacto previsto mostram separadamente seleção e trajetória real. Antes do corpo terminar de virar, o retículo deve refletir a direção atual da arma.
- Cadência, munição, recarga e dano continuam pertencendo à arma. Repetição ao segurar o gatilho pertence a este modo proposto; os outros conservam o comportamento atual.

## Implementação

`PlayerWeapon` controla aquisição pelo cursor, manutenção da trava, troca pela roda/Tab e repetição de disparo. Os três modos anteriores continuam disponíveis e respondem a um disparo por acionamento. `AimSettings.Modern.LOCKED` foi acrescentado ao fim do enum, preservando os valores salvos dos modos anteriores e o padrão livre 360.

`lock_indicator.gd` desenha colchetes no alvo, aviso BLOQUEADO e seta para alvo fora da tela, separadamente do retículo de impacto. A página de jogabilidade explica os controles e avisa quando o esquema tanque está ativo. Pausa, perda de controle e troca de configuração interrompem a mira e exigem soltar os botões. A morte/perda do alvo também interrompe o gatilho mantido. A recarga pode completar e retomar o disparo enquanto o gatilho está pressionado.

Reutiliza o mapeamento janela → viewport de `AimSolver`. Há alvos de treino, mas ainda não há inimigos com comportamento de combate.

## Verificação realizada

`tests/check_combat.gd`: 1430 ticks headless, zero falhas; inclui os três modos anteriores e tanque, aquisição próxima do cursor, recusa de alvo atrás de parede, mouse atravessando outro alvo sem trocar a trava, eventos de roda nos dois sentidos e retorno ao início, caminhada, alvo móvel, corte de câmera, obstrução, cadência, liberação do gatilho, morte/remoção/alcance, pausa e perda de controle, recarga com estoque limitado e persistência em arquivo isolado. O teste protege o arquivo de configurações do jogador.

Execução gráfica: 1438 ticks, zero falhas. Capturas de seleção, bloqueio, indicação fora da tela e menu em 16:9/4:3 inspecionadas. Regressões de portas, tanque, terminal, operação dos cenários e combate: cinco probes, zero falhas. Mouse físico humano ainda requer avaliação do conforto da tolerância e troca de alvos.
