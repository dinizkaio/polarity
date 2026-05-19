# Polaridade — Especificação de Design

**Documento de briefing para design de jogo mobile**
**Versão:** 1.1
**Plataforma:** Flutter (Android + iOS)
**Autor do conceito:** Kaio (Session Flow)

---

## 1. Pitch em uma frase

**Polaridade** é um jogo de tabuleiro abstrato 1×1 (jogador vs IA) onde peças magnetizadas se atraem e se repelem, e o objetivo é empurrar as peças do adversário pra fora do tabuleiro através de reações em cadeia provocadas por jogadas mínimas.

## 2. Posicionamento estratégico

- **Gênero:** estratégia abstrata casual / puzzle
- **Duração de partida:** 1 a 3 minutos
- **Modo:** single-player vs IA (3 níveis de dificuldade previstos)
- **Público-alvo:** casual+ — jogadores que curtem xadrez/damas/2048 mas não querem aprender regras por 30 minutos
- **Monetização:** anúncios intersticiais entre partidas + rewarded video opcional (dica do mestre / desfazer)
- **Restrição de orçamento:** projeto de baixo custo, sem backend, sem multiplayer online
- **Diferencial competitivo:** mecânica de reação em cadeia visualmente espetacular em partida de 90 segundos

---

## 3. Regras completas do jogo

### 3.1 Configuração inicial

- Tabuleiro quadrado **5×5** (25 casas), todas vazias no início.
- Dois jogadores: **Jogador** (humano) e **IA**.
- Cada jogador tem um **estoque** de **6 peças** fora do tabuleiro.
- Cada peça tem uma **polaridade** visível: positiva (⊕) ou negativa (⊖). A polaridade é escolhida no momento em que a peça é colocada.
- Visual: peças do humano são de uma cor, da IA de outra cor (ver seção 6). A polaridade é distinguida por um símbolo dentro da peça, não apenas por cor.

### 3.2 Estrutura de turno

O Jogador joga primeiro. A cada turno, o jogador da vez faz **exatamente uma** das duas ações:

**Ação A — Colocar peça.** Pega uma peça do estoque, escolhe sua polaridade (⊕ ou ⊖) e a coloca em qualquer casa vazia do tabuleiro.

**Ação B — Girar polaridade.** Escolhe uma peça sua já no tabuleiro e inverte sua polaridade (⊕ vira ⊖, ou vice-versa). A peça permanece na mesma casa.

A peça que sofreu a ação (recém-colocada ou recém-girada) é chamada de **epicentro** do turno.

### 3.3 Reação magnética (o núcleo do jogo)

Imediatamente após o epicentro ser determinado, ele exerce força magnética sobre os 8 vizinhos (4 ortogonais + 4 diagonais). A reação é **onda única** — só os 8 vizinhos do epicentro reagem; as peças que se movem por reação **não** geram novas ondas.

**Para cada um dos 8 vizinhos, na ordem fixa: N → NE → E → SE → S → SW → W → NW** (sentido horário começando no Norte), aplica-se:

- Se a casa vizinha está vazia → nada acontece.
- Se há peça vizinha de **polaridade oposta** ao epicentro → **atração**: a peça é puxada 1 casa em direção ao epicentro.
- Se há peça vizinha de **polaridade igual** ao epicentro → **repulsão**: a peça é empurrada 1 casa pra longe do epicentro (direção oposta à direção entre epicentro e vizinho).

### 3.4 Resolução dos movimentos (casos)

**Atração — casa destino vazia:** peça se move normalmente.

**Atração — casa destino ocupada (por qualquer peça, inclusive o próprio epicentro):** atração **bloqueia**. A peça não se move. (Casos típicos: peças adjacentes ao epicentro, onde o destino da puxada *é* a casa do epicentro.)

**Repulsão — casa destino vazia:** peça se move normalmente.

**Repulsão — casa destino ocupada:** **cadeia de empurrão**. A peça bloqueadora também é empurrada na mesma direção. Se a próxima casa também estiver ocupada, a cadeia continua. Qualquer peça da cadeia que seja empurrada **pra fora do tabuleiro é removida permanentemente** (do dono dela). A cadeia para quando uma peça encontra casa vazia ou todas saem.

