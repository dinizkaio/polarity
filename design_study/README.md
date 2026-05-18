# Handoff: Polaridade

Jogo mobile 1×1 (jogador vs IA) de tabuleiro abstrato 5×5 onde peças magnetizadas se atraem e se repelem em reações em cadeia. Plataforma-alvo: **Flutter (Android + iOS)**.

---

## Sobre os arquivos deste pacote

Os arquivos `.html` / `.jsx` / `.css` / `.js` neste bundle são **referências de design construídas em HTML/React** — protótipos que demonstram o look-and-feel pretendido e o comportamento esperado. Eles **não são código de produção** pra copiar diretamente.

A tarefa do dev é **recriar esses designs em Flutter** (a stack-alvo do projeto), seguindo os padrões idiomáticos do Flutter (widgets, providers/Riverpod/Bloc, AnimationController, etc.) — não portar JS/React linha a linha.

A `polaridade_design_spec.md` na raiz deste bundle é a **especificação canônica do jogo** (regras, mecânica, monetização, telas, animações, acessibilidade, localização). O design HTML é uma materialização visual dela. Em caso de conflito, a spec prevalece.

## Fidelidade

**Hi-fi.** Cores, tipografia, espaçamentos, raios, animações e interações estão finalizados. Reproduzir 1-pra-1 dentro das possibilidades do Flutter (algumas técnicas web — `backdrop-filter`, `oklch()`, gradientes radiais complexos — têm equivalentes diretos em Flutter via `BackdropFilter`, `Color.fromARGB`, `RadialGradient`).

---

## Direção visual: Cosmos / Gravidade

Tema escolhido conforme recomendação da spec (seção 4.3). Peças = corpos celestes; polaridade = gravidade (atração) vs energia escura (repulsão); peças destruídas "caem no vazio".

- **Mood:** contemplativo e vasto, com momentos de impacto
- **Backdrop:** navy/violeta profundo com nuvem de estrelas estáticas + nebulosas radiais sutis (blur ~40px)
- **Sem partículas custosas:** mantenha animação a ≤ 3% CPU em devices de entrada (spec restriction)

---

## Design tokens

### Cores (todos os valores exatos)

| Token | Valor | Uso |
|---|---|---|
| `bg-void` | `#06061a` | Fundo absoluto, vazio entre nebulosas |
| `bg-deep` | `#0a0a24` | Fundo base de telas |
| `bg-mid` | `#15103a` | Camada média (cards de dificuldade) |
| `bg-soft` | `#1f1a4a` | Camada elevada |
| `player` | `#FFEBC2` | Cor base das peças do jogador (branco-quente) |
| `ai` | `#7EE8FA` | Cor base das peças da IA (ciano-frio) |
| `plus` (halo ⊕) | `oklch(0.82 0.16 70)` ≈ `#F5C46B` | Halo dourado das peças positivas |
| `minus` (halo ⊖) | `oklch(0.70 0.20 295)` ≈ `#A271DC` | Halo violeta das peças negativas |
| `ink` | `#F5F2FF` | Texto primário |
| `ink-2` | `#B8B2D9` | Texto secundário |
| `ink-3` | `#6B6498` | Texto terciário / eyebrow / mono |
| `ink-4` | `#3D375E` | Texto desativado |
| `line` | `rgba(255,255,255,0.08)` | Bordas sutis |
| `line-strong` | `rgba(255,255,255,0.15)` | Bordas destacadas |

### Gradientes-chave

- **Peça jogador:** `radial-gradient(circle at 35% 30%, #FFFEF5 0%, #FFEBC2 50%, #E8C988 100%)` com sombra interna `inset 0 -2px 6px rgba(120,80,30,0.3)`
- **Peça IA:** mesmo gradiente em ciano (`#C9F8FF → #7EE8FA → #3DA9C7`) + **anel duplo interno** pra acessibilidade (1.5px branco + 3px navy escuro)
- **Halo da peça:** `radial-gradient(circle, <halo-color> 0%, transparent 60%)` com `filter: blur(6px); opacity: 0.8`. Estende 22% além da peça.
- **Backdrop cósmico:** múltiplos `radial-gradient` (nebulosas violeta/rosa) sobrepostos em `linear-gradient(180deg, #08081f, #100a2c, #060616)`.
- **Estrelas:** ~12 pontos brancos/dourados/ciano de 1-1.5px posicionados aleatoriamente. Em Flutter: `CustomPainter` desenhando pontos com `Paint..maskFilter`.

