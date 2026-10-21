# ART_DIRECTION — Tonkatsu no Kami (padrão técnico do Tonkatsu Reborn)

Este documento é a **régua**. A ferramenta `tools/audit_pixels.py` verifica automaticamente o que dá para medir. Toda arte nova, seja da equipe ou do pipeline, segue estas regras.

## 1. Tela e renderização
- **Resolução lógica:** 640×360. Fica em escala inteira: ×2 = 1280×720, ×3 = 1920×1080. Nada de escala fracionária.
- `stretch/mode = viewport`, `scale_mode = integer`, snap de pixel ligado (transforms e vértices).
- **Filtragem:** nearest em tudo. Única exceção: a textura de luz suave (`light_soft.png`) usada por `PointLight2D`, que ilumina mas não é desenhada como sprite.
- **Importação:** PNG sem perda, sem mipmaps.
- **Câmera:** atualiza no **passo de física** (`CAMERA2D_PROCESS_PHYSICS`), com suavização 7. O teste "Câmera" exige 0 inversões ao andar em linha reta. Tremor de tela: no máximo 3 px e só em impactos.

## 2. Densidade de pixel e escala
- **1 pixel de arte = 1 pixel lógico.** Proibido escalar sprites no jogo (`scale` ≠ 1) para ganhar tamanho. Exceções: efeitos de partícula e o "squash" de animação de 1–2 px.
- **Tile = 32×32.**
- A arte da equipe chega em escalas diferentes por folha. Ela é **re-pixelizada para o tamanho-alvo**: grade detectada → mediana por bloco → paleta da região → contorno. Nunca por média de área (gera ruído).

### Tamanhos-alvo (altura visível, pés à cabeça)

| Categoria | Altura | Célula | Pés (origem) |
|---|---|---|---|
| Lulu porquinha (protagonista) | **36–44 px** (alvo 40) | 64×64 | (32, 60) |
| Lulu humana | 48–56 px | 64×64 | (32, 60) |
| NPC adulto | 36–52 px | 64×64 | (32, 60) |
| NPC criança / animal pequeno | 24–36 px | 48×48 | (24, 45) |
| Rei Porco | 64–72 px (é rei, propositalmente maior) | 96×96 | (48, 90) |
| Inimigo pequeno | 16–40 px | 48×48 | (24, 45) |
| Inimigo médio | 36–64 px | 64×64 ou 80×80 | base −4 |
| Chefe | 64–140 px | 128×128 ou maior | base −6 |

### Proporções do cenário em relação à Lulu (40 px)
- banco: 20–28 px de altura (assento na cintura)
- lanterna de pedra: 40–52 px
- porta: 44–52 px
- casa térrea: 96–128 px; sobrado: 128–170 px
- árvore média: 80–110 px

## 3. Contorno e luz
- **Contorno escuro** de 1 px em personagens, criaturas, itens e objetos interativos: cor `ink 2a1613`, ou a cor mais escura da paleta do material quando o contorno for "seletivo".
- Tiles de chão **sem contorno**.
- **Luz do alto, à esquerda.** Sombra no lado direito/baixo, realce em cima/esquerda.
- Sombra de personagem: elipse de pixels de 25% de alfa, desenhada pelo motor (nunca na arte).

## 4. Transparência
- Alfa **binário** (0 ou 255) em toda arte de sprite.
- Translucidez (fantasmas, asas, magia) é feita pelo motor (`modulate.a`), nunca com pixels semitransparentes na imagem.
- As únicas exceções aceitas pela auditoria são as animações de morte/coleta (`die`, `collect`, `morph`), cujo fade é intencional.

## 5. Paletas
- `resources/palettes/palettes.json` (prévia em `docs/img/palettes.png`).
- **Núcleo comum** (igual em todo o jogo): tinta, papel washi, madeira, laca vermelha, dourado e os rosas da Lulu. É isso que liga todas as regiões a uma identidade só.
- **Rampa da região**, extraída da arte da equipe para aquela região quando existe:

| Região | Fonte da rampa |
|---|---|
| HUB | `tiles_village_day.png` |
| Cidade Fantasma | `tiles_village_night.png` |
| Floresta Espiritual | `tiles_spirit_forest_a/b.png` |
| Reino dos Temperos | folha do Monstro Pimenta Coroado |
| Pântano, Céu, Arena | arte atual do jogo, até a equipe enviar referências |

- Personagens e itens usam o núcleo + a rampa da região onde vivem. Personagens que viajam (Lulu, Rei Porco) usam só o núcleo + a própria rampa.

## 6. Animação
- **Ritmo da animação** (fps do sprite) é independente do FPS do jogo: idle 4–6, caminhada 8–10, corrida 12, ataque 12–14.
- **Pés fixos**: em idle, a linha dos pés não pode variar (exceto criaturas que flutuam). Em caminhada, a variação máxima é 1 px (o "bob").
- **Centro fixo**: o personagem não pode deslizar mais de 2 px no idle.
- Nenhum quadro pode encostar no topo ou nas laterais da célula (seria corte).
- **Direções**: protagonista e NPCs em 4 direções. Esquerda pode ser o espelho da direita **só** se a arte for simétrica. Itens na mão trocam de mão no espelho: o utensílio é uma camada separada (Marco 5).

### Conjunto mínimo de animações
| Quem | Animações |
|---|---|
| Lulu | idle ×4 · caminhada ×4 · corrida ×4 · ataque leve ×4 · ataque pesado ×4 · esquiva ×4 · interação · dano ×4 · derrota · vitória |
| Inimigos | idle · movimento · ataque · dano · derrota (+ especiais) |
| NPCs | idle ×3 (frente, costas, lado) · caminhada ×3 · fala |

## 7. Interface
- Pixel art com fontes pixel sem antialiasing. Tamanhos permitidos: Pixelify 16 (texto), Silkscreen 8 (rótulos curtos).
- Moldura washi + madeira escura + detalhes em laca vermelha e dourado (já em `UiTheme.gd`).
- Ícones de item 16×16 com contorno. Ícones de minimapa 7×7.
- Layout completo e zonas da HUD: `docs/UI_DESIGN.md`.

## 8. Origem da arte e substituição
- A arte da equipe fica intacta em `assets/sprites/source/`.
- Sprites de jogo: `assets/sprites/generated/<id>/` (pipeline). Arte oficial vai em `assets/sprites/characters/<id>/` com `anims.json`, e o jogo passa a usá-la automaticamente.
- Nada gerado é declarado "definitivo": o inventário marca **gerado / equipe / equipe (derivado)**.
