# Validação executada nesta entrega

Ambiente: Linux, Godot 4.6.3 oficial. Não foi usado o PC de referência nem Windows para executar o jogo.

- `godot --headless --editor --import --quit`: importação e scripts aprovados.
- `godot --headless --quit-after 120`: cena principal iniciou e encerrou sem erros.
- `godot --headless --script tests/integration.gd`: 25 verificações, **zero falhas**. Câmera e inputs instanciados; coleta anterior à conversa rejeitada; três pedras coletadas; duplicata rejeitada; retorno obrigatório; recompensa única; portão invisível com colisão desativada; gravação e carga; região persistente; raycast do terreno; jogador pousa; save duplicado/corrompido/ausente rejeitado sem perda do estado atual.
- Exportação Web release single-thread e Windows x86_64 release concluídas pelos presets, com templates oficiais da mesma versão. Executável Windows gerado, mas **não executado no Windows**.
- Chromium/Playwright iniciou o export Web via servidor HTTP e registrou Godot/WebGL 2 Compatibility, sem erro de script no console até esse ponto. Capturas do menu e da cena após clicar em Iniciar foram inspecionadas. A primeira captura revelou menu cortado; âncoras corrigidas e nova captura confirmou menu inteiro e entrada no jogo. Movimento, salto e pausa foram enviados por automação; a missão completa foi validada pela integração headless, não percorrida manualmente no navegador.
- GitHub Pages: tentativa de ativação pela API recebeu HTTP 403 `Resource not accessible by integration`. Requer ação administrativa no repositório: Settings → Pages → Source: GitHub Actions.

Correções durante os testes: tipagem explícita da cena no teste; comparação numérica compatível com JSON no inventário; parser de save inválido com retorno controlado; extração dos templates Web sem threads corretos; redução de polígonos das árvores repetidas para reduzir custo de renderização; âncoras do menu e contorno dos textos para legibilidade.

Não foi validado: 60 FPS/1080p, VRAM, gamepad, campanha completa, restante das regiões, agricultura, reparos, combate ou fidelidade realista. Esses recursos não são apresentados como concluídos.
