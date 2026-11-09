# Validação executada nesta entrega

Ambiente: Linux, Godot 4.6.3 oficial. Não foi usado o PC de referência nem Windows para executar o jogo.

- `godot --headless --editor --import --quit`: importação e scripts aprovados.
- `godot --headless --quit-after 120`: cena principal iniciou e encerrou sem erros.
- `godot --headless --script tests/integration.gd`: 25 verificações, **zero falhas**. Câmera e inputs instanciados; coleta anterior à conversa rejeitada; três pedras coletadas; duplicata rejeitada; retorno obrigatório; recompensa única; portão invisível com colisão desativada; gravação e carga; região persistente; raycast do terreno; jogador pousa; save duplicado/corrompido/ausente rejeitado sem perda do estado atual.
- Exportação Web release single-thread e Windows x86_64 release concluídas pelos presets, com templates oficiais da mesma versão. Executável Windows gerado, mas **não executado no Windows**.
- Chromium/Playwright iniciou o export Web via servidor HTTP e registrou Godot/WebGL 2 Compatibility, sem erro de script no console até esse ponto. Capturas do menu e da cena após clicar em Iniciar foram inspecionadas. A primeira captura revelou menu cortado; âncoras corrigidas e nova captura confirmou menu inteiro e entrada no jogo. Movimento, salto e pausa foram enviados por automação; a missão completa foi validada pela integração headless, não percorrida manualmente no navegador.
- GitHub Pages: tentativa de ativação pela API recebeu HTTP 403 `Resource not accessible by integration`. Esse foi o resultado inicial; veja o resultado final abaixo.

Correções durante os testes: tipagem explícita da cena no teste; comparação numérica compatível com JSON no inventário; parser de save inválido com retorno controlado; extração dos templates Web sem threads corretos; redução de polígonos das árvores repetidas para reduzir custo de renderização; âncoras do menu e contorno dos textos para legibilidade.

Não foi validado: 60 FPS/1080p, VRAM, gamepad, campanha completa, restante das regiões, agricultura, reparos, combate ou fidelidade realista. Esses recursos não são apresentados como concluídos.

## CI e verificação visual final

O workflow da PR #1, execução `42554826410`, concluiu com sucesso: instalação, importação, 25 verificações, exportação Web e Windows e upload dos artefatos. O deploy é executado apenas em `main`. Captura adicional confirmou o menu de pausa visível e seus botões. O contorno dos textos foi acrescentado depois das capturas armazenadas para melhorar leitura sobre o terreno.

## Publicação confirmada

A execução da main `42554982855` concluiu **build e deploy com sucesso** no commit de merge `94b4d6f`. A API Pages retornou `build_type: workflow`, `status: built` e a URL https://mariomarques01.github.io/cronicasgame/ respondeu HTTP 200. A falha inicial de ativação pela API não permaneceu como bloqueio após a execução do workflow. Não é necessário ativar Pages novamente.

## Atualização para toque e nova fazenda

Adicionados eventos multitoque: joystick move o CharacterBody3D sem teclado, soltar interrompe, salto aplica velocidade vertical e pausa zera comandos. O teste envia eventos diretamente ao viewport em coordenadas locais; a primeira tentativa usava coordenadas globais sem transformar pela escala da janela e foi corrigida no teste. Chromium emulado a 390×844 mostrou menu, entrada no jogo, movimento com toque e rotação para 844×390 com controles visíveis e canvas ocupando a tela. Não houve teste em iPhone/Safari físico nem medição de FPS. Há aviso de AudioContext antes do primeiro gesto; o protótipo não reproduz áudio.

As referências não fornecem geometria/UVs/texturas de produção. As superfícies adicionadas são PNGs procedurais originais de 256 px (madeira, telhado, pedra, grama, terra, pelo, couro, tecido). O coelho é uma malha composta articulada proceduralmente, não uma reconstrução fiel do personagem da imagem.

Resultado final desta revisão: **32 verificações aprovadas**, incluindo arrasto da câmera por segundo dedo, botão Pular via evento de toque, ida/volta da câmera aérea e os testes anteriores da missão/save. Botões móveis recebem eventos ScreenTouch diretamente, permitindo ações com um segundo dedo enquanto o joystick é usado, sem depender da emulação de mouse de um único toque. Capturas em `docs/screenshots/mobile-portrait.png`, `mobile-landscape.png` e `farm-map.png` documentam a aproximação visual, anterior apenas ao acabamento contínuo das trilhas.
