# PIXEL_ART_AUDIT — Tonkatsu no Kami (Marco 0 do Tonkatsu Reborn)

Data: 2026-10-19 · Godot 4.3 · projeto em `pre-reborn-backup` (tag git) + `/home/claude/backups/tonkatsu_pre_reborn_*.tar.gz`

Como foi feito:
- **Ferramenta automática** `tools/audit_pixels.py`: analisa os 50 personagens/criaturas animados (todas as animações, quadro a quadro), 301 objetos e 100 tiles. Mede transparência parcial, fundo opaco, cortes na célula, deriva dos pés e do centro, altura visível × padrão, contorno e ruído de reamostragem. Resultado completo: `docs/ASSET_INVENTORY.md`.
- **Capturas reais** do jogo rodando (menu, introdução, HUB, menus de pausa, loja, 3 dungeons), inspecionadas uma a uma.
- **Medição de tremor de câmera** (posição da Lulu na tela, quadro a quadro, andando em linha reta).

Gravidade: **CRÍTICA** = quebra a direção de arte do jogo inteiro · **ALTA** = visível e frequente · **MÉDIA** = visível em situações específicas · **BAIXA** = acabamento.

---

## Configuração técnica (verificada)

| Item | Estado | Evidência |
|---|---|---|
| Resolução lógica | 640×360, `stretch=viewport`, escala **inteira** | `project.godot` |
| Filtragem | nearest por padrão (`default_texture_filter=0`) | `project.godot` |
| Snap de pixel | `snap_2d_transforms_to_pixel` e `vertices` ligados | `project.godot` |
| Importação de PNG | sem perda (`compress/mode=0`), sem mipmaps — 400/400 verificados | `*.png.import` |
| Fontes | pixel (Pixelify Sans, Silkscreen), sem antialiasing | `UiTheme.gd` |
| Tile | 32×32 | `GroundLayer.TILE` |
| Tilemap | desenho próprio por código (`GroundLayer`), não `TileMapLayer` | ver "Pendências de arquitetura" |

A base técnica está correta. Os problemas são de **conteúdo visual** e **escala**.

---

## CRÍTICA

### C1 — Escala da protagonista incompatível com o mundo
A Lulu porquinha tem **22 px** de altura visível (célula 48×48). Comparações 1:1:
- banco: 35 px
- lanterna de pedra: 51 px
- NPCs: 28–38 px
- Rei Porco: 69 px
- casa: 151 px

Ela ocupa menos de um tile e parece uma miniatura ao lado dos móveis (captura da praça: tem metade da altura do banco).
**Causa:** extraída da folha completa da equipe em ~25 px nativos, enquanto o cenário foi escalado para um personagem de ~40 px.
**Correção:** Marco 2, com nova altura-padrão de 36–44 px (ver `ART_DIRECTION.md`).

### C2 — Duas técnicas de pixelização convivendo
- **Personagens:** reconstruídos na grade de pixels da arte da equipe (mediana por bloco + contorno escuro limpo).
- **Objetos do cenário:** reduzidos por média de área (`build_tileset.py`, fator "tile da folha → 32 px").

Resultado: **190 de 301 objetos** têm textura ruidosa (>22% de pixels isolados) e 41 têm contorno fraco. Árvores e casas parecem "reamostradas", não desenhadas, e não combinam com os personagens.
**Correção:** Marco 1/3, re-pixelizar todos os objetos com o mesmo método dos personagens + contorno + paleta da região.

### C3 — Folhas da equipe em escalas diferentes entre si
As folhas enviadas (vila, floresta, personagens) foram desenhadas em escalas que não conversam: na grade nativa, uma casa da folha da vila ficaria **menor** que a Lulu da folha de personagem. Não existe "escala nativa comum".
**Decisão:** a densidade do jogo é definida por **tamanhos-alvo** (tabela em `ART_DIRECTION.md`), e toda arte é re-pixelizada para eles.

---

## ALTA

