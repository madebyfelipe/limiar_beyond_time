# Mapas editáveis

Mapas são cenas 3D comuns em `maps/`, feitas e alteradas no editor do Godot,
sem escrever código. Um executor genérico (`environments/maps/map_runner.tscn`)
monta a fase em volta do mapa: Dylan, câmeras fixas com cortes, pausa, F3,
maleta, filtro, arte opcional e Kelekens.

## Atalhos

| Linux | Windows | O que faz |
| --- | --- | --- |
| `./criar-mapa.sh nome` | `criar-mapa.cmd nome` | Cria `maps/nome.tscn` a partir do modelo: chão, blocos, rampa, duas câmeras e o início. |
| `./editar-mapas.sh [nome]` | `editar-mapas.cmd [nome]` | Abre o editor, já com o mapa aberto quando o nome é dado. |
| `./executar-mapa.sh [nome]` | `executar-mapa.cmd [nome]` | Joga o mapa. Sem nome, o `exemplo`. No editor, **F6** sobre o mapa faz o mesmo. |
| `./converter-fase.sh fase [--force]` | `converter-fase.cmd fase [--force]` | Copia uma fase pronta para `maps/`: `exterior`, `sala`, `perimetro`, `rele`, `patio-servico`, `percurso`. |

## Estrutura de um mapa

A raiz é um `MapRoot` (`systems/maps/map_root.gd`). O editor avisa, com um
triângulo amarelo, quando falta alguma parte.

| Nó | Tipo | Papel |
| --- | --- | --- |
| `Geometry` | Node3D | Tudo em que Dylan pisa ou esbarra. Colidem: **CSG** com *Use Collision* ligado (o mais prático para rascunho), **StaticBody3D** com forma, e **MeshInstance3D** com o meta `collision_size` (Vector3, caixa) ou `collision_points` (cunha), que é a convenção das fontes autorais. |
| `Shots/*` | `MapShot` (Camera3D) | Um enquadramento fixo. Posicione com o botão **Preview** da câmera no editor. Opcional: `background` (prancha pintada), `zoom`/`focus` (recorte). |
| `Zones/*` | `MapZone` (Area3D) | Caixa que corta para a câmera em `camera` enquanto Dylan está dentro. Precisa de uma CollisionShape3D com BoxShape3D. Zonas podem se sobrepor: maior `shot_priority` vence; no empate, a câmera atual fica. |
| `PlayerStart` | Marker3D | Onde Dylan aparece, olhando para o −Z do marcador. |
| `Keleken*` | Marker3D | Um Keleken por marcador, vagando num quadrado de lado `2 × keleken_radius` (propriedade da raiz). |

Na raiz também ficam `map_title`, a luz ambiente e a luz das câmeras.

## Fluxo de trabalho

1. `./criar-mapa.sh meu_mapa` e `./editar-mapas.sh meu_mapa`.
2. Em `Geometry`, duplique (Ctrl+D) e mova os blocos CSG, ou adicione novos
   (`CSGBox3D`, `CSGCylinder3D`, `CSGPolygon3D`), sempre com *Use Collision*.
   Escala: Dylan mede 1,8 m e a cápsula tem raio 0,3 m.
3. Para cada área, uma `MapShot` em `Shots` e uma `MapZone` em `Zones` com
   `camera` apontando para ela. Para criar outra câmera, duplique uma existente.
4. **F6** joga o mapa. **B** alterna prancha/geometria quando há prancha.

### Prancha pintada (opcional)

As pranchas das fases foram geradas sobre capturas da geometria em cada
câmera. Num mapa novo, o caminho é o mesmo: capture a vista da `MapShot`,
pinte por cima mantendo as linhas, coloque o PNG em `assets/backgrounds/` e
arraste-o para `background`. A geometria passa a desenhar a prancha sobre si
e esconde Dylan onde a pintura esconderia.

## Fases convertidas: o que vem e o que não vem

`converter-fase` cria uma **cópia** editável. A fase original e seus testes
não mudam. A cópia traz geometria e colisão (incluindo limites invisíveis),
câmeras com pranchas e recortes, zonas de corte, o início de Dylan e a posição
dos animais.

**Não** vêm portas, terminais, baús, cinemáticas, objetivos e encadeamento de
fases. Essas partes ficam no script de cada fase (`environments/*.gd`). Por
isso, editar `maps/exterior.tscn` não altera a fase que o NEW GAME abre.
Ligar um mapa à campanha exige trazer essas interações para o mapa, um
trabalho à parte.

Para editar a geometria da própria fase, há as fontes `environments/*_source.tscn`.
Elas são regeneradas pelos scripts `tools/author_*.gd`, que **sobrescrevem**
edições manuais. Edite a fonte à mão só se não for rodar o autor de novo, ou
passe a mudança para o script.

`--force` recria o mapa a partir da fase e descarta as edições feitas nele.

## Verificação

`tests/check_maps.gd` (probe `mapas` da suíte) joga o `exemplo` com entrada
real: início no marcador, corte para a segunda câmera e de volta, bloqueio da
parede CSG e reinício. Depois abre todos os outros mapas de `maps/` e confere
câmeras, zonas, chão e enquadramento ativo. Com o corte desligado de propósito,
o probe reprovou em 5 asserções.
