# Arquitetura

- `scenes/main/main.tscn`: entrada; composição do protótipo por código.
- `scripts/player/player.gd`: CharacterBody3D com intensidade analógica, aceleração/frenagem, assistência ao salto, estados idle/walk/run/air e câmera orbital com antecipação, centralização e SpringArm3D. Aterrissagens emitem sinal para `landing_feedback.gd`, que reutiliza pequenos emissores de poeira; colisões permitem transpor apenas degraus baixos com teto e apoio livres. `touch_controls.gd` separa joystick flutuante, câmera e botões por dedo.
- `scripts/world/terrain.gd`: terreno 256 × 256 m, grade de 4 m, altura determinística (seed 7421), normais, cores e colisão trimesh; gerado uma vez. Expansão para setores ainda não implementada.
- `scripts/world/ancient_ruins.gd`: região de ruínas, arquitetura modular, colisões, leitura por proximidade e avanço automático. `ruins_layout.gd` reserva o pátio e as trilhas antes da geração de terreno/vegetação.
- `scripts/world/world.gd`: composição da fazenda, marcos, vegetação MultiMesh, alvos de interação, portão e ciclo solar. Limite lógico ao norte acompanha a barreira física até a missão terminar, impedindo contornar a progressão pelas laterais.
- `scripts/systems/game.gd`: autoload do estado, sinais, missão, inventário e save versionado. Uma conversa inicia a missão e a terceira pedra abre a passagem automaticamente; saves antigos de retorno a Lia/mecanismo migram para passagem aberta. A cena salva a conversa e as coletas; a região salva descoberta, inscrições e chegada à árvore. O formato v2 valida as inscrições de cada etapa e lê saves v1. JSON temporário seguido de renomeação. Carga valida esquema, IDs, duplicatas, posição, contagens e consistência da progressão antes de alterar o estado atual.
- `data/quests/forest_call.json`: metadados, objetivos, pré-requisitos e recompensa da primeira missão. Transições ainda são específicas desta missão em código; não é um motor genérico completo de campanha.
- `scripts/ui/interface.gd`: menu, HUD, diálogo, mochila, pausa e opções de sombras/ciclo solar.
- `scripts/ui/fantasy_hud.gd`: molduras SVG, retrato, indicadores reais e layout responsivo do HUD escolhido.
- `scripts/ui/minimap.gd`: SubViewport compartilhando o World3D, câmera ortogonal e captura inicial única; o movimento desloca o recorte da textura, sem renderização periódica do mundo.
- `scripts/world/meadow_details.gd`: cobertura vegetal determinística em setores MultiMesh, sem colisões e excluindo circulação/cultivos.
- `scripts/world/valley_atmosphere.gd`: céu, ambiente, névoa Compatibility, relevo distante e partículas da árvore ancestral.
- `tests/integration.gd`: integração real da cena e sistemas usando Godot headless; restaura um save preexistente ao terminar normalmente.

Input Map é criado no `_ready` do autoload antes da cena principal, usando códigos físicos. Não há gamepad mapeado nesta entrega.

O inventário atual contém apenas pedras de missão empilhadas, tem capacidade em espaços e rejeita coleta duplicada. Não há descarte, consumo genérico, comércio ou interface de itens avançada. Lia permanece parada e não utiliza navegação; não há rotina autônoma implementada.

Compatibility mantém paridade entre os presets WebGL e desktop. Texturas PBR e malhas reduzidas são usadas no cenário; o coelho de execução tem 18 mil triângulos e clipes pré-processados. Árvores e cercas são agrupadas por células para descarte espacial, com colisões simples individuais. Streaming e um sistema completo de níveis de qualidade ainda não foram implementados. O cenário e a expansão devem respeitar os limites documentados em `docs/mobile-geometry-budget.md` e `docs/ancient-ruins.md`.

O menu suspende controle e avanço do ciclo, mas não pausa globalmente SceneTree. O protótipo não tem simulações autônomas que precisem de pausa global. O Lago do Vale do mapa de referência ainda não foi construído nesta versão; não há natação implementada.
