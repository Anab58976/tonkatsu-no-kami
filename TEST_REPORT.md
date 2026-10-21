# TEST_REPORT — Tonkatsu no Kami

Última execução: 2026-10-19 · Godot 4.3 headless · `tools/run_tests.sh`

**Resultado: 123 verificações aprovadas, 0 falhas.**

## Testes automatizados (resultado real da última execução)

### Introdução — discurso oficial
- ✅ segmentos concatenados == texto oficial (sem alterações)
- ✅ começa com 'Rosta more.'
- ✅ termina com 'Agora, vá.'
- ✅ nomes possivelmente intencionais preservados (Lulul, Ton Katsunokami)
- ✅ seis regiões na ordem exigida

### Introdução — cena e pular
- ✅ Rei Porco e Lulu existem na cena
- ✅ personagens possuem animações reais
- ✅ portal e pergaminho existem
- ✅ transformação tem quadros intermediários (>=10)
- ✅ pular marca introdução como concluída
- ✅ pular atualiza forma de Lulu (porquinho)
- ✅ pular concede equipamento inicial
- ✅ pular inicia a missão principal
- ✅ pular encaminha para o HUB
- ✅ estado salvo após a introdução
- ✅ diálogo encerrado ao pular
- ✅ HUB carregado após pular
- ✅ controles restaurados no HUB

### Salvamento
- ✅ salvar no slot 9
- ✅ reset limpa o estado
- ✅ carregar slot 9
- ✅ moedas persistem
- ✅ inventário persiste
- ✅ flags (baús, cutscenes) persistem
- ✅ posição persiste
- ✅ nível persiste
- ✅ forma de Lulu persiste (não repete introdução)
- ✅ arquivo inválido é rejeitado sem travar
- ✅ estado atual intacto após falha de carga
- ✅ save antigo (sem versão) migra e mantém chaves novas

### Inventário e lojas
- ✅ não compra sem dinheiro suficiente
- ✅ nada muda em compra recusada
- ✅ compra com dinheiro suficiente
- ✅ moedas e inventário atualizados
- ✅ equipar arma comprada
- ✅ bônus de ataque da arma aplicado
- ✅ aprimoramento na forja aumenta o ataque
- ✅ não vende o último item equipado
- ✅ itens de missão não podem ser vendidos
- ✅ vender atualiza moedas e quantidade
- ✅ poção cura e é consumida
- ✅ relíquia aumenta a vida máxima
- ✅ seis lojas definidas
- ✅ todos os itens das lojas existem no banco de itens
- ✅ todos os itens têm ícone (0 faltando)

### Missões
- ✅ objetivo inicial: explorar a vila
- ✅ objetivo atualiza automaticamente para o Repolho
- ✅ ingrediente conta no progresso
- ✅ progresso não regride ao consumir o item
- ✅ missão secundária conclui e entrega recompensa
- ✅ missão 'main_six_ingredients' tem título e objetivos
- ✅ missão 'side_spirit_lanterns' tem título e objetivos
- ✅ missão 'side_takeshi_ore' tem título e objetivos

### Progressão e habilidades
- ✅ XP sobe de nível corretamente
- ✅ pontos de habilidade concedidos por nível
- ✅ aprender habilidade com pontos
- ✅ pré-requisito impede aprendizado
- ✅ habilidade de chefe começa bloqueada
- ✅ derrotar o Ogro desbloqueia Resistência ambiental
- ✅ resistência a terrenos venenosos ativa

### Combate
- ✅ ataque causa dano
- ✅ um golpe acerta só uma vez (sem dano duplicado)
- ✅ inimigo reage ao golpe (atordoado)
- ✅ inimigo morre com vida zerada
- ✅ derrotar inimigo concede XP
- ✅ contador de abates atualizado
- ✅ Lulu recebe dano
- ✅ invencibilidade após dano evita dano em sequência
- ✅ esquiva concede invencibilidade
- ✅ caranguejo: armadura frontal reduz o dano
- ✅ inimigo 'cogumelo' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'sapo_guerreiro' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'mosquito' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'planta_carnivora' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'espirito_lodo' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'caranguejo' tem animações idle/walk/attack/hurt/die
- ✅ inimigo 'golem_musgo' tem animações idle/walk/attack/hurt/die