**Repulsão — peça empurrada saindo do tabuleiro:** peça é removida permanentemente. Não retorna ao estoque, não pontua, simplesmente some.

**Importante:** o epicentro **nunca se move**. Ele é a fonte da força, não sujeito a ela.

### 3.5 Tabela-resumo dos casos

| Situação | Resultado |
|---|---|
| Repulsão, casa destino vazia | Peça move 1 casa pra longe do epicentro |
| Repulsão, casa destino ocupada | Cadeia: bloqueadora também empurrada na mesma direção |
| Repulsão, peça empurrada pra fora do tabuleiro | Removida permanentemente (peça destruída) |
| Atração, casa destino vazia | Peça move 1 casa em direção ao epicentro |
| Atração, casa destino ocupada (inclusive epicentro) | Bloqueia — peça não move |
| Casa vizinha vazia | Nada acontece |

### 3.6 Vantagem de quem começa

Regra do "pie": o Jogador faz a primeira jogada; a IA pode então decidir trocar de lado (passar a controlar as peças do Jogador) ou continuar como segundo a jogar. Decisão da IA é baseada na avaliação heurística da primeira jogada do Jogador. *(Nota de design: esse comportamento da IA pode ser invisível pro jogador casual — apresentar apenas o resultado.)*

### 3.7 Condições de vitória

**Vitória imediata:** adversário fica sem peças no tabuleiro **e** sem peças no estoque.

**Vitória por pontos (após 20 ações totais — 10 por jogador):** quem tem mais peças no tabuleiro vence. Em caso de empate, vence quem jogou em segundo (compensação pela regra do "pie").

A partida termina **assim que uma das condições acima é satisfeita**.

---

## 4. Direções temáticas (3 opções pra design escolher)

A mecânica é abstrata, mas precisa de um tema forte pra identidade visual, marketing e ASO. Sugiro três direções coerentes com a mecânica. **Recomendação:** direção C (cosmos).

### 4.1 Direção A — Laboratório / Física

**Conceito:** peças são ímãs reais, vistos de cima. Linhas de campo magnético desenhadas sutilmente entre peças. Tabuleiro é uma mesa de laboratório.

- Paleta: vermelho (⊕) e azul (⊖) clássicos de física, fundo cinza-claro ou branco.
- Tipografia: técnica, mono ou sans-serif geométrica (tipo IBM Plex Mono).
- Mood: limpo, científico, didático.
- Som: zumbidos magnéticos, cliques metálicos.

**Prós:** mais barato de produzir; conceito instantaneamente legível. **Contras:** menos apelo emocional, thumbnail menos chamativa na loja.

### 4.2 Direção B — Alquimia / Misticismo

**Conceito:** peças são símbolos alquímicos (Sol ☉ / Lua ☾, ou Ouro/Mercúrio). Tabuleiro é uma mesa de pedra entalhada ou pergaminho velho. Reações magnéticas são "transmutações".

- Paleta: ouro e prata sobre fundo terroso ou negro profundo.
- Tipografia: serifada antiga (tipo Cormorant ou Cardo).
- Mood: misterioso, ocultista mas elegante.
- Som: tons de cristal, sinos baixos.

**Prós:** identidade visual forte e diferente do mainstream. **Contras:** "alquimia" pode soar nicho; risco de parecer pseudo-religioso e afastar parte do público.

### 4.3 Direção C — Cosmos / Gravidade *(recomendada)*

**Conceito:** peças são estrelas/corpos celestes. Polaridade representa gravidade (atração) e energia escura (repulsão). Reações em cadeia são colisões cósmicas. Peças empurradas pra fora do tabuleiro "caem no vazio".

- Paleta: roxo profundo e azul-marinho de fundo; peças em branco-quente (⊕) e ciano-frio (⊖); partículas brilhantes na borda das peças.
- Tipografia: sans-serif moderna com personalidade (tipo Space Grotesk ou Manrope).
- Mood: contemplativo, vasto, com momentos de impacto.
- Som: drones espaciais ambientes, impactos com reverb longo, "swoosh" pra movimentação.

