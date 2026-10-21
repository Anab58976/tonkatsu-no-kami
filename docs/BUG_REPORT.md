# BUG_REPORT — Tonkatsu no Kami

Cada bug tem: evidência, causa (quando conhecida), estado e teste que protege a correção.

| # | Gravidade | Bug | Evidência | Causa | Estado | Proteção |
|---|---|---|---|---|---|---|
| 1 | Alta | Tremor de 1 px da Lulu na tela ao andar | 109 inversões de direção em 150 quadros | câmera atualizando no quadro de desenho e Lulu no passo de física | ✅ corrigido | teste "Câmera" (falha com o código antigo: 69 inversões; passa com 0) |
| 2 | Alta | NPCs com cabeça/chapéu/orelhas cortados | auditoria + capturas ampliadas | célula 32×32 pequena demais | ✅ corrigido (40×44) | `audit_pixels.py`: regra de corte (topo e laterais) |
| 3 | Média | Lulu nasce em cima da fonte da praça | captura | ponto de chegada atrás da fonte; o jato cobria os pés | ✅ corrigido | captura de verificação |
| 4 | Alta | Rótulos sobrepostos e cortados na tela de mapa | captura do menu Mapa | posições fixas sem detecção de colisão de rótulos | aberto → Marco 4 | — |
| 5 | Crítica (arte) | Lulu com 22 px, fora de escala com o mundo | auditoria | ver `PIXEL_ART_AUDIT.md` C1 | aberto → Marco 2 | `audit_pixels.py` (altura × padrão) |
| 6 | Crítica (arte) | Objetos com textura ruidosa (190/301) | auditoria | redução por média de área | aberto → Marco 1 | `audit_pixels.py` (ruído) |
| 7 | Média | Pés de inimigos terrestres variando no idle | auditoria | animação gerada com balanço | aberto → Marco 2/7 | `audit_pixels.py` |
| 8 | Baixa | Sem áudio | — | nenhum arquivo de som no projeto | aberto → Marco 8 | — |

Histórico anterior (já corrigidos e protegidos por testes): brechas de acesso ao templo da Cidade Fantasma, balsa de nuvem re-embarcando a Lulu, correntes de vento curtas demais, cais do lótus no vazio, teste de combate instável com acerto crítico. Detalhes nos commits e em `TEST_REPORT.md`.
