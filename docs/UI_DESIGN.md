# UI_DESIGN — Tonkatsu no Kami

Tela lógica 640×360 (×2 = 720p, ×3 = 1080p, sempre inteiro). Margem segura: 8 px.

## Estado atual (auditado)
| Elemento | Hoje | Problema |
|---|---|---|
| Vida | corações 8 px no canto superior esquerdo | pequenos; energia sem rótulo |
| Moeda | placa "Koban" no canto superior direito | ocupa o lugar previsto para o minimapa |
| Objetivo | caixa no canto superior direito | ok |
| Arma | placa no canto inferior esquerdo | mostra "Espada" |
| Poções | — | não existe |
| Minimapa | — | não existe |
| Mapa (pausa) | quadrado pequeno no centro | rótulos sobrepostos e cortados |

## Zonas da nova HUD (Marco 6)
Coordenadas em pixels lógicos. Nenhuma zona se sobrepõe a outra nem à caixa de diálogo (y ≥ 246).

```
┌────────────────────────────────────────────────────────────────┐
│ [VIDA ▮▮▮▮▮▮]            (centro livre)          ┌──────────┐ │ y 8
│ [ENERGIA ◆◆◆◆]                                  │ MINIMAPA │ │
│ ¥ 550 Ryō                                        │  96×72   │ │
│                                                  └──────────┘ │ y 84
│                                                  ┌──────────┐ │
│                                                  │ OBJETIVO │ │ y 88–120
│                                                  └──────────┘ │
│                                                               │
│ ┌──────┐┌────┐                                                │
│ │UTENS.││POÇÃO│                                               │ y 316–352
│ └──────┘└────┘                                                │
└────────────────────────────────────────────────────────────────┘
```

| Zona | Retângulo (x, y, w, h) | Conteúdo |
|---|---|---|
| Vida | 8, 8, 140, 14 | barra laqueada vermelha com moldura de bambu; números na barra |
| Energia | 8, 24, 100, 8 | contas de jade |
| Ryō | 8, 36, 90, 12 | moeda + valor |
| Minimapa | 536, 8, 96, 72 | moldura de madeira e papel |
| Objetivo | 448, 88, 184, 32 | título da missão + progresso ("1/3"); some ao concluir |
| Utensílio | 8, 316, 44, 36 | ícone 16×16 ampliado ×2 + nível |
| Poções | 56, 316, 36, 36 | ícone + quantidade |
| Toasts | centro, y 60 | avisos curtos, um de cada vez |
| Diálogo | 20, 262, 600, 90 | (existente) |

## Minimapa (Marco 4)
- Desenhado a partir do próprio mapa (tiles agregados em blocos de 4×4), na paleta da região.
- **Marcadores registrados pelos próprios nós** (`MapMarker`): loja, portal, NPC importante, missão. Se uma loja muda de lugar, o marcador acompanha. Nenhuma coordenada fica fixa em outro script.
- **Ícones 7×7:**

| Ícone | Para |
|---|---|
| panela | oficina culinária |
| saco | mercador |
| frasco | alquimista |
| folha | curandeira |
| boneco | treino |
| torii | portal |
| "!" | missão |
| seta | jogador, girando conforme a direção |

- Zoom em 2 níveis.
- Seta na borda apontando para o objetivo quando ele está fora da área.

## Tela de mapa (Marco 4)
- O mapa ocupa a área útil inteira, com moldura de pergaminho.
- **Rótulos sem colisão**: posicionados por prioridade e deslocados até não encostarem em nada. Os que não cabem viram só ícone, com o nome ao passar o cursor.
- Selecionar um destino cria a marca do objetivo, que aparece também no minimapa.

## Estilo
- Papel washi `f3e7cf` · madeira `5c3a28` · tinta `2a1613` · laca `a3252e` · dourado `f0be3c`.
- Botões com estados normal, hover (laca), foco (borda dourada) e pressionado (madeira escura).
- Fontes: Pixelify Sans 16 e Silkscreen 8. Nunca menor que 8 px. Nunca fonte com antialiasing.
