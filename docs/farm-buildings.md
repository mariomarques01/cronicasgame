# Moinho, celeiro e oficina

Fontes enviadas pelo usuário, preservadas sem alterações:

- `moinho.glb` → `assets/models/windmill.glb`.
- `celeiro 3d model.glb` → `assets/models/barn.glb`.
- `ofcina 3d model.glb` → `assets/models/workshop.glb`.

`scripts/world/farm_buildings.gd` instancia os três modelos com seus materiais e colisões triangulares. A oficina é a construção à esquerda/noroeste próxima ao poço. O celeiro continua ao norte e o moinho a leste. Colocação em `data/regions/farm_buildings.json`:

| Elemento | Centro X/Y/Z | Dimensão | Frente |
| --- | --- | --- | --- |
| Oficina | -30,25 / 0,025 / -27,5 | largura 13 | 45° para o caminho central |
| Celeiro | -2,2 / 0,025 / -36,3 | largura 23 | sul (+Z) |
| Moinho | 39,6 / 0,025 / 1,925 | altura 16 | sul (+Z) |

As construções antigas eram fundidas à Golden Acres. `building_geometry.gd` prepara os polígonos de remoção da oficina e do celeiro e a elipse do moinho. O polígono da oficina inclui margem para a varanda antiga. O processamento rebaixa somente os vértices elevados dessas áreas, e os pisos recompostos cobrem as UVs das construções colapsadas. As colisões antigas deixam de formar paredes invisíveis. Os acessos às pedras próximas da oficina e do moinho são testados.

As amostras de preservação da vegetação originalmente incluíam uma pequena faixa do telhado do anexo do celeiro. As assinaturas atuais excluem as áreas das construções substituídas, comparando as plantas conservadas com o estado anterior `5757e28`. As assinaturas anteriores permanecem registradas em `farm_trees.json`; o processamento continua falhando caso plantas fora dessas áreas sejam alteradas.

Regenerar os recursos derivados com Godot 4.6.3:

```sh
godot --headless --editor --import --quit
godot --headless --script tools/bake_farm_fences.gd
godot --headless --script tests/integration.gd
```

As malhas otimizadas têm 31.416 triângulos (oficina), 62.758 (celeiro) e 62.726 (moinho). A simplificação mantém UVs e materiais; os modelos originais continuam disponíveis. Renderizações em terceira pessoa e vista aérea foram inspecionadas. Não houve medição de FPS em celular físico.

## Hélices em rotação lenta

O arquivo do moinho veio como uma malha única. O processamento separa seus triângulos em `windmill_static.res` (51.873 triângulos) e `windmill_rotor.res` (10.853), preservando materiais e UVs. A torre e a fachada permanecem na parte fixa; apenas as hélices e o cubo frontal giram. A soma das partes conserva todos os triângulos, sem deixar uma cópia estática das hélices sobreposta.

O pivô fica no centro do cubo, em `(0.0028, 0.6258, 0.285)` nas coordenadas originais do modelo, antes da escala. O giro acontece no eixo Z local, no sentido horário pela frente, a **3°/s (120 s por volta)**. A velocidade usa o tempo decorrido, e o ângulo é mantido dentro de uma volta para evitar acumulação. A torre e seu colisor são fixos; as hélices são uma animação visual independente. Menus, diálogo e pausa interrompem o giro, acompanhando a pausa do controlador e do ciclo do dia.

Inspeção de poses em 0 s, 15 s e 30 s confirmou que torre, porta e objetos na base não acompanham o movimento das hélices. Os testes verificam velocidade, ciclo completo, eixo fixo, pausa e conservação da geometria.

Capturas: [oficina](screenshots/new-workshop.png), [celeiro](screenshots/new-barn.png), [moinho](screenshots/new-windmill.png), [mapa](screenshots/new-buildings-map.png), hélices em [0 s](screenshots/windmill-rotation-start.png) e [15 s](screenshots/windmill-rotation-15s.png).