### Tipografia

3 famílias Google Fonts. Todas têm suporte a Latin Extended (PT/EN/ES).

| Token | Família | Pesos | Uso |
|---|---|---|---|
| `font-display` | **Space Grotesk** | 400/500/600/700 | Títulos, valores grandes, headers |
| `font-ui` | **Manrope** | 400/500/600/700 | Corpo, botões, labels de UI |
| `font-mono` | **JetBrains Mono** | 400/500/600 | Eyebrows, números, contadores, "TURNO 04/20" |

### Escala tipográfica

| Token | Tamanho | Peso | Letter-spacing | Uso |
|---|---|---|---|---|
| Display XL | 44px | 500 | -0.02em | Splash title, EndGame title |
| Display L | 36px | 500 | -0.02em | Menu title |
| H1 | 28px | 500 | -0.02em | "Escolha a dificuldade", "Ajustes" |
| H2 | 20-22px | 500-600 | -0.01em | Card titles |
| Body | 14-15px | 400 | normal | Descrições |
| UI button | 16px | 600 | 0.01em | Botões primários |
| Eyebrow | 11px | 500 | 0.18em UPPERCASE | "TURNO 04/20", "PASSO 01 DE 1" |
| Mono small | 10-11px | 500 | 0.1-0.12em | Contadores, etiquetas |

### Espaçamento, raios e sombras

- **Stack gap:** 4 · 8 · 12 · 16 · 20 · 24 · 28 · 32
- **Padding de página:** 20-28
- **Raios:** Cell 12 · Board 22 · Modal 28 · Botão pill 999 · Tray 18 · Card 16-20
- **Sombras de peça:** `0 4px 12px rgba(0,0,0,0.3)` (drop) + `inset 0 -2px 6px rgba(120,80,30,0.3)` (depth) + `inset 0 2px 4px rgba(255,255,255,0.6)` (highlight)
- **Glow do botão primário:** `0 4px 16px oklch(0.85 0.10 70 / 0.4)`

---

## Anatomia da peça

Toda peça é um **disco circular** composto por 4 camadas (de fundo pra frente):

1. **Halo** — radial-gradient na cor da polaridade, blur 6px, expande 22% pra fora. Cor por polaridade (não por dono): dourado pra ⊕, violeta pra ⊖.
2. **Corpo (base)** — disc de 78% do tamanho da casa. Cor por dono:
   - **Jogador:** branco-quente com gradiente radial
   - **IA:** ciano com gradiente radial **+ anel duplo interno** (acessibilidade — diferencia donos sem depender só de cor)
