# Cenário e HUD de fantasia

Implementado em Godot 4.6.3 / Compatibility, preservando a fazenda, os modelos
fornecidos, colisões, cultivos, animações, missão e formato do salvamento.

## Cenário

- O shader do terreno mantém a textura Emerald Meadow e a máscara dos caminhos,
  com nova paleta, variação em escalas diferentes e detalhe de cascalho.
- Tufos de grama e flores são malhas pequenas geradas uma vez, agrupadas por
  setores em MultiMeshes. Máximo de 7.200 tufos e 540 conjuntos de flores;
  descarte por distância a 55/65 unidades. Não acrescentam colisão.
- As posições excluem os caminhos, a casa, as construções e as plantações
  protegidas. A passagem da missão permanece livre.
- Luz solar mais neutra, ambiente azulado, névoa comum, duas camadas de relevo
  distante, nuvens simples e 38 partículas junto à árvore ancestral.
- O ciclo de dia/noite dura cerca de 27,8 minutos. A cor do céu/ambiente é
  atualizada por limiar para evitar recalcular o céu a cada frame.

## HUD baseado na referência escolhida

Molduras e ícones SVG próprios, tipografia Cinzel/Nunito (licenças OFL junto dos
arquivos), retrato renderizado a partir do modelo do protagonista e moldura
circular com folhas douradas. Os controles de toque usam molduras chanfradas,
ícones e legendas, com joystick dourado e resposta multitoque preservada.

O minimapa compartilha o World3D existente, com câmera ortogonal e atualização
máxima de duas vezes por segundo enquanto a jornada está ativa. Mostra posição
e orientação da câmera do jogador e abre a vista aérea quando acionado. A imagem
é recortada por shader circular; não é uma ilustração estática.

A barra do retrato mostra **etapas reais da missão (0–4)**. Os indicadores mostram
**pedras coletadas (0–3)** e **regiões abertas (1–2)**. O retrato se chama
“Explorador”: Lia continua sendo a guardiã/NPC. Não foram inventados níveis, XP,
vida ou saldos de moedas/gemas. O aviso na mochila aparece quando há itens reais.

A interface usa coordenadas da janela, com layout adaptável, em vez de ampliar
uma referência de 720×480. Menu de pausa com rolagem para janelas baixas.

## Capturas reais

Geradas pelo Godot Compatibility com renderização Mesa/llvmpipe. Não são imagens
geradas por IA nem promessa de paridade com o conceito cinematográfico.

### Cenário anterior

![Antes](screenshots/visual-before.png)

### Cenário revisado e HUD em desktop

![Desktop](screenshots/visual-hud-desktop.png)

### HUD no celular em pé

![Celular](screenshots/visual-hud-portrait.png)

## Validação

180 verificações de integração aprovadas, zero falhas. Incluem a missão até
abrir o portão, save/load, animações, acessos e colisões, joystick e segundo dedo,
vegetação fora dos acessos/cultivos e HUD/pausa em 1280×720, 390×844 e 844×390.
O minimapa compartilha o mundo real e os indicadores acompanham o estado real.

Exportações release Web e Windows geradas. O pacote Web é iniciado de fora do
projeto por `tests/export_smoke.gd`, verificando recursos, texturas e a missão.
O executável Windows não foi executado neste Linux. Não houve medição de FPS
em celular físico; MSAA, cobertura vegetal e minimapa acrescentam custo gráfico.

Para repetir as capturas em um desktop Linux com servidor gráfico:

```sh
DISPLAY=:99 godot --audio-driver Dummy --path . --script tools/capture_visuals.gd -- /tmp/eldervale-captures
```

Use `--hud-only --quick` após a pasta de saída para capturar só os três formatos
do HUD. A captura mantém o HUD funcional e mostra o mesmo cenário da jornada.

Modelos de maior qualidade, vegetação mais elaborada, novas animações e os três
poderes continuam sendo trabalho futuro. Nenhum desses elementos é apresentado
como concluído nesta revisão.
