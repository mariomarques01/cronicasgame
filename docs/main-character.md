# Personagem principal importado

Modelo fornecido pelo usuário: Meshy_AI_The_Brave_Bunny_Explo_1109112006_texture.glb.
Copiado sem alteração para `assets/models/brave_bunny.glb`, com um material e três texturas incorporadas. O arquivo não contém esqueleto nem clipes de animação.

`imported_bunny.gd` instancia o modelo, ajusta a altura para 2,5 m incluindo orelhas e posiciona a base nos pés do controlador. O controlador mantém movimento, corrida, salto, giro, colisão simplificada e câmera. A malha acompanha o corpo, mas não move braços/pernas: um rig e animações ainda são necessários. O coelho procedural anterior permanece no repositório, sem ser instanciado pelo jogador.

## Arquivo animado

O jogador agora usa `bunny_animated.glb`, fornecido posteriormente pelo usuário. Contém um esqueleto e os clipes Walking e Running. Os ciclos são repetidos e alternam com transição de 0,18 s. O controlador continua sendo responsável pelo deslocamento e pela física. O modelo tem altura de origem de 1,7 m e é escalado para 2,5 m, com base em Y=0.

Sem clipes de idle ou jump no arquivo: parado usa uma pose congelada de Walking e no ar suspende o ciclo atual. Não há animação específica de salto, aterrissagem ou respiração.
