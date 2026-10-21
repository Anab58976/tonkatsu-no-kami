# GAME_DESIGN_DOCUMENT — Tonkatsu no Kami

## Premissa
Lulu, uma jovem cozinheira, falha pela sétima vez no tonkatsu. O Rei Porco, guardião do prato perfeito, vê nela algo que nenhuma receita ensina — ela não desiste — e a envia ao mundo mágico, transformada em porquinha, para recuperar seis ingredientes lendários guardados por seis guardiões. Só então poderá preparar o Tonkatsu no Kami e voltar a ser quem é.

## Pilares
1. **Exploração de um mundo vivo** — vila que reage e evolui; nada de "seis portais lado a lado".
2. **Combate de ação legível** — ataques telegrafados, esquiva com invencibilidade, chefes com fases.
3. **Culinária como mecânica central** — minigames de várias etapas cuja qualidade importa.
4. **Fantasia japonesa coerente** — torii, shoji, noren, jizō, komainu, sakura, kamado, lanternas; sem símbolos aleatórios.

## Controles
WASD/setas mover · Shift correr · Espaço esquivar · J/clique atacar (segure: carregado) · K/clique-dir. habilidade · Q trocar habilidade · E interagir · I inventário · M mapa · Esc pausa. Controle suportado; teclas remapeáveis.

## Estrutura do mundo
- **Vila do Rei Porco (HUB)**: praça (estátua, fonte, santuário de salvamento/viagem), castelo ao norte (trono, biblioteca, mapas, cozinha real, treino, recompensas), rua comercial a leste (5 lojas + mercador viajante na praça), bairro residencial e campos a oeste, jardim espiritual a sudeste (lago, ponte vermelha, cachoeira com segredo), campo de treinamento a sudoeste. Seis estradas saem em seis direções com transição gradual de cor/objetos para cada bioma.
- **Regiões**: Pântano (SO) · Cidade Fantasma (O) · Céu (N) · Floresta (NE) · Reino dos Temperos (L) · Arena (S).

## Dungeons (mecânica única cada)
| # | Região | Mecânica | Chefe | Ingrediente | Habilidade |
|---|---|---|---|---|---|
| 1 | Pântano dos Esquecidos | Nível da água (3 níveis): alavancas, roda, caminho submerso, templo afundado, jangadas | Ogro do Repolho (golpes lentos → raízes → ataques rápidos + arena venenosa) | Repolho Místico | Resistência ambiental |
| 2 | Cidade Fantasma | Mundo físico × espiritual: pontes espirituais, portas invisíveis | Samurai das Mil Almas (esquiva e contra-ataque) | Trigo Espectral | Visão Espiritual |
| 3 | Reino dos Céus | Correntes de vento, plataformas móveis, elevadores | Guardião da Tempestade | Arroz Celestial | Impulso Celestial |
| 4 | Floresta Espiritual | Restaurar santuários, raízes, puzzles de luz | Unicórnio Ancestral (purificado) | Carne Encantada | Manipulação de Raízes |
| 5 | Reino dos Temperos | Combinação de habilidades anteriores | Rei Pimenta-Negra | Pimenta-Negra Imperial | Infusão Elemental |
| 6 | Arena dos Deuses | Torneio em 7 rodadas | Ganso Dourado | Ovo Dourado | — |

## Progressão
- Nível por XP (inimigos/chefes): +1 coração a cada 2 níveis, ataque e energia fracionados, 1 ponto de habilidade por nível.
- Árvores: Combate (golpe giratório, ataque carregado+, esquiva aprimorada, contra-ataque, combos, dano elemental), Exploração (habilidades dos chefes + detecção de segredos), Culinária (receitas avançadas, bônus de refeições, preparação, aproveitamento, utensílios).
- Equipamento: 8 armas (espada/lança/martelo/adagas/mágicas) com aprimoramento +1..+3 na forja, 7 armaduras, relíquias, cosméticos.

## Economia
Koban por inimigos, baús, missões, segredos, treino e venda (50% do valor). Itens de missão nunca vendáveis. Estoque de lojas cresce com o progresso (flags de chefes); o mercador viajante alterna metade do estoque.

## Culinária
Etapas: separar ingredientes → cortar (timing) → ritmo (moldar/moer) → empanar (ordem correta) → fritar (manter temperatura na faixa) → descansar (precisão) → montar (direções). Nota final: Desastre / Comestível / Bom / Ótimo / Perfeito (Perfeito rende porção dupla). Utensílios e habilidades alargam as janelas. A missão final usa a receita de 8 etapas do Tonkatsu no Kami.

## Narrativa por NPC
Moradores comentam conquistas (ex.: o Ogro derrotado), têm rotinas de caminhada e missões (Takeshi: minério; Espírito Kaeru: lanternas espirituais).

## Final (planejado)
Lulu entrega o prato ao Rei Porco → close, surpresa e alegria → aura dourada, ingredientes brilham → transformação inversa (mesmo motor de morph da introdução, ao contrário) → celebração da vila → créditos → pós-jogo (revanches na arena, receitas especiais, colecionáveis).
