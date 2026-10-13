# Porta da transição

`painted_steel_v01.png`: textura de aço pintado desgastado gerada com image_gen
integrado. Prompt completo em `painted_steel_v01.prompt.txt`.

`systems/interaction/door_steel.gdshader` projeta a textura no espaço local da
malha em três eixos: mantém o tamanho do grão na face, verso e espessura, e
acompanha a dobradiça durante a animação. Folha e chapa inferior usam o shader;
o batente usa a mesma textura com tonalidade mais escura. Janela e maçaneta
continuam sendo peças 3D separadas.

O nome de destino vem de `DoorInteraction.destination_name`: Guardhouse,
Guardhouse Yard ou Perimeter Trail. É mostrado dentro do quadro 16:9 durante
a abertura, acima do filtro e abaixo do fade, também em janelas 4:3.
