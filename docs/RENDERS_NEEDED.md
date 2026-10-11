# Renders necessários para retomar a calibração — T06

**Atualização 11/10/2026:** os três renders ENV_1 foram recebidos e preservados. O usuário escolheu fundos de estudo consistentes para concluir T06/T07; fichas aprovadas em `docs/calibration/ROUTE_STUDY.md`. ENV_1 permanece para refinamento, com hipóteses em `docs/calibration/ENV_1.md`. Não há pedido de novos renders. O restante deste arquivo é o handoff histórico anterior ao recebimento.

Parada solicitada pelo usuário em 11/10/2026: notificar ao chegar à necessidade dos renders de ambientes. T01–T05 usam somente primitivas e estudos SVG originais provisórios. Esses estudos não definem arte ou ambientes canônicos.

## Material para a próxima etapa

- Renders 16:9; preferencialmente 1920 × 1080, sem barras incorporadas à imagem.
- Para começar, dois enquadramentos fixos do mesmo espaço, com área caminhável comum e um obstáculo contornável. No percurso T07 serão necessários três enquadramentos de duas áreas conectadas por corredor.
- Cada imagem deve mostrar chão e referências de escala suficientes para posicionar uma cápsula de 1,8 m sem distorção.
- Se os renders vierem de uma cena 3D, incluir posição/rotação da câmera, FOV ou lente/sensor e unidades/escala. Esses dados ajudam; para imagens pintadas, a câmera será ajustada manualmente.
- Identificar o espaço e o enquadramento de cada arquivo. Colocar as imagens em `assets/backgrounds/` ou fornecer os arquivos ao executor quando retomar.

## O que será feito na T06

Grade 3D e marcadores de debug, ajustes no Inspector e ficha por enquadramento com imagem/dimensões/câmera/escala. Selecionar pelo menos seis correspondências distribuídas entre perto/longe e esquerda/direita; medir erro em 1080p, buscando máximo de oito pixels. Uma reprodução por outro executor fecha o aceite.

As colisões e oclusores serão alinhados aos renders. Imagens incompatíveis com perspectiva consistente precisarão ser corrigidas ou rejeitadas; o personagem mantém sua escala. Não foi criada ferramenta de calibração nem iniciado percurso T07 nesta parada.

## Reprodução mínima da pendência

Na raiz `E:\LIMIAR`, executar `rg --files assets/backgrounds`. O inventário atual contém somente `composition_study.svg`, `occlusion_study.svg`, `second_shot_study.svg` e sidecars `.import`. Não há render de ambiente fornecido pelo usuário para selecionar e calibrar.

Na parada inicial, T06 ficou bloqueada antes da implementação. Após o recebimento, as ferramentas foram implementadas; o gate ENV_1 ainda falha. Posteriormente, por escolha do usuário, T06 foi concluída com estudos autorais e T07 foi implementada; T08–T10 permanecem pendentes.
