# As Crônicas de Eldervale — O Segredo da Árvore Celestial

## Cenário atual: Golden Acres (Meshy)

A fazenda jogável usa agora o modelo `assets/models/golden_acres.glb`, fornecido pelo usuário como `Meshy_AI_Golden_Acres_Homestea_1109103804_texture 2_0454.glb`. Substitui as construções, cercas, animais e plantações procedurais anteriores; as texturas do modelo são preservadas. A floresta externa e os elementos da missão continuam disponíveis. A importação gera arquivos de textura junto ao GLB: mantenha-os com suas configurações `.import`.

O modelo recebe escala uniforme de 55 e deslocamento vertical de 9,8 unidades. Uma colisão estática triangular acompanha sua geometria. O coelho começa no caminho oeste; Lia e as pedras foram reposicionadas em caminhos da nova fazenda. O mapa aéreo, controles, missão e salvamentos continuam funcionando. Salvamentos antigos são elevados até a superfície ao carregar. O modelo tem cerca de 360 mil triângulos; desempenho em celulares ainda precisa de medição.

Protótipo Godot **4.6.3**, GDScript, em português. Primeira entrega: Vale da Fazenda e missão **O Chamado da Floresta**. Modelos geométricos provisórios; não representa o visual realista final da referência.

## Jogar

Abra `project.godot` na Godot 4.6.3 e pressione **F6** na cena principal ou **F5** no editor. Pelo terminal: `godot --path .`.

- WASD: mover; mouse: câmera; Shift: correr; Espaço: pular.
- E: interagir; I: inventário; Esc: pausa e opções.
- F5 durante o jogo: salvar; F9: carregar.

A câmera usa órbita de terceira pessoa: mouse ou arrasto giram ao redor do personagem com suavização, sensibilidade reduzida e horizonte nivelado. A inclinação fica entre 8° e 55° para baixo, impedindo passar por baixo do personagem. O acompanhamento vertical amortece os saltos; colisões aproximam a câmera de obstáculos. O mapa aéreo bloqueia o giro da câmera do personagem.

Converse com **Lia**, perto da casa. Recolha os três objetos com pilares azuis: perto do moinho, da oficina e da passagem norte. Retorne a Lia e use o obelisco dourado junto ao portão norte. A barreira desaparece e permite explorar o início da floresta e sua árvore ancestral. A abertura salva automaticamente. Há também salvamento manual; sair não salva automaticamente.

`user://eldervale_v1.json` guarda posição, inventário, pedras, etapa da missão e região desbloqueada. No navegador, o armazenamento é local ao navegador/origem; use o mesmo endereço e permita armazenamento persistente. Não remova os dados do site para manter o progresso.

## Web / GitHub Pages

O preset Web usa **Compatibility / WebGL 2, sem threads**, dispensando cabeçalhos COOP/COEP. Precisa de mouse, teclado e navegador de desktop compatível com WebGL 2.

```sh
mkdir -p build/web
godot --headless --editor --import --quit
godot --headless --export-release Web build/web/index.html
python -m http.server 8000 --directory build/web
```

Instale antes os export templates oficiais da versão 4.6.3. Abra http://localhost:8000. Não abra o HTML diretamente com `file://`.

O workflow `.github/workflows/pages.yml` importa, testa, exporta Web e Windows e publica em Pages após alterações em `main`. **Publicado em https://mariomarques01.github.io/cronicasgame/**. O workflow da `main` concluiu build e deploy com sucesso (execução `42554982855`), e o endereço respondeu HTTP 200. A tentativa inicial de ativação pela API retornou 403, mas o deploy posterior concluiu e a API passou a indicar `status: built`. Para configurar uma cópia deste repositório, selecione Settings → Pages → Source: GitHub Actions.

O executável Windows é disponibilizado pelo workflow como artefato `Eldervale-Windows`. Extraia todos os arquivos juntos e execute `Eldervale.exe`.

## Validação

```sh
godot --headless --editor --import --quit
godot --headless --script tests/integration.gd
godot --headless --quit-after 120
```

Veja `docs/validation.md`, `docs/architecture.md` e `docs/roadmap.md` para resultados, limites e próximas etapas. Não há promessa de 60 FPS: não houve medição no hardware de referência.

## Atualização: celular e referência da fazenda

No celular: joystick no canto inferior esquerdo (arraste até a borda para correr), arrasto na área direita acima dos botões para girar a câmera, **Pular**, **Interagir**, **Mochila**, **Pausa**. Soltar o dedo ou pausar libera o movimento. A interface se adapta à orientação da tela. O botão **Mapa / voltar** alterna uma vista aérea para conferir a fazenda.

A disposição foi reorganizada conforme a nova referência: casa central, celeiro ao norte, oficina e poço a oeste, curral/silo a nordeste, moinho/horta a leste, depósito a sudoeste, plantações ao sul, ovelhas a sudeste e entrada sul. A passagem da missão continua ao norte.

O protagonista agora é um coelho 3D articulado com orelhas, focinho, lenço vermelho, colete e mochila, com movimento procedural dos membros. As oito texturas de superfície foram geradas por código e estão em `assets/textures`; **não são as texturas originais das imagens**. O mapa e personagem são aproximações estilizadas. Não há modelo realista com pelo, roupas e animações equivalentes à referência. Os animais são decorativos.