**Prós:** apelo visual máximo (thumbnail brilhante na Play Store); animações de cadeia ficam espetaculares com partículas; tema universal sem ofender ninguém; permite skins futuras (galáxias diferentes como cosmético opcional). **Contras:** mais animação = mais trabalho de polimento; partículas exigem cuidado pra não destruir performance em celulares baratos.

---

## 5. Arquitetura de telas

```
┌──────────────────────────────────────────────┐
│  SPLASH (2-3s, logo + tagline)               │
└───────────────────┬──────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  MENU PRINCIPAL                              │
│  • Jogar                                     │
│  • Como jogar                                │
│  • Configurações                             │
│  • Sobre / créditos                          │
└───────────────────┬──────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  SELEÇÃO DE DIFICULDADE                      │
│  • Aprendiz / Adepto / Mestre                │
└───────────────────┬──────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  TELA DE JOGO  (núcleo do produto)           │
└───────────────────┬──────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  FIM DE PARTIDA (resultado + 2 CTAs)         │
│  • Nova partida → roda intersticial          │
│  • Menu                                      │
└──────────────────────────────────────────────┘

(Modais auxiliares: pausa, confirmação de saída, dica via rewarded ad)
```

### 5.1 Splash

Logo do jogo + tagline curta (ex.: "Polaridade — gravidade em duelo"). Duração 2-3s, transição suave pro menu. Pré-carrega assets críticos do tabuleiro nesse tempo.

### 5.2 Menu principal

Layout vertical centralizado. Botão **Jogar** dominante (CTA principal). Pode ter peças cósmicas flutuando no fundo como decoração viva e leve. Atenção: nenhuma animação de fundo deve consumir mais que ~3% de CPU em celulares de entrada.

### 5.3 Seleção de dificuldade

3 cards horizontais, cada um com um nome temático e descrição curta:
- **Aprendiz** — IA olha 1 jogada à frente
- **Adepto** — IA olha 2 jogadas à frente
- **Mestre** — IA olha 3+ jogadas à frente

### 5.4 Tela de jogo

Esta é a tela mais importante. Detalhamento completo na seção 6.

### 5.5 Fim de partida

Modal grande no centro: resultado ("Vitória" / "Derrota" / "Empate"), peças remanescentes de cada lado, número de turnos. Dois CTAs: **Nova partida** (botão primário, dispara intersticial antes de voltar pra tela de jogo) e **Voltar ao menu** (botão secundário, também dispara intersticial). Botão terciário pequeno: **Compartilhar resultado** (gera card visual da partida).

### 5.6 Tutorial / Como jogar

Tutorial obrigatório na primeira execução (pode ser pulado). Formato: 4-5 telas com animações curtas mostrando: colocação, polaridade, atração, repulsão, vitória. Após o tutorial, oferecer **primeira partida em modo treino** (sem custo de derrota — não afeta estatísticas).

### 5.7 Configurações

- Som (on/off + volume)
- Vibração (on/off)
- Tema visual (se houver alternativas)
- Idioma (PT / EN / ES — padrão do Session Flow do Kaio)
- Sobre / Privacidade / Termos

---

## 6. Tela de jogo — detalhamento completo

### 6.1 Layout (orientação retrato, dimensões aproximadas com base em viewport 360×800)

```
┌──────────────────────────────────────┐
│  [≡]  Polaridade        Turno 4/20   │  ← Header (h ~56px)
├──────────────────────────────────────┤
│                                      │
│   IA                                 │  ← Bandeja superior
│   Estoque: ● ● ● ●                   │     (~80px)
│   No tabuleiro: 2                    │
│                                      │
├──────────────────────────────────────┤
│                                      │
│                                      │
│          ┌─┬─┬─┬─┬─┐                 │
│          │ │ │ │ │ │                 │
│          ├─┼─┼─┼─┼─┤                 │
│          │ │⊕│ │ │ │                 │  ← Tabuleiro
│          ├─┼─┼─┼─┼─┤                 │     (quadrado,
│          │ │ │⊖│ │ │                 │      ~340×340)
│          ├─┼─┼─┼─┼─┤                 │
│          │ │ │ │ │ │                 │
│          ├─┼─┼─┼─┼─┤                 │
│          │ │ │ │ │ │                 │
│          └─┴─┴─┴─┴─┘                 │
│                                      │
├──────────────────────────────────────┤
│   VOCÊ                               │  ← Bandeja inferior
│   Estoque: ● ● ● ● ●                  │     (~80px)
│   No tabuleiro: 1                    │
├──────────────────────────────────────┤
│                                      │
│   [ ⊕ ]  Colocar  [ ⊖ ]              │  ← Barra de ação
│                                      │     (~100px)
│   [ Girar peça selecionada ]         │
└──────────────────────────────────────┘
```

