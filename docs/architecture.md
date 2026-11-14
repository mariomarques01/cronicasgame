# Arquitetura

- `scenes/main/main.tscn`: entrada; composição do protótipo por código.
- `scripts/player/player.gd`: CharacterBody3D com intensidade analógica, aceleração/frenagem, assistência ao salto, estados idle/walk/run/air e câmera orbital com antecipação, centralização e SpringArm3D. Aterrissagens emitem sinal para `landing_feedback.gd`, que reutiliza pequenos emissores de poeira; colisões permitem transpor apenas degraus baixos com teto e apoio livres. `touch_controls.gd` separa joystick flutuante, câmera e botões por dedo.
- `scripts/world/terrain.gd`: terreno 256 × 256 m, grade de 4 m, altura determinística (seed 7421), normais, cores e colisão trimesh; gerado uma vez. Expansão para setores ainda não implementada.
- `scripts/world/world.gd`: composição da fazenda, marcos, vegetação MultiMesh, alvos de interação, portão e ciclo solar. Limite lógico ao norte acompanha a barreira física até a missão terminar, impedindo contornar a progressão pelas laterais.
- `scripts/systems/game.gd`: autoload do estado, sinais, missão, inventário e save versionado. JSON temporário seguido de renomeação. Carga valida esquema, IDs, duplicatas, posição, contagens e consistência da progressão antes de alterar o estado atual.
- `data/quests/forest_call.json`: metadados, objetivos, pré-requisitos e recompensa da primeira missão. Transições ainda são específicas desta missão em código; não é um motor genérico completo de campanha.
- `scripts/ui/interface.gd`: menu, HUD, diálogo, mochila, pausa e opções de sombras/ciclo solar.
- `scripts/ui/fantasy_hud.gd`: molduras SVG, retrato, indicadores reais e layout responsivo do HUD escolhido.
- `scripts/ui/minimap.gd`: SubViewport compartilhando o World3D, câmera ortogonal e atualização a 2 Hz durante a jornada ativa.
- `scripts/world/meadow_details.gd`: cobertura vegetal determinística em setores MultiMesh, sem colisões e excluindo circulação/cultivos.
- `scripts/world/valley_atmosphere.gd`: céu, ambiente, névoa Compatibility, relevo distante e partículas da árvore ancestral.
- `tests/integration.gd`: integração real da cena e sistemas usando Godot headless; restaura um save preexistente ao terminar normalmente.

Input Map é criado no `_ready` do autoload antes da cena principal, usando códigos físicos. Não há gamepad mapeado nesta entrega.

O inventário atual contém apenas pedras de missão empilhadas, tem capacidade em espaços e rejeita coleta duplicada. Não há descarte, consumo genérico, comércio ou interface de itens avançada. Lia permanece parada e não utiliza navegação; não há rotina autônoma implementada.

Compatibility foi escolhido para viabilizar WebGL e manter paridade entre os presets. Forward+, PBR com texturas, LOD por malha, streaming, níveis de qualidade completos e otimizações específicas da GTX 1650 são trabalho futuro. Vegetação repetida usa duas MultiMeshes; o alcance de visibilidade de 190 m se aplica ao conjunto MultiMesh, sem culling por instância; árvores repetidas não possuem colisão individual. Construções, portão, NPC e árvore ancestral possuem colisões simplificadas.

O menu suspende controle e avanço do ciclo, mas não pausa globalmente SceneTree. O protótipo não tem simulações autônomas que precisem de pausa global. O lago é somente visual, não possui natação nem superfície de água simulada.