3. **Highlight especular** — radial-gradient branco translúcido no canto superior-esquerdo (30% 25%), simula iluminação cósmica
4. **Símbolo** — `⊕` ou `⊖` no centro, Space Grotesk 600, cor escura sobre a peça (#4a2e0a no jogador, #0a2530 na IA) com text-shadow sutil. **NUNCA remover símbolo** — é o vetor de acessibilidade obrigatório.

### Estados visuais

| Estado | Efeito |
|---|---|
| Normal | Base |
| Selecionada | `transform: scale(1.08)` em pulso 1.4s ease-in-out infinito |
| Epicentro | `transform: scale(1.18) brightness(1.6)` por 600ms, depois volta |
| Em movimento | Translate via transition 0.3s cubic-bezier(0.3,1.3,0.5,1). Stagger de 40ms por peça na cadeia. |
| Destruindo | Translate além da grade + `scale(0.2)` + `opacity:0` + `blur(8px)` em 500ms |

---

## Telas (arquitetura)

Fluxo: **Splash → Menu → Dificuldade → Jogo → Fim de partida**. Modais auxiliares: Pausa, Tutorial, Ajustes, Confirmação de saída, Rewarded ad.

### 1. Splash (2-3s)

- Backdrop cósmico + nebulosas (orbs roxas/rosas blur 40px)
- Logo: duas peças (jogador ⊕ + IA ⊖) orbitando ao redor de um glow central
  - Animação: `transform: rotate(0→360deg)` 8s linear infinite no container
  - Glow central: `radial-gradient → blur(8px) → scale(0.9↔1.2)` 2s ease-in-out infinite
- Título "Polaridade" — Space Grotesk 44px 500, gradiente branco→dourado
- Tagline "GRAVIDADE EM DUELO" — mono 11px 0.25em
- Dots de loading (3 dots staggered 0.2s)
- Pre-carrega assets críticos durante os 2-3s

### 2. Menu principal

- Mesmo backdrop com peças decorativas flutuando (4 peças em posições absolutas, `transform: translateY(-12px) rotate(10deg)` 6s ease-in-out infinite com delays diferentes)
- Logo orbital (versão menor, 92px)
- Hierarquia de botões:
  - **Primário "Jogar"** — pill 60px altura, gradiente branco→dourado, com ícone ▶
  - **Secundários "Como jogar" / "Ajustes"** — pill ghost (rgba white 0.06, blur)
  - **Terciário "SOBRE · v0.1"** — texto mono, sem fundo

### 3. Seleção de dificuldade

- 3 cards verticais com:
  - Avatar circular 56×56 (gradiente radial com glow externo) + glyph (◔ / ◑ / ●)
  - Nome (display 19px 600) + duração à direita (mono 10px: "1 JOGADA À FRENTE")
  - Descrição (body 13px)
  - Cada nível tem **hue distinta** pra hierarquia visual: 200 / 280 / 340 (azul → roxo → magenta)
  - Background do card: `linear-gradient(135deg, oklch(0.22 0.12 <hue> / 0.5), oklch(0.12 0.08 <hue> / 0.3))`

### 4. Tela de jogo (a mais importante)

Layout vertical (de cima pra baixo):

```
[Header — 56px]                    ← hamburger · POLARIDADE · TURNO 04/20
[Tray da IA — ~80px]               ← avatar · nome · contador · 6 dots de estoque
[Board — quadrado, ~340×340]       ← 5×5 cells em grid
[Tray do jogador — ~80px]
[Barra de ação — ~110px]           ← contextual ao estado
```

**Header:**
- Botão hamburger esquerdo (44×44 ghost circle) → abre modal de pausa
- Título "POLARIDADE" + linha mono "TURNO N/10" abaixo (10 turnos × 2 ações = 20 ações totais)
- Nos últimos 2-3 turnos, o número fica `oklch(0.78 0.20 30)` (laranja-quente) pra criticality

**Trays (jogador / IA):**
- Background ghost rounded 18px
- Quando ativo (vez do jogador): variante `bg: oklch(0.4 0.18 290 / 0.12)` + animação "respiração" 2.4s (box-shadow pulsando)
- Avatar 36×36 com gradiente
- Nome (UI 13px 600) à esquerda; "N no tabuleiro" mono à direita
- 6 dots circulares 12×12 — cor cheia se peça disponível, ring se gasto
- Quando IA pensa: substituir "N no tabuleiro" por "PENSANDO…"

**Board:**
- Container 22px rounded com gradiente radial + shadow inset
- 5×5 grid, gap 4px, padding 6px
- Cells 12px rounded, fundo `rgba(white, 0.025)`, hover `0.06`
- Cell "targetable" (durante seleção de polaridade): `bg: oklch(0.4 0.18 290 / 0.15)` + outline violeta

**Barra de ação (estados):**

| Estado | UI |
|---|---|
| Idle (sua vez) | Texto centralizado: "Sua vez" eyebrow + instrução + 2 chips ghost "DICA" e "DESFAZER" (rewarded ads) |
| Escolhendo polaridade (após tocar casa vazia) | Eyebrow "ESCOLHA A POLARIDADE" + 2 botões grandes lado a lado (⊕ Positivo dourado / ⊖ Negativo violeta). Selecionado: `transform: scale(1.04)` + glow forte |
| Peça selecionada (própria peça) | Eyebrow "PEÇA SELECIONADA" + botão grande "⊖ → ⊕ Girar polaridade" mostrando o swap |
| Vez da IA | Texto esmaecido "VEZ DA IA" + barra de progresso animada (loading bar slide) |
| Animando | Texto esmaecido "REAÇÃO MAGNÉTICA" |

### 5. Fim de partida (modal)

- Backdrop preto 70% + `backdrop-filter: blur(8px)`
- Modal 28px rounded, gradiente navy, sombra grande + glow externo violeta (`0 0 120px oklch(0.5 0.18 290 / 0.2)`)
- Eyebrow "FIM DE PARTIDA"
- Título 44px 600 — cor varia: dourado pra Vitória (com text-shadow glow), ink neutro pra Empate, laranja pra Derrota
- Tagline poética ("O cosmos pendeu pro seu lado.")
- 3 stat boxes lado a lado: VOCÊ · TURNOS · IA — número grande 26px 600
- 3 botões: **Nova partida** (primário) · **Menu** (ghost) · **COMPARTILHAR RESULTADO** (mono link)
- Animação de entrada: fade-in 0.3s no backdrop + `translateY(20px) scale(0.95) → 0 / 1` 0.4s cubic-bezier(0.34,1.56,0.64,1)

### 6. Tutorial (4-5 passos)

- Header com ← e PULAR (mono)
- Barra de progresso de 5 segmentos (segmentos preenchidos = dourado, vazios = white 0.1)
- Demo board mini (5×5 estático, 280px max width) ilustrando o conceito
- Textos: eyebrow numerado · título display 26px · body 15px · botão "Próximo" primário (último: "Jogar minha primeira partida")
- Conteúdo dos 5 passos: Colocação · Atração · Repulsão · Destruição · Vitória

### 7. Configurações (lista padrão)

- Grupos: Jogabilidade · Som e vibração · Idioma · Sobre
- Linhas com toggle iOS-style (gradiente violeta on / cinza off, glow quando on)
- Selects mostram valor + chevron
- Links pra Privacidade / Termos / Créditos

### 8. Modais auxiliares

- **Pausa:** mesmo estilo do EndGame mas menor. Botões: Continuar / Reiniciar partida / Abandonar (laranja)
- **Confirmação de saída:** title + corpo + Sim/Não
- **Rewarded ad dialog (Dica / Desfazer):** texto explicando o reward + Assistir / Agora não

---

## Mecânica e animações críticas

### Resolução da onda magnética (núcleo do jogo — seção 7.3 da spec)

Quando uma peça vira **epicentro** (recém-colocada ou recém-girada):

1. Epicentro flasha com `scale(1.18) brightness(1.6)` por 600ms
2. Para cada um dos 8 vizinhos na **ordem fixa N→NE→E→SE→S→SW→W→NW**:
   - Linha de força desenha do epicentro até o vizinho:
     - **Atração** (polaridades opostas): linha branca-dourada (`linear-gradient(transparent, #FFEBC2, #FFFFFF)`) + glow `0 0 8px #FFEBC2`, 220ms total
     - **Repulsão** (polaridades iguais): linha laranja-quente + glow, 220ms
   - Vizinho reage:
     - **Atração com sucesso** → desliza 1 casa em direção ao epicentro (300ms cubic-bezier(0.3,1.3,0.5,1))
     - **Atração bloqueada** (destino ocupado, tipicamente pelo próprio epicentro) → shake horizontal 6px amplitude 2 ciclos, 200ms
     - **Repulsão sem cadeia** → desliza 1 casa pra fora
     - **Repulsão com cadeia** → todas as peças da cadeia deslizam juntas com stagger de 40ms entre elas
     - **Peça empurrada pra fora** → continua o movimento além da grade, fade out + blur + scale(0.2), 500ms
3. **Pequeno delay de 60ms** entre cada vizinho — cria sensação de cascata
4. Duração total no pior caso (8 reações): ~1.8s

**Importante:** epicentro nunca se move. Só os 8 vizinhos do epicentro reagem (onda única, sem propagação).

### Toda lógica de regras está em `game-logic.js`

A função `applyAction(state, action)` retorna `{ newState, animation: [...steps] }` onde cada step é um evento da animação (`place`, `flip`, `epicenter`, `force`, `move`, `destroy`, `shake`, `end`). **Use isso como referência canônica da resolução** — incluindo a ordem dos vizinhos, o tratamento de cadeias, e a checagem de fim de partida (incluindo o desempate por regra do "pie": vitória da IA em empate).

### Outras animações

- **Colocação de peça:** scale 0→1 + fade-in 150ms ease-out-back, settle pulse 80ms — total ~400ms antes da onda
- **Giro de polaridade:** rotate-Y 180° 250ms, troca de símbolo + halo no meio da rotação, flash branco 50ms — total ~450ms
- **AI thinking:** 700-1200ms aleatório, anel violeta pulsando no tray + texto "Pensando…"

---

## Acessibilidade (prioritário — seção 9 da spec)

1. **Polaridade NUNCA depende só de cor.** Símbolo ⊕/⊖ sempre visível em todos os tamanhos.
2. **Forma de peça também distingue donos** — IA tem anel duplo interno (não confunde com a peça do jogador mesmo em b/w).
3. **Modo daltônico** (toggle em Ajustes): troca paleta pra azul/laranja em vez de azul/vermelho/violeta.
4. **Hit targets ≥ 44×44pt** (Apple HIG). Cells do board são ~60×60pt — OK.
5. **Modo "Animação reduzida"** (toggle em Ajustes): remove partículas, reduz cascatas, mantém só o essencial.
6. **Contraste**: contadores grandes, alto contraste sobre fundos escuros.

---

## Localização (seção 13 da spec)

Três idiomas: **PT-BR · EN · ES**. Tabela completa de strings na spec, seção 13.4-13.6. Pontos críticos pro design:

- PT e ES são **15-30% mais longos** que EN — botões e labels precisam respirar (evitar largura fixa pra textos)
- Detectar idioma do sistema na primeira execução, com seletor em Ajustes
- Estrutura: `assets/i18n/pt.json`, `en.json`, `es.json` (ou `.arb` se `flutter_localizations` nativo)
- Pluralização via `Intl.plural`

---

## Tracking / telemetria mínima

Vide seção 11 da spec. Eventos sugeridos:

- `match_started` (difficulty)
- `match_ended` (result, turns, pieces_remaining_player, pieces_remaining_ai, duration_ms)
- `action_taken` (type: place/flip, turn)
- `hint_used` / `undo_used`
- `tutorial_step_completed` (step)
- `setting_changed` (key, value)

---

## Arquivos neste bundle

| Arquivo | Conteúdo |
|---|---|
| `polaridade_design_spec.md` | **Especificação canônica** (mecânica, regras, monetização, animações, acessibilidade, strings) |
| `Polaridade — Design.html` | Entrada do design canvas com todas as telas + protótipo jogável |
| `styles.css` | Design tokens (cores, tipografia, peças, board, modais) — referência de valores exatos |
| `game-logic.js` | **Regras do jogo** (resolução da onda, IA simples, vitória). Use como referência da lógica. |
| `game-components.jsx` | Componentes visuais (Piece, Board, PlayerTray, ForceLine, GameHeader) |
| `screens.jsx` | Telas estáticas (Splash, Menu, Difficulty, EndGame, Tutorial, Settings, Pause) |
| `app.jsx` | Protótipo interativo completo (state machine + game loop + AI turn) |
| `canvas-app.jsx` | Wrapper do design canvas com todas as artboards estáticas |
| `design-canvas.jsx` / `ios-frame.jsx` | Starters do canvas e moldura iPhone (descartáveis) |

Abra `Polaridade — Design.html` em qualquer browser pra navegar todas as telas e jogar o protótipo (clique no botão de "focus" no canto da artboard "Protótipo jogável" pra abrir em tela cheia).

---

## Recomendações de implementação (Flutter)

- **State management:** Riverpod ou Bloc pra o `GameState`. Use uma classe `GameState` imutável com `copyWith` (mesmo padrão de `clone()` em `game-logic.js`).
- **Animações:** `AnimationController` por evento da onda. Sequência via `TweenSequence` ou um event queue async. Considere `flutter_animate` pra menos boilerplate.
- **Peças:** `CustomPainter` ou `Container` com `BoxDecoration` + `RadialGradient` + sombras compostas. Halo pode ser um `Container` com `ImageFilter.blur` ou `BackdropFilter`.
- **Backdrop estrelado:** `CustomPainter` desenhando ~12 dots (não use partícula real — custo desnecessário pro CPU spec'd).
- **Modal blur:** `BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8))`.
- **Haptics:** já tudo previsto na spec seção 8.3 — `HapticFeedback.selectionClick` / `.mediumImpact` / `.heavyImpact`.
- **i18n:** `flutter_localizations` + `Intl` + `.arb` files.
- **Ads:** Google Mobile Ads SDK (intersticial pós-partida + 2 rewarded).
- **Telemetria:** Firebase Analytics ou similar — não tem backend, então client-side só.

### IA — o protótipo usa uma heurística simples; produção precisa de minimax real

O `game-logic.js` tem `aiPickAction()` que faz uma busca de profundidade 1 com scoring básico. Substituir por **minimax com poda alpha-beta**:

- **Aprendiz:** depth 1 (lookhead 1 jogada) — uso direto da função atual já serve
- **Adepto:** depth 3 (lookahead 2 jogadas: minha+oponente+minha)
- **Mestre:** depth 5+ com iterative deepening e/ou move ordering

Função de avaliação sugerida: `peças_minhas - peças_oponente × 1.5 + bonus_por_estoque`. Tune com a telemetria (seção 11 da spec).