### 6.2 Componentes da tela de jogo

**Header (topo, ~56px):**
- Botão hamburger esquerdo (abre menu lateral: pausar, abandonar, configurações)
- Título "Polaridade" centralizado
- Indicador de turno à direita: "Turno X/20" — fica vermelho/destacado nos últimos 3 turnos

**Bandeja superior — IA:**
- Avatar/ícone da IA (sutil, pode ser uma "estrela" se cosmos)
- Contador de estoque visual: 6 pontos que vão sumindo conforme peças são usadas
- Contador "No tabuleiro: N"
- Quando é turno da IA: anel pulsante ao redor da bandeja + texto "Pensando..." abaixo do contador

**Tabuleiro (núcleo):**
- Quadrado, sempre centralizado horizontalmente
- 5×5 casas. Cada casa ~60-68px com 2-4px de gap
- Casas vazias: leve borda sutil, fundo levemente diferenciado do bg da tela
- Casa selecionada (mostrando que jogador tocou ali): glow sutil + escala 1.05
- Casa onde uma peça será colocada (após escolher polaridade): preview translúcido da peça

**Bandeja inferior — Jogador:**
- Espelho da bandeja superior, mas destacado
- Quando é turno do jogador: ligeira animação de "respiração" pra indicar vez

**Barra de ação:**
- Quando jogador está colocando peça: 2 botões grandes lado a lado mostrando ⊕ e ⊖, cada um com a cor do jogador. Toque seleciona polaridade, depois jogador toca em casa vazia pro placement.
- Quando jogador tem peça sua selecionada no tabuleiro: aparece botão "Girar polaridade" abaixo, mostrando preview de "⊕ → ⊖" ou "⊖ → ⊕".
- Estado de "aguardando IA": barra de ação fica esmaecida.

### 6.3 Anatomia da peça

Cada peça é um disco circular com:
- **Cor de base** indicando dono (Jogador / IA)
- **Símbolo central** indicando polaridade (⊕ ou ⊖)
- **Halo/aura** sutil ao redor, na cor da polaridade (não do dono)
- **Tamanho:** ~80% da casa, deixando respiração visual

Estados visuais da peça:
- Normal
- Selecionada (pulsando suavemente)
- Epicentro do turno (forte brilho temporário)
- Em movimento (com trail)
- Sendo destruída (fade + partículas pra fora)

**Importante para acessibilidade:** a polaridade **nunca** deve ser distinguida apenas por cor. Sempre use forma + símbolo + cor combinados. Veja seção 9.

### 6.4 Indicações visuais durante seleção

Quando o jogador seleciona uma peça sua no tabuleiro (preparando uma rotação), mostrar **as 8 casas vizinhas com prévia da reação**: setas sutis indicando direção do empurrão (peças iguais) ou da atração (peças opostas), considerando se a polaridade fosse invertida. Isso é uma decisão de design — torna o jogo mais palatável pra iniciantes; designers podem propor versão sem essa ajuda pra modo "Mestre".

Quando o jogador seleciona uma casa vazia + uma polaridade pra colocar, mostrar **prévia das reações** que ocorreriam: peças vizinhas com seta indicando pra onde se moverão. Permite "planejar" antes de confirmar.

Toque longo na peça do oponente: mostra sua polaridade em destaque (caso o jogador esteja se confundindo). Não é jogada — é consulta.

---

## 7. Animações críticas — especificação detalhada

A qualidade das animações é o diferencial entre "jogo amador" e "jogo premium". Detalhamento por sequência:

### 7.1 Colocação de peça

**Duração total:** ~400ms

1. Peça materializa do estoque (escala 0 → 1, fade in, ~150ms, easing out-back)
2. Peça "assenta" na casa (leve pulse de escala, ~80ms)
3. **Início da onda magnética** (ver 7.3)

### 7.2 Giro de polaridade

**Duração total:** ~450ms

1. Peça rotaciona em torno do eixo Y por 180° (~250ms, easing out)
2. No meio da rotação, símbolo central troca (⊕ ↔ ⊖) e cor do halo transita
3. Flash branco no centro ao terminar a rotação (~50ms)
4. **Início da onda magnética** (ver 7.3)

### 7.3 Onda magnética (sequência mais importante do jogo)

A onda é resolvida na ordem fixa **N → NE → E → SE → S → SW → W → NW**. Cada vizinho reage em sequência, com um pequeno delay entre eles pra criar sensação de cascata.

**Por vizinho, duração ~180-220ms:**

1. **Indicação da força (~60ms):** linha de força emerge do epicentro até o vizinho. Cor da linha: branca pra atração, vermelha quente pra repulsão. Linha desaparece após chegar no vizinho.
2. **Reação da peça vizinha (~120-160ms):**
   - **Atração com sucesso:** peça desliza 1 casa em direção ao epicentro (easing ease-out)
   - **Atração bloqueada:** peça "trepida" levemente no lugar (shake ~6px de amplitude, 2 ciclos)
   - **Repulsão sem cadeia:** peça desliza 1 casa pra longe
   - **Repulsão com cadeia:** peça 1 + peça 2 (+ peça 3, etc) deslizam juntas, ligeiramente atrasadas entre si (~40ms de stagger)
   - **Peça empurrada pra fora do tabuleiro:** desliza pra fora + fade + explosão de partículas + "blip" sonoro
3. **Pequeno delay (~60ms)** antes do próximo vizinho reagir

**Duração total da onda completa (pior caso, 8 reações):** ~1.8 segundos. Aceitável e satisfatório se bem coreografado. Considerar opção de "animações rápidas" nas configurações pra jogadores experientes (reduz timing pra ~50%).

### 7.4 Captura / destruição de peça

Quando uma peça é empurrada pra fora do tabuleiro:

1. Peça continua o movimento pra fora da grade visual
2. Ao cruzar a borda do tabuleiro, peça começa a se desfazer: partículas se desprendem
3. Fade out total em ~300ms
4. Decremento visual do contador "no tabuleiro" do dono da peça
5. Som: impacto + dissolução (depende do tema escolhido)

### 7.5 Fim de partida

1. Última animação resolve normalmente
2. Pausa dramática (~600ms)
3. Tabuleiro escurece levemente
4. Modal de fim de partida entra (slide up + fade, ~400ms)
5. Resultado pulsa uma vez ao aparecer
6. Botões aparecem com leve stagger (~100ms entre eles)

### 7.6 Turno da IA — feedback de "pensando"

Durante o cálculo da IA (até 1s nos níveis mais altos):
- Anel pulsante na bandeja superior
- Texto "Pensando..." ou variação temática ("Calculando trajetória...", "Avaliando o cosmos...")
- Se cálculo passar de 800ms, mostrar barra de progresso sutil

Quando IA decide a jogada:
- Pequeno highlight no destino (~200ms antes da peça aparecer/girar)
- Mesma sequência de animação que o jogador (não favorecer visualmente nenhum lado)

---

## 8. Som e haptics

### 8.1 SFX necessários

- **Tap em casa do tabuleiro** (curto, sutil)
- **Seleção de polaridade** (dois timbres distintos pra ⊕ e ⊖ — uma oitava de diferença)
- **Colocação de peça** (impacto suave + reverb)
- **Giro de polaridade** (whoosh + click)
- **Linha de força — atração** (tom ascendente curto)
- **Linha de força — repulsão** (tom descendente curto)
- **Peça se movendo** (slide / sussurro)
- **Peça empurrada pra fora** (impacto + dissolução, é o "ka-pow" do jogo)
- **Cadeia em sequência** (cada peça da cadeia gera um tick, pitch sobe a cada peça)
- **Vitória** (acorde maior, ~2s)
- **Derrota** (acorde menor com resolução, ~2s)
- **Empate** (acorde neutro)