### Dungeon 1 — Pântano (nível da água e caminhos)
- ✅ nível 2: caminho submerso coberto
- ✅ nível 2: templo submerso
- ✅ entrada → alavanca A alcançável
- ✅ canal bloqueia o centro no nível 2
- ✅ nível 1: caminho submerso aparece
- ✅ nível 1: roda da comporta alcançável
- ✅ nível 1: alavanca C (borda do templo) alcançável
- ✅ nível 1: baú do templo inalcançável
- ✅ nível 0: templo drenado
- ✅ nível 0: baú da chave alcançável
- ✅ ilha do guardião inalcançável sem jangadas
- ✅ nível 2 + comporta aberta: jangadas formam ponte
- ✅ da borda do templo → ilha do guardião (caminho principal completo)
- ✅ caminho alternativo 1 (baú secreto) alcançável
- ✅ caminho alternativo 2 (santuário/golem) alcançável
- ✅ chefe Ogro do Repolho presente
- ✅ pântano tem os 6 tipos de inimigos (+golem): sapo_guerreiro, mosquito, caranguejo, planta_carnivora, espirito_lodo, cogumelo, golem_musgo

### HUB — Vila do Rei Porco
- ✅ seis caminhos para as regiões
- ✅ portais distantes entre si (mín 768 px)
- ✅ vila povoada (17 NPCs)
- ✅ NPCs com rotinas de caminhada (14)
- ✅ praça → castelo alcançável
- ✅ praça → loja 'forja' alcançável
- ✅ praça → loja 'protecao' alcançável
- ✅ praça → loja 'caldeirao' alcançável
- ✅ praça → loja 'mil_sabores' alcançável
- ✅ praça → loja 'reliquias' alcançável
- ✅ praça → caminho de 'swamp' alcançável
- ✅ praça → caminho de 'ghost_city' alcançável
- ✅ praça → caminho de 'sky' alcançável
- ✅ praça → caminho de 'spirit_forest' alcançável
- ✅ praça → caminho de 'spice_kingdom' alcançável
- ✅ praça → caminho de 'arena' alcançável
- ✅ segredo da cachoeira alcançável

### Castelo e culinária
- ✅ castelo: trono alcançável
- ✅ castelo: biblioteca alcançável
- ✅ castelo: cozinha real alcançável
- ✅ castelo: sala de mapas alcançável
- ✅ castelo: treinamento alcançável
- ✅ castelo: recompensas alcançável
- ✅ receita 'onigiri' válida (3 etapas)
- ✅ receita 'missoshiru' válida (4 etapas)
- ✅ receita 'katsu_treino' válida (5 etapas)
- ✅ receita 'tonkatsu_no_kami' válida (8 etapas)
- ✅ Tonkatsu no Kami é um minigame de várias etapas
- ✅ avaliação de qualidade

## Erros encontrados e corrigidos durante o desenvolvimento
- **Ponte de jangadas incompleta** (Pântano): a busca de caminho com física mostrou que a coluna x=19 do canal continuava sendo água; a ilha do guardião era inalcançável. Corrigido (ponte com 5 colunas) e pontos de desembarque protegidos contra vegetação aleatória.
- **Executor de testes destruído ao pular a introdução**: a troca de cena liberava o próprio executor. Corrigido isolando o executor da cena atual.
- **Shader de água escurecendo a textura** (multiplicava a cor duas vezes) e **bordas brancas** (linhas de margem desenhadas com o shader). Corrigido.
- **Mudança de estado de física durante consultas** ao entrar na arena do chefe. Corrigido com `call_deferred`.
- **Progresso de missão regredindo** ao entregar/consumir itens. Agora o progresso é monotônico.
- **Texto de descrições ilegível** (RichTextLabel usava cor padrão branca). Corrigido no tema.

## Testes manuais/visuais executados (display virtual + capturas)
- Introdução completa a 4× de velocidade, do primeiro quadro até o HUB (≈ 3 min em tempo real): todas as 10 cenas, transformação, chegada e título conferidos por capturas.
- Menu de pausa: todas as abas abertas e navegadas por teclas simuladas.
- Loja (Forja do Dragão): entrar, falar, navegar, ver comparação e confirmação de compra.
- HUB e Pântano: vistas aéreas de todo o mapa; combate na entrada do pântano; apresentação e luta do chefe.
- Build exportado para Linux executado e capturado (HUB renderizando corretamente).

## Limitações dos testes
- Sem áudio no ambiente (driver dummy) e sem arquivos de áudio no projeto.
- Controle físico (gamepad) não testado; build Windows gerado mas não executado em Windows.
- A campanha completa (Novo Jogo → créditos) ainda não pode ser testada: dungeons 2–6 não existem.