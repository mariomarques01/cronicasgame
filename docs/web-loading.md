# Carregamento web e memória

O erro do iOS “Um problema ocorreu repetidamente” indica que o processo da
página caiu; a mensagem, sozinha, não identifica a causa. O recarregamento pode
ser uma recuperação automática do navegador. É necessário confirmar no aparelho.

A inicialização carregava várias texturas 3D de 2048 px (algumas sem limite de
importação) e a cena original Golden Acres, cuja malha era imediatamente
substituída pela versão editada. Download comprimido não representa o consumo
de memória depois da decodificação e do envio para a GPU.

As texturas dos modelos agora usam `process/size_limit=1024`. Os arquivos-fonte
permanecem intactos, mas o detalhe das texturas importadas é menor, inclusive no
Windows. A fazenda instancia diretamente `farm_without_fences.res`, mantendo a
escala, a posição, os materiais e a construção da colisão. O GLB original continua
no projeto para edição, mas não faz parte dos pacotes exportados.

Validação local com Godot 4.6.3:

- `godot --headless --editor --import --quit`
- `godot --headless --script tests/integration.gd`: 124 verificações, zero falhas.
- Exportação Web release: pacote de aproximadamente 53 MiB, comparado a 146 MiB
  da versão publicada `2d9b5608`.
- `tests/export_smoke.gd` executado de fora do projeto contra o pacote exportado:
  inicialização, missão, recursos e orçamento de texturas aprovados.
- 28 texturas únicas nos materiais 3D: estimativa conservadora de 149,3 MiB em
  RGBA8 com mipmaps. Isso não mede a memória total do processo. O teste exige
  resolução máxima de 1024 px e orçamento de 192 MiB para esses materiais.

Após a publicação, abrir a raiz do site para receber o HTML da nova versão:
<https://mariomarques01.github.io/cronicasgame/>. Favoritos para HTML com hash
antigo continuam apontando para a versão antiga ou deixam de existir. Validar
no iPhone a abertura, o início da jornada, a movimentação e uma nova abertura.