### 8.2 Música ambiente

Loop ambient de 2-3 minutos, bem leve, sem percussão forte. Volume baixo por padrão. Deve "sumir" mentalmente durante o jogo.

### 8.3 Haptics (Android + iOS)

- Tap em casa: haptic feedback leve (`HapticFeedback.selectionClick`)
- Colocação de peça: medium (`HapticFeedback.mediumImpact`)
- Captura de peça inimiga: heavy (`HapticFeedback.heavyImpact`)
- Vitória: pattern customizado (3 pulses)

---

## 9. Acessibilidade — prioritário

**Polaridade não pode depender só de cor pra ser jogável.** Aproximadamente 8% dos homens têm alguma forma de daltonismo, e diferenciar duas polaridades é o ato fundamental do jogo.

Requisitos:

1. **Símbolo sempre presente:** ⊕ e ⊖ visíveis em **todas** as peças, em todos os tamanhos. Nunca remover símbolo "pra ficar mais bonito".
2. **Cor + forma da peça:** se possível, peças do Jogador e da IA têm também **formas levemente distintas** (ex.: borda mais grossa, ou pequeno padrão interno) além da cor.
3. **Modo daltônico nas configurações:** alterna paletas pra combinações testadas (azul/laranja, ao invés de azul/vermelho).
4. **Tamanho de toque:** casa do tabuleiro mínimo 44×44 pontos em qualquer dispositivo (recomendação Apple HIG).
5. **Reduzir movimento (opção):** alternativa pra jogadores sensíveis a animação — reduz cascatas e remove partículas, mantém só o essencial.
6. **Legibilidade dos contadores:** numeração grande, contraste alto.

---

## 10. Estados de UI e fluxos auxiliares

### 10.1 Pausa

Acessível pelo botão hamburger no header. Modal escuro com opções: **Continuar**, **Reiniciar partida**, **Abandonar (volta ao menu)**. Abandonar conta como derrota nas estatísticas.

### 10.2 Confirmação de saída

Se o jogador pressiona "voltar" do sistema durante partida: dialog "Sair sem terminar? Sua partida será perdida." Sim/Não.

### 10.3 Rewarded ad — Dica do mestre

Em qualquer turno do jogador, botão pequeno discreto perto da barra de ação: "Dica" com ícone de play. Toque abre dialog: "Assista um vídeo curto pra ver a jogada que a IA Mestre faria agora". Após assistir, mostra a jogada sugerida com highlight no tabuleiro por ~3 segundos.

### 10.4 Rewarded ad — Desfazer

Após uma jogada ruim, jogador pode tocar em "Desfazer" (aparece por 3 segundos após cada jogada). Abre dialog: "Assista um vídeo pra desfazer sua última jogada". Uso limitado a 1 desfazer por partida.

### 10.5 Intersticial

Toca **após** o modal de fim de partida ser fechado pelo botão "Nova partida" ou "Menu". Frequência: máximo 1 a cada 2 partidas (evitar fatiga). Configurar cap diário razoável.

---

## 11. Telemetria mínima sugerida

Pra ajustar balance da IA e identificar problemas de design:

- Taxa de vitória do jogador por nível de dificuldade
- Duração média de partida
- Número médio de turnos por partida
- Taxa de uso de "Girar" vs "Colocar"
- Quantas peças sobrevivem em média ao final
- Taxa de abandono (partidas iniciadas vs finalizadas)
- Pontos de saída do funil (menu, dificuldade, primeira jogada, etc)

---

## 12. Resumo executivo pro designer

Você está desenhando um jogo de tabuleiro abstrato 5×5 com mecânica de polaridade magnética. A experiência principal é: **jogada simples → reação espetacular em cadeia → satisfação**. Cada partida dura 1-3 minutos, então cada segundo de tela conta.

