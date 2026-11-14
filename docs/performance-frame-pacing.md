# Redução de travadas durante o jogo

## Correções

- **Minimapa:** substitui uma renderização adicional do mundo a cada 0,5 s por uma captura de 512 × 512 durante a tela inicial. A câmera captura 360 m do cenário; o HUD recorta uma janela de 92 m e desloca as coordenadas UV conforme o jogador anda. A seta continua seguindo a orientação da câmera. O botão mantém o mapa aéreo ao vivo. A miniatura é estática: iluminação e objetos coletados não são recapturados.
- **HUD:** layout e estilos passam a ser aplicados quando dimensões, menu, modo de toque, texto ou estado visível mudam. O temporizador das notificações continua funcionando a cada quadro. Isso evita invalidações repetidas de temas, texto e containers.
- **Retina/web:** resolução da cena 3D limitada a 1,25 pixels por pixel CSS e a 1280 × 720 pixels de área. O HUD permanece na resolução nativa. Em DPR 3, a área 3D passa a aproximadamente 17,4% da área física original, sem diminuir os botões. A resolução varia com a orientação/tamanho da janela.
- **Efeitos:** seis emissores dedicados à poeira e dois ao brilho. Quantidade, malha e duração são configuradas uma vez; eventos não redimensionam buffers de partículas nem trocam materiais. Atualização da pausa somente quando o estado muda.

## Validação

294 verificações de integração aprovadas, sem falhas. Incluem orçamento de pixels em DPR 1/2/3 e retrato/paisagem, contagem fixa de capturas do minimapa, deslocamento UV, HUD estável sem novos layouts e configurações imutáveis dos emissores durante rajadas. Os testes anteriores de movimento, salto, colisão, HUD, pausa, diálogos e coleta permanecem ativos. A CI também exporta web/Windows e testa a jornada no pacote exportado.

A inspeção local usa renderização OpenGL por software (llvmpipe), que não representa o GPU de um telefone. A correção remove trabalho desnecessário identificável no código; não é uma garantia de FPS nem substitui a avaliação no aparelho em que o usuário observou as travadas.