| # | Problema | Evidência | Estado |
|---|---|---|---|
| A1 | **Tremor de câmera de 1 px** ao andar: a posição da Lulu na tela invertia de direção 109 vezes em 150 quadros | câmera atualizava no quadro de desenho, Lulu no passo de física | ✅ **Corrigido** (câmera no passo de física → 0 inversões; teste "Câmera" na suíte) |
| A2 | **NPCs cortados**: célula 32×32; orelhas do Takeshi, chapéu da Yumi, elmo do guarda, orelhas da coelha cortados no topo | 13 NPCs encostavam na borda superior | ✅ **Corrigido** (célula 40×44 com folga; alturas reais 28–38 px) |
| A3 | **Lojas concentradas**: as 5 lojas enfileiradas numa única rua a leste; o resto da vila é grama com árvores espalhadas ao acaso | visão geral do HUB | Marco 3 |
| A4 | **Armas são espadas** (espada de bambu, katanas, lança…), contrariando a identidade culinária | `items.json`, HUD "Espada de bambu" | Marco 5 |
| A5 | **NPCs com o mesmo corpo-modelo** (só muda cor e cabeça) | `build_npcs.py` | Marco 2/3 |
| A6 | **Pixels semitransparentes** em sprites gerados fora das animações de morte (asas translúcidas) | ver `ASSET_INVENTORY.md` | Marco 2 (paleta + alfa binário) |
| A7 | **Tela de mapa**: rótulos sobrepostos ("Santuário"/"Praça"), "Floresta Espiritual" cortado na borda, mapa num quadrado pequeno | captura do menu Mapa | Marco 4 |
| A8 | **Sem minimapa**; HUD sem contador de poções nem rótulo de energia | capturas do HUB | Marcos 4 e 6 |

## MÉDIA

| # | Problema | Evidência | Estado |
|---|---|---|---|
| M1 | Lulu nascia **em cima da fonte** (o jato de água cobria os pés) | captura da praça | ✅ **Corrigido** (spawn ao sul da fonte) |
| M2 | Chefes da equipe pequenos para um chefe: Pégaso 54 px, Cisne 58 px, Rei Pimenta 56 px (padrão 64–140) | auditoria | Marco 7 (reconstrução em escala maior a partir das folhas originais em alta resolução) |
| M3 | Frames encostando na borda lateral/superior (possível corte) em inimigos gerados: dragão de vento, guardião do cemitério, marionete, samurai, guerreiro das nuvens | auditoria | Marco 2/7 |
| M4 | Pés variando 2–4 px no idle de inimigos terrestres (deslizam/pulam) | auditoria | Marco 2/7 |
| M5 | Mapas de dungeon gerados por código com bordas "em escada" (elipses de tiles), sem tiles de transição | capturas do Céu e do Pântano | Marco 1 (autotiling) / Marco 7 |
| M6 | Transição de biomas no HUB feita só por **tingimento de cor** dos tiles | `Hub.gd` (tint por distância) | Marco 3 |
| M7 | Ícones de item 16×16 desenhados por modelo (vários parecidos) | `build_icons.py` | Marco 5 |

## BAIXA

| # | Problema | Estado |
|---|---|---|
| B1 | 41 objetos com contorno fraco | Marco 3 |
| B2 | Cartões de nome de chefe/região com fonte pequena (8 px) no subtítulo | Marco 6 |
| B3 | Partículas de ponto (2×2) iguais em todas as regiões | Marco 8 |

---

## Pendências de arquitetura visual
- O chão é desenhado por um nó próprio (`GroundLayer`) e não por `TileMapLayer` + `TileSet`. Funciona, tem colisão e água animada, mas **não tem autotiling** (cantos e transições). Ir para `TileMapLayer` com terrenos é o caminho para transições suaves (Marco 1, prova de conceito no HUB, Marco 3).
- **Não há áudio** no projeto (o `AudioDirector` está pronto e toca qualquer arquivo colocado nas pastas). Marco 8.

## Limitação honesta sobre a meta "pixel art premium"
As referências pedidas (Sea of Stars, Eastward, CrossCode) são feitas por equipes de pixel artists desenhando à mão. Aqui, a arte vem de duas fontes:
1. as folhas que a equipe enviou, convertidas para a grade do jogo;
2. o que eu desenho com código.

Consigo garantir **consistência** (mesma densidade de pixel, contorno, paletas, alinhamento, animações completas) e um acabamento bom de jogo independente. Não posso prometer o nível de ilustração dessas referências. Todo o pipeline foi feito para que arte desenhada por um artista substitua a minha **sem mudar código** (`assets/sprites/characters/<id>/`). Os itens marcados "gerado" no inventário são candidatos a essa substituição.
