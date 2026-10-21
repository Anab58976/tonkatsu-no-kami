# CUTSCENE_PRODUCTION — Introdução

Implementação: `scripts/cinematics/IntroDirector.gd` (cena `scenes/intro/IntroCutscene.tscn`)
+ `scripts/cinematics/HubArrival.gd` (chegada ao HUB e título, dentro do HUB real).

## Texto-fonte
`resources/cutscenes/intro_speech.json` guarda o discurso oficial (§5) **exatamente** como fornecido e a sua divisão em 28 falas. Um teste automático garante que a concatenação das falas é idêntica ao texto oficial. "Rosta more", "Ton Katsunokami" e "Lulul" foram preservados (podem ser intencionais).

## Gravação de voz
Nenhuma gravação foi fornecida. Quando houver:
1. Coloque o arquivo em `assets/audio/voice/intro_rei_porco.ogg` e preencha `voice_file`.
2. Preencha `start`/`end` (segundos) de cada segmento após ouvir a gravação. **Não** foi inventada nenhuma marcação.
3. Registre divergências de pronúncia entre áudio e texto antes de alterar legendas.
Até lá, cada fala avança pelo ritmo natural de leitura (digitação a 30 caracteres/s + pausa proporcional ao tamanho) ou pelo jogador.

## Roteiro implementado (por cena)
| Cena | Ação | Câmera / luz |
|---|---|---|
| 1 Cozinha | Lulu mexe a panela (vapor), serve o prato, prova, fica desapontada; batida na porta; porta de shoji desliza; Rei Porco surge na penumbra e caminha | plano aberto → push-in em Lulu → panorâmica até a porta → segue o rei; luz quente → levemente dramática |
| 2 Desastre | Rei inspeciona, inclina a cabeça, cruza os braços, aponta; Lulu constrangida (suor) | cortes alternados, pausas cômicas |
| 3 Determinação | Rei suaviza (olhos felizes, sobrancelhas suaves); Lulu ergue o olhar com esperança | luz quente, música de esperança |
| 4 Rei do tonkatsu | Braços abertos, coroa brilha, aura dourada (PointLight + partículas) | push-in lento e grandioso |
| 5 Mundo mágico | Pergaminho flutua, desenrola; mapa com as 6 regiões surgindo uma a uma (animadas) | sobe para o pergaminho |
| 6 Transformação anunciada | Lulu surpresa, olha as mãos; rei aponta; círculo mágico se forma no chão; portal dourado se abre | panorâmica até o portal |
| 7 Seis regiões | Seis cartões animados na ordem exigida (água com ondulações, névoa, lanternas, nuvens e relâmpago, vagalumes, bandeiras, multidão), cada um com o guardião | sobreposição com fundo escurecido |
| 8 Missão | Seis ingredientes orbitam o prato lendário; cozinha banhada em dourado | — |
| 9 Aviso | Rei olha diretamente; close extremo; portal intensifica; música misteriosa | luz arroxeada |
| 10 Despedida | Rei estende o braço; Lulu olha para ele, caminha até o portal, olha para trás; rei acena; Lulu atravessa (estica, brilha, some) | segue Lulu; flash |
| Transformação | Espaço mágico procedural (vazio violeta, fitas de energia, partículas, brasões); Lulu flutua; vórtice; **morph em 15 quadros** (silhueta humana brilha → encolhe → orelhas e focinho → porquinha), interpolando campos de distância entre a arte humana e a arte porquinha da equipe; explosão dourada controlada | zoom in no centro |
| Chegada | Lulu cai suavemente na praça, se levanta, olha as patas, salto de surpresa, gira duas vezes (!, ?) | zoom 3× → 1× revelando a vila |
| Título | Faixa laqueada, logotipo cai com bounce, explosão de pétalas de sakura; HUD aparece gradualmente; controle devolvido | — |

## Pular
Segure Esc/Start por 0,8 s (barra de progresso). Pular aborta diálogos, aplica exatamente o mesmo estado final da cutscene completa (`Game.apply_intro_completion`: forma porquinha, kit inicial, flag, missão principal, save) e carrega o HUB com controles ativos. Coberto por testes.

## Arte usada
Lulu humana e porquinha: arte da equipe (folhas de referência convertidas). Rei Porco, cozinha, portal, espaço mágico, cartões, logotipo: gerados/procedurais (temporários, substituíveis).
