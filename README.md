# As Crônicas de Eldervale — O Segredo da Árvore Celestial

Protótipo Godot **4.6.3**, GDScript, em português. Primeira entrega: Vale da Fazenda e missão **O Chamado da Floresta**. Modelos geométricos provisórios; não representa o visual realista final da referência.

## Jogar

Abra `project.godot` na Godot 4.6.3 e pressione **F6** na cena principal ou **F5** no editor. Pelo terminal: `godot --path .`.

- WASD: mover; mouse: câmera; Shift: correr; Espaço: pular.
- E: interagir; I: inventário; Esc: pausa e opções.
- F5 durante o jogo: salvar; F9: carregar.

Converse com **Lia**, perto da casa. Recolha os três objetos com pilares azuis: perto do celeiro, da margem do lago e na trilha norte. Retorne a Lia e use o obelisco dourado junto ao portão norte. A barreira desaparece e permite explorar o início da floresta e sua árvore ancestral. A abertura salva automaticamente. Há também salvamento manual; sair não salva automaticamente.

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