**O que precisa estar polido até a perfeição:**
1. A animação da onda magnética (seção 7.3) — é o "produto" que o usuário compra
2. A clareza da polaridade das peças (seção 9) — sem isso, o jogo é injogável
3. O loop de fim de partida → nova partida (rápido, sem fricção)

**O que pode ser mais simples sem problema:**
- Menu principal (basta ser limpo)
- Tutorial (4-5 telas estáticas com animação curta resolvem)
- Configurações (lista padrão)

**Direção temática recomendada:** Cosmos / Gravidade (seção 4.3) — pelo apelo visual em loja, pela coerência com a mecânica (gravidade ↔ atração) e pela escalabilidade de skins futuras.

**Diretriz final:** o jogo precisa ser **belo em screenshots estáticos** (importante pra ASO) e **espetacular em vídeos de 15 segundos** (importante pra ads pagos e crescimento orgânico). Cada decisão visual deve considerar essas duas superfícies.

---

## 13. Localização e strings

O jogo será lançado em três idiomas: **Português (Brasil)**, **Inglês** e **Espanhol**. Diretrizes pro design considerar desde o início:

### 13.1 Implicações pro design

- **Comprimento variável:** PT e ES são tipicamente 15-30% mais longos que EN. Botões, labels e tooltips precisam respirar sem quebrar layout em nenhum dos três idiomas. Evitar containers de largura fixa pra textos.
- **Caracteres acentuados:** as fontes escolhidas devem ter suporte completo a Latin Extended (ã, õ, ç, á, é, í, ó, ú, ñ, ¿, ¡). Verificar previamente em Space Grotesk, Manrope ou alternativas.
- **Hierarquia visual idêntica:** o layout deve funcionar igualmente bem nos 3 idiomas. Nada de "fica bonito em inglês e quebra em português".
- **Detecção e troca de idioma:** sugestão de detectar idioma do sistema na primeira execução, com seletor explícito em Configurações pra trocar a qualquer momento.

### 13.2 Nome do jogo

| Idioma | Nome | Notas |
|---|---|---|
| PT | **Polaridade** | Reconhecível, sem ambiguidade |
| EN | **Polarity** | Termo direto, ótimo pra busca em ASO |
| ES | **Polaridad** | Direto, paridade visual com PT |

Os três nomes são quase idênticos — bom pra recall internacional e pra ASO (mesmas keywords core).

### 13.3 Tagline (proposta de trabalho, refinar depois)

| Idioma | Tagline |
|---|---|
| PT | Atração, repulsão, vitória |
| EN | Attract. Repel. Win. |
| ES | Atrae, repele, vence |

### 13.4 Glossário de termos do jogo

Termos consistentes nos 3 idiomas, pra usar em tutorial, tooltips, dicas e textos da loja:

| Conceito | PT | EN | ES |
|---|---|---|---|
| Polaridade | Polaridade | Polarity | Polaridad |
| Tabuleiro | Tabuleiro | Board | Tablero |
| Peça | Peça | Piece | Pieza |
| Estoque (peças fora do tabuleiro) | Estoque | Stock | Reserva |
| Epicentro | Epicentro | Epicenter | Epicentro |
| Atração | Atração | Attraction | Atracción |
| Repulsão | Repulsão | Repulsion | Repulsión |
| Onda magnética | Onda magnética | Magnetic wave | Onda magnética |
| Cadeia (de empurrão) | Cadeia | Chain | Cadena |
| Turno | Turno | Turn | Turno |
| Colocar peça | Colocar | Place | Colocar |
| Girar polaridade | Girar polaridade | Flip polarity | Girar polaridad |
| Vitória | Vitória | Victory | Victoria |
| Derrota | Derrota | Defeat | Derrota |
| Empate | Empate | Draw | Empate |

### 13.5 Níveis de dificuldade

| PT | EN | ES |
|---|---|---|
| Aprendiz | Apprentice | Aprendiz |
| Adepto | Adept | Adepto |
| Mestre | Master | Maestro |

### 13.6 Strings de UI principais

