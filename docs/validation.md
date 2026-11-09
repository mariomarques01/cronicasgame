# Validação executada nesta entrega

## Correção da publicação Pages e densidade da floresta

A execução `42653222998` concluiu o build em 2m03s e falhou na publicação após 10m07s, com `Timeout reached, aborting!`. O serviço aceita no máximo 10 minutos de deploy; o workflow respeita esse teto, com limite do job de 30 minutos. Após reduzir o pacote, a execução `42659472298` concluiu build e publicação com sucesso: build de 2m29s e deploy de 46s.

Os presets agora selecionam explicitamente os recursos de execução, incluindo scripts e JSON carregados dinamicamente, deixando fora fontes e cenas de teste não utilizadas. Texturas acima de 2048 px usam esse limite de importação, preservando os arquivos originais. O pacote Web passou de aproximadamente 373 MiB para 146 MiB. Os 120 testes de integração continuam aprovados; Web e Windows foram exportados novamente.

Um teste adicional executa o próprio pacote Web em um diretório vazio, validando os modelos, os dados JSON, o início do jogo e a missão até a abertura do portão. Essa checagem foi adicionada ao workflow antes do upload. A floresta externa passou de 313 para 157 árvores, mantendo os quatro pinheiros internos e o marco ancestral.

## Moinho, celeiro e oficina fornecidos

**120 verificações aprovadas, zero falhas**. Cobertura dos três elementos independentes, materiais fornecidos, malhas otimizadas, remoção das construções antigas da malha/colisão fundida e correspondência entre colisões e novos modelos. Acessos às pedras antigas perto da oficina e do moinho continuam livres, assim como as entradas da fazenda. Preservação da vegetação fora das áreas substituídas verificada por assinaturas de geometria e UVs. As hélices são testadas separadamente: 120 s por volta, torre/eixo fixos, ciclo contínuo, pausa e geometria sem duplicação.

Modelos inspecionados isoladamente e em terceira pessoa no mapa, além de vista aérea. A rotação foi renderizada e conferida em 0 s, 15 s e 30 s. Exportações Web e Windows release concluídas. A oficina mantém a posição à esquerda perto do poço; celeiro ao norte e moinho a leste. Fontes GLB preservadas. Sem medição de FPS em celular físico ou execução do binário Windows neste Linux.

## Pinheiros internos e árvores externas

**102 verificações aprovadas, zero falhas**. Cobertura da classificação pelo cercado real, modelos compartilhados, setores da floresta, substituição da árvore ancestral, remoção do tronco inclinado e preservação das plantas por comparação de posições dos triângulos e UVs com referências anteriores. A missão, os salvamentos, o controlador, as cercas, a casa, as entradas e a câmera continuam passando nos testes existentes.

Renderizações em terceira pessoa no pátio, sudoeste e floresta externa e inspeção da vista aérea. **4 pinheiros internos e 313 árvores externas**. Exportações Web e Windows release concluídas. Fontes GLB preservadas; modelos de execução com 15.716 triângulos cada. Sem medição de FPS em celular físico ou execução do binário Windows neste Linux.

## Casa principal Cozy Timber Hearth

**91 verificações aprovadas, zero falhas**. Cobertura adicionada para presença do modelo, largura de 24 unidades, malha otimizada, remoção da casa antiga da geometria/colisão fundida, colisão do novo telhado e passagem livre no lado oeste. Os testes existentes de cercas, entradas, missão, salvamento, animações, câmera e toque continuam passando.

Modelo inspecionado isoladamente e integrado ao cenário, com renderizações frontal, lateral e aérea no Godot Compatibility. Exportações Web e Windows release concluídas. A fonte GLB foi preservada sem alterações; derivação com 56.786 triângulos, frente voltada para o caminho e solo do pátio recomposto. Sem medição de FPS em aparelho físico ou execução do binário Windows neste Linux.

## Substituição das cercas por Mossy Garden

**85 verificações de integração aprovadas, zero falhas**. Cobertura de seções compartilhando malha simplificada, colisões correspondentes, bloqueio pelas novas cercas, abertura das plantações, perímetro externo, acesso norte ao portão, remoção do arco deformado, piso nivelado na entrada sul e remoção dos fragmentos altos junto aos canteiros. O próprio controlador atravessa a entrada sul caminhando por 220 frames de física, sem saltar.

Inspeção de renderizações em terceira pessoa no início, entrada sul e horta, além de vista aérea do mapa. Exportações Web e Windows release concluídas. A fonte Mossy Garden contém 140.766 triângulos; o módulo compartilhado usado em 192 seções contém 4.394. Não houve medição de FPS em celular físico nem execução do binário Windows neste Linux. Fontes GLB originais preservadas; processamento reproduzível em `tools/bake_farm_fences.gd`.

## Tela inicial com arte fornecida

**73 verificações de integração aprovadas, zero falhas**. Abertura sem HUD/painel antigo, arte proporcional inteira e área clicável alinhada em retrato/paisagem/desktop, opção Continuar condicionada a salvamento e início da jornada pelo botão da arte. A imagem original de `MENU.zip` é usada sem recriação.

Renderização e inspeção no Godot Compatibility em 960×1280, 1280×720 e 390×844; cliques reais enviados às áreas do botão iniciaram a ação nas três dimensões. Exportações Web e Windows release concluídas. Pausa, diálogos e inventário continuam usando os painéis do jogo; a abertura se oculta ao jogar e reaparece ao voltar ao menu. Não houve teste em celular físico.

## Câmera de terceira pessoa

**64 verificações de integração aprovadas, zero falhas**. Novas verificações cobrem limites verticais, órbita sem rolagem lateral, suavização gradual, acompanhamento vertical amortecido e bloqueio de giro durante o mapa. Importação e exportações Web/Windows release concluídas. Enquadramentos inicial, limite superior e limite inferior foram renderizados e inspecionados no cenário Golden Acres pelo Godot Compatibility. Sensibilidade de mouse usa deslocamento de tela; eventos de mouse emulados por toque são ignorados para evitar aplicação duplicada. Não houve avaliação manual em celular físico.

## Correção da animação de pulo

Integração headless: **57 verificações aprovadas, zero falhas**. Além dos testes anteriores de missão/física/toque, a cobertura verifica fases de decolagem e ápice sincronizadas com a velocidade vertical, pose mantida em quedas longas, aterrissagem somente no chão, compressão local do quadril e retorno à corrida. Pequenos desníveis não disparam pulo nem agachamento. A translação global continua sendo física; somente a flexão local do quadril é animada.

Sequência de poses renderizada no Godot Compatibility e inspecionada, em `docs/screenshots/jump-phases.png`, sobre um piso de referência: decolagem, subida, ápice, descida, contato e recuperação. Exportações Web e Windows release concluídas. A sequência visual usa trajetória balística controlada; não representa um teste manual completo no navegador/celular. O executável Windows não foi executado neste Linux.

## Substituição da fazenda por Golden Acres

O GLB enviado pelo usuário foi importado e integrado à cena principal, preservando suas texturas. Importação e exportação Web release concluídas sem erros. A integração headless passou em **45 verificações, zero falhas**, incluindo presença do cenário Meshy, ausência da antiga fazenda procedural, colisão do modelo sob o ponto inicial e apoio físico dos cinco objetivos. Os testes anteriores de missão, salvamento, animação, física e toque continuam passando.

A cena principal também foi executada por 120 frames em modo headless. Esta validação não mede FPS, não percorre todos os caminhos da malha gerada e não substitui uma revisão visual e de desempenho no navegador/celular. A alteração local não publica automaticamente no GitHub Pages.

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
