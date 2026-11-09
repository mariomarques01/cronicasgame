# Personagem principal importado

Modelo fornecido pelo usuário: Meshy_AI_The_Brave_Bunny_Explo_1109112006_texture.glb.
Copiado sem alteração para `assets/models/brave_bunny.glb`, com um material e três texturas incorporadas. O arquivo não contém esqueleto nem clipes de animação.

`imported_bunny.gd` instancia o modelo, ajusta a altura para 2,5 m incluindo orelhas e posiciona a base nos pés do controlador. O controlador mantém movimento, corrida, salto, giro, colisão simplificada e câmera. A malha acompanha o corpo, mas não move braços/pernas: um rig e animações ainda são necessários. O coelho procedural anterior permanece no repositório, sem ser instanciado pelo jogador.

## Arquivo animado

O jogador agora usa `bunny_animated.glb`, fornecido posteriormente pelo usuário. Contém um esqueleto e os clipes Walking e Running. Os ciclos são repetidos e alternam com transição de 0,18 s. O controlador continua sendo responsável pelo deslocamento e pela física. O modelo tem altura de origem de 1,7 m e é escalado para 2,5 m, com base em Y=0.

Parado usa uma pose congelada de Walking. Não há um clipe separado de respiração.

## Pulo do arquivo Jumping.fbx

O arquivo `assets/models/Jumping.fbx`, fornecido pelo usuário, contém o clipe Mixamo `mixamo_com` (1,9 s). `imported_bunny.gd` adapta suas rotações para os ossos correspondentes do coelho, levando em conta as orientações globais de repouso dos dois esqueletos. Ossos ausentes no coelho, como dedos, são ignorados. Escala e deslocamento global não são copiados: comprimentos dos membros e trajetória permanecem sob controle do modelo e da física.

O clipe `Jumping` usa somente a fase de voo do FBX (0,50–1,10 s), sincronizada com a velocidade vertical do controlador: decolagem em 0,50 s, ápice em 0,78 s e descida até 1,10 s. A preparação não é comprimida dentro do voo. Quedas longas mantêm a pose de descida; perdas de chão inferiores a 0,10 s ao descer pequenos desníveis não disparam pulo.

O contato com o chão aciona `JumpLanding`, extraído de 1,10–1,65 s do FBX e reproduzido em 0,20 s. Uma translação local apenas vertical do quadril acompanha a flexão dos joelhos, sem copiar a translação balística do FBX nem mudar o corpo físico. Depois o personagem retoma a caminhada, corrida ou pose parada. A sequência renderizada em `docs/screenshots/jump-phases.png` mostra decolagem, ápice, descida e absorção da aterrissagem.