Strings verbatim pra uso direto em design e implementação. Placeholders entre `{}` são substituídos em runtime.

| Contexto | PT | EN | ES |
|---|---|---|---|
| Menu — botão principal | Jogar | Play | Jugar |
| Menu — secundário | Como jogar | How to play | Cómo jugar |
| Menu — terciário | Configurações | Settings | Ajustes |
| Menu — sobre | Sobre | About | Acerca de |
| Seleção de dificuldade — título | Escolha a dificuldade | Choose difficulty | Elige la dificultad |
| Tela de jogo — header | Turno {n}/{total} | Turn {n}/{total} | Turno {n}/{total} |
| Tela de jogo — vez do jogador | Sua vez | Your turn | Tu turno |
| Tela de jogo — vez da IA | Pensando… | Thinking… | Pensando… |
| Tela de jogo — ação colocar | Colocar | Place | Colocar |
| Tela de jogo — ação girar | Girar polaridade | Flip polarity | Girar polaridad |
| Tela de jogo — selecionar polaridade | Escolha a polaridade | Choose polarity | Elige la polaridad |
| Tela de jogo — dica (rewarded) | Dica | Hint | Pista |
| Tela de jogo — desfazer (rewarded) | Desfazer | Undo | Deshacer |
| Estoque (label) | Estoque: {n} | Stock: {n} | Reserva: {n} |
| No tabuleiro (label) | No tabuleiro: {n} | On board: {n} | En el tablero: {n} |
| Fim — vitória | Vitória | Victory | Victoria |
| Fim — derrota | Derrota | Defeat | Derrota |
| Fim — empate | Empate | Draw | Empate |
| Fim — CTA principal | Nova partida | New game | Nueva partida |
| Fim — CTA secundário | Menu | Menu | Menú |
| Fim — compartilhar | Compartilhar | Share | Compartir |
| Pausa — título | Pausado | Paused | En pausa |
| Pausa — continuar | Continuar | Resume | Continuar |
| Pausa — reiniciar | Reiniciar partida | Restart game | Reiniciar partida |
| Pausa — abandonar | Abandonar | Quit | Abandonar |
| Confirmação saída — título | Sair sem terminar? | Quit without finishing? | ¿Salir sin terminar? |
| Confirmação saída — corpo | Sua partida será perdida. | Your game will be lost. | Tu partida se perderá. |
| Confirmação saída — sim | Sair | Quit | Salir |
| Confirmação saída — não | Continuar jogando | Keep playing | Seguir jugando |
| Rewarded ad — dica (corpo) | Assista um vídeo curto para ver a jogada que o Mestre faria agora. | Watch a short video to see the move the Master would make now. | Mira un video corto para ver la jugada que el Maestro haría ahora. |
| Rewarded ad — undo (corpo) | Assista um vídeo curto para desfazer sua última jogada. | Watch a short video to undo your last move. | Mira un video corto para deshacer tu última jugada. |
| Rewarded — assistir | Assistir | Watch | Mirar |
| Rewarded — agora não | Agora não | Not now | Ahora no |
| Configurações — som | Som | Sound | Sonido |
| Configurações — vibração | Vibração | Vibration | Vibración |
| Configurações — idioma | Idioma | Language | Idioma |
| Configurações — animação reduzida | Animação reduzida | Reduced motion | Animación reducida |
| Configurações — modo daltônico | Modo daltônico | Colorblind mode | Modo daltónico |

Strings de tutorial, descrição da loja e marketing serão entregues em momento posterior pelo Kaio, no mesmo padrão verbatim PT/EN/ES.

### 13.7 Notas pro Genspark (implementação técnica)

- Estrutura recomendada: arquivos JSON `assets/i18n/pt.json`, `en.json`, `es.json`, ou `.arb` se usar `flutter_localizations` nativo.
- Toda string em UI deve passar por função de tradução. **Não hardcodar texto em widgets.**
- Pluralização: o jogo usa "{n} peças no tabuleiro" — usar formas plurais corretas (`Intl.plural` no Flutter).
- Datas e números no idioma do dispositivo (não é crítico aqui, mas vale a regra).

---

*Fim do documento.*
