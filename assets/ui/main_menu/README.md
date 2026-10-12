# Menu inicial

Arte gerada com a ferramenta integrada ImageGen a partir da referência visual do usuário. O cenário não contém texto: logo, botões e partículas são camadas independentes no Godot.

- `snow_outpost_v02.png`: cenário noturno 16:9 em uso, com o dinossauro removido via edição no ImageGen.
- `snow_outpost_v01.png`: versão original preservada.
- `limiar_logo_v01.png`: logo LIMIAR com transparência, reutilizável separadamente.
- `background.prompt.txt` / `logo.prompt.txt`: prompts de geração.
- `background_v02.prompt.txt`: prompt da remoção do dinossauro.

O cenário e a neve recebem um shake suave de até 2,5 pixels nas coordenadas do design. Logo e controles ficam estáveis. Uma margem adicional no fundo evita revelar as bordas durante o movimento. A intensidade é ajustável em `camera_shake_strength` na cena do menu.

Cena: `res://ui/main_menu.tscn`. Inicie por `executar-menu.cmd` ou pela cena principal do projeto. Mouse, setas/Enter e gamepad navegam. OPTIONS reutiliza as configurações existentes. NEW GAME inicia no exterior com estoque e missão novos, preservando o save até o próximo salvamento. LOAD GAME restaura o registro do terminal. EXTRAS abre os estudos já disponíveis.
