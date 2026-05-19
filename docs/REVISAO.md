# Revisão crítica: Polaridade v0.1 → v0.2

Análise exaustiva das regras, física, IA, monetização e potencial de retenção do jogo entregue no briefing. Cada seção identifica problema → diagnóstico → correção aplicada (ou recomendação).

---

## 1. Sumário executivo

O Polaridade v0.1 entregue tinha **três problemas estruturais sérios** que limitavam a profundidade estratégica e a satisfação do jogador:

1. **Atração era visualmente bonita mas mecanicamente inerte** — não produzia movimento real (todo caso era bloqueado pelo próprio epicentro). O jogo na prática era só de repulsão.
2. **Empate decidido pela "regra do pie"** (IA vence em empate) era arbitrário e desagradável — o jogador perdia partidas que sentia ter empatado.
3. **Falta de mecânica de escalada** — uma vez aprendidas as regras, todas as partidas ficavam parecidas. Sem fator de viciamento.

A v0.2 entregue resolve os três:

| Problema | Correção v0.2 |
|---|---|
| Atração inerte | **Passagem orbital**: opostas cruzam pelo epicentro e param do outro lado |
| Empate injusto | **Desempate por destruições totais** (quantas do oponente cada lado eliminou) |
| Sem escalada | **Carga** (peças que sobrevivem viram pulsar com alcance 2) + **Ressonância** (destruir 2+ numa onda = bônus de estoque) |

Mais: motor de monetização cabeado (intersticial + rewarded + IAP "remover anúncios" em 3 línguas), linha de força visualmente renderizada, hierarquia visual para peças carregadas, e desempate exibido no fim de partida.

---

## 2. Análise da física — antes vs depois

### 2.1 O bug crítico da atração v1

A regra v1 dizia: "vizinho de polaridade oposta é puxado 1 casa em direção ao epicentro; se a casa-destino estiver ocupada, atração bloqueia."

**Problema:** o vizinho está a distância 1 do epicentro. A casa-destino é 1 casa em direção ao epicentro = **a casa do próprio epicentro**. Que está sempre ocupada (pela peça recém-jogada ou recém-girada). Portanto: **toda atração sempre bloqueia**. Sempre.

A spec original menciona "casos típicos" (e implica que existem outros), mas matematicamente não existem — onda é única, peças que se movem por reação não geram nova onda, então a casa do epicentro nunca fica vazia durante a resolução.

**Efeito prático no jogo:** atração era só um shake decorativo. O único vetor de pressão real era repulsão. Estratégia ficava reduzida a "empurrar peças do oponente pra fora", e o flip de polaridade (uma das duas ações por turno) ficava marginalizado: girar pra causar atração não fazia nada útil.

### 2.2 A correção: passagem orbital

Nova regra: **opostos se atraem com tanta força que a peça cruza pelo epicentro e cai do outro lado** — na casa simétrica `(er - dr, ec - dc)`.

- Casa simétrica vazia → peça aterrissa lá (com +1 charge).
- Casa simétrica fora do tabuleiro → peça destruída.
- Casa simétrica ocupada → cadeia: empurra o que estiver depois, peça atraída ocupa a casa simétrica.

**Por que essa solução:**
1. **Coerência física:** mantém a metáfora magnética. "Atração tão forte que passa pelo polo oposto" é intuitivo.
2. **Aumenta a profundidade:** atração agora é uma ferramenta ofensiva real. Posicionar epicentro perto da borda significa que peças opostas vizinhas podem ser jogadas pra fora pelo lado oposto.
3. **Não viola o "onda única":** continua sendo uma resolução em passe único.
4. **Permite trocas elegantes:** posicionar epicentro entre duas peças opostas pode atrair uma e repelir outra na mesma jogada.
5. **Valoriza o flip:** girar polaridade de uma peça sua que tem oponentes vizinhos agora muda drasticamente o que vai acontecer.

**Trade-off conhecido:** a casa simétrica do epicentro nem sempre está dentro do tabuleiro (depende da posição do epicentro). Isso significa que peças vizinhas com casa simétrica "fora" são essencialmente **alvos fáceis de eliminação**. Não é bug — é estratégia: posicione seu epicentro perto da borda e atraia inimigos pra morte.

### 2.3 Sistema de carga (novo)

Peças acumulam **+1 charge** cada vez que sobrevivem a uma força (atração ou repulsão). Charge máximo: 3 = **carregada (pulsar)**.

Quando uma peça carregada vira EPICENTRO (você joga sobre ela girando, ou ela já estava lá e o jogo continua), ela tem **alcance 2** — a onda magnética detecta vizinhos a 1 e a 2 casas (pulando por cima de cells vazias). Após disparar, charge zera.

**Por que essa mecânica funciona:**
- **Recompensa a paciência defensiva** — peças que sobrevivem ficam mais valiosas.
- **Cria escalada natural** — partidas longas tendem a ter peças carregadas, aumentando a tensão.
- **Estratégia emergente:** dá pra "carregar" uma peça de propósito, mantendo-a próxima a ações que a movam mas não a destruam.
- **Visualmente espetacular:** pulsar tem halo intenso e impacta múltiplas peças quando dispara.

### 2.4 Ressonância (combo)

Destruir **2+ peças do oponente numa única onda** → +1 peça no estoque (3+ → +2), até o limite de 6.

**Por que importa:**
- **Premia cadeias bem planejadas** — ganhar peça é melhor que só destruir peça.
- **Comeback potential** — quem está perdendo pode reverter com uma jogada espetacular.
- **Satisfação tátil** — uma cadeia de destruição já é satisfatória; ganhar peça por isso é o "tilt" da slot machine.
- **Educação invisível** — jogadores naturalmente aprendem a buscar cadeias.

Toast de "Ressonância!" aparece no centro do tabuleiro durante ~650ms.

### 2.5 Desempate justo

A v1 declarava: "Empate → P2 (IA) vence". Isso era arbitrário e frustrante. Em playtest hipotético, o jogador investe 10 turnos, fica empatado, perde.

A v2 conta **destruições totais**: quem destruiu mais peças do outro durante a partida toda vence o desempate. Empate verdadeiro (mesma quantidade no tabuleiro E mesma de destruições) é declarado oficialmente empate — não dá vitória pra ninguém.

Isso é justo, mensurável e expostas: o modal de fim de partida agora mostra "DESTRUÍDAS: 3 × 2" embaixo das peças, deixando claro como foi a contagem.

### 2.6 Resumo da nova tabela de casos

| Situação | Resultado v2 |
|---|---|
| Repulsão, destino vazio | Peça move 1 casa pra longe (+1 charge) |
| Repulsão, destino ocupado | Cadeia: bloqueadora também empurrada (+1 charge) |
| Repulsão, peça pra fora | Removida permanentemente. Conta como destruição. |
| **Atração, casa simétrica vazia** | **Peça cruza epicentro, aterrissa do outro lado (+1 charge)** |
| **Atração, casa simétrica ocupada** | **Cadeia push a partir da casa simétrica; atraída ocupa a casa simétrica** |
| **Atração, casa simétrica fora** | **Peça destruída (cruzou o epicentro e saiu)** |
| Casa vizinha vazia | Onda detecta peça na casa 2 se carregada; senão, nada |
| Epicentro carregado | Alcance 2 em todas as 8 direções; carga zera após disparar |
| 2+ destruições na onda | +1 (ou +2 se 3+) peça no estoque |
| Empate no fim do turno 20 | Desempata por destruições; senão, empate técnico |

---

## 3. Análise da IA

### 3.1 O que estava certo na v1
- Minimax + alpha-beta com 3 níveis (depth 1/3/5) é a abordagem correta pra um tabuleiro 5×5.
- Heurística básica (peças × 1.5 do oponente + estoque + penalidade de borda).
- Seed determinístico para testes.

### 3.2 O que melhoramos na v2

Função de avaliação considera, em adição às métricas v1:

```
+ peças carregadas (alto valor — alcance 2 é ameaça grande)
+ controle do centro (cell central = +1, controla 8 vizinhos)
+ destruições acumuladas (importante pro desempate)
- corners (-2.5, mais vulneráveis que bordas regulares)
```

Pesos calibrados conservadoramente. A IA Master agora "entende" que:
1. Empurrar uma peça do oponente pra borda é meio caminho pra destruí-la.
2. Manter peças próprias no centro maximiza alcance.
3. Não desperdiçar a polaridade — atrair pode destruir mais que repelir em certas configurações.
4. Carregar uma peça e depois dispará-la pode causar destruições múltiplas.

### 3.3 Limitações conhecidas
- **Aprendiz** (depth 1) ainda é fraco — qualquer humano vence depois de 3-4 partidas. Isso é intencional pra onboarding.
- **Mestre** (depth 5) no início do tabuleiro pode demorar 1-2s. Aceitável mas perceptível. Em devices baratos pode chegar a 3s.
- IA não usa transposition table — em cenários com peças simétricas, recalcula mesmas posições. Otimização futura.
- Sem heurística específica pra ressonância — a IA descobre a cadeia via lookahead, não via padrão.

### 3.4 Recomendações futuras
- **Iterative deepening** com transposition table no Master (ganho de ~30% de performance).
- **Quiescent search** quando o board está em "ação" (destruições/cadeias pendentes não capturadas pelo depth limite).
- **Self-play tuning** dos pesos da heurística: rodar 1000 partidas Mestre vs Mestre e ajustar até taxa de vitória do P1 ficar 50%.

---

## 4. Avaliação de UX e potencial de retenção

### 4.1 O que já está bom
- **Tempo de partida (1-3 min)** é ideal pra mobile casual.
- **Tutorial obrigatório de 6 passos** com ilustrações esquemáticas.
- **Tema cósmico** funciona em screenshots de loja (ASO).
- **Acessibilidade** levada a sério: símbolos sempre visíveis, anel duplo na peça da IA, modo daltônico, modo animação reduzida.
- **i18n PT/EN/ES** desde o dia 1.
- **Feedback tátil completo** (selection / medium / heavy / pattern de vitória).

### 4.2 Pontos fracos pra viciar o jogador

Em ordem de impacto esperado:

1. **Falta de progressão visível.** Não há "perfil", "estatísticas", "conquistas", "ranking" — nada que o jogador vê crescer entre partidas. Mobile games modernos vivem disso. **Recomendação: implementar `lib/services/stats_service.dart` que persiste em Hive (`vitórias_por_dificuldade`, `maior_cadeia`, `total_destruidas`, `partidas_jogadas`, `winrate`). Adicionar tela "Cosmos Profile" no menu.**

2. **Falta de desafio diário.** Não há motivo pra abrir o app amanhã se já jogou hoje. **Recomendação: daily puzzle — situação pré-montada do tabuleiro que precisa ser resolvida em N jogadas. Calendário visual no menu mostrando puzzles passados, recompensa cosmética (skin) por sequência de dias.**

3. **Sem skins/cosméticos.** Personalização é o vetor de monetização mais saudável em jogos casuais. **Recomendação: 3-5 skins de tabuleiro/peças (Nebulosa Andrômeda, Buraco Negro, Pulsar etc) a R\$ 4,90 cada. Algumas ganháveis por progressão, outras só compráveis.**

4. **Onda magnética é o mesmo show toda vez.** Após 20 partidas, a satisfação atenua. **Recomendação: variações sutis baseadas em conquistas. Ex: jogador com 100+ vitórias na Mestre desbloqueia partículas extras nas destruições.**

5. **Sem feedback comparativo.** Não sei se ganhei "facilmente" ou "no fio do bigode". **Recomendação: no end game, mostrar quão raro foi o resultado ("apenas 3% das partidas terminam com ressonância tripla") via stats persistidos.**

6. **Pause durante turno da IA é estranho.** O jogador fica esperando 700-1200ms sem motivo. **Recomendação: durante o "Pensando…" exibir um insight estatístico ("você venceu 60% das partidas no Adepto") — converte tempo morto em retenção.**

7. **Compartilhamento é apenas texto.** O design tem um botão "Compartilhar resultado" mas só copia texto. **Recomendação: gerar PNG (via `RenderRepaintBoundary` → bytes → share_plus) do tabuleiro final + score, com watermark do jogo. Captura de tela exige zero esforço do designer, alta taxa de share.**

### 4.3 Ranking de implementação por ROI

| Feature | Esforço | Impacto retenção |
|---|---|---|
| Stats persistidos | 1 dia | Alto |
| Daily puzzle | 3-4 dias | Muito alto |
| Skins comprável | 2-3 dias + design | Alto (e monetiza) |
| Card de share visual | 1 dia | Médio |
| Insights durante IA pensa | 1 dia | Médio |
| Variações de animação | 4-5 dias | Baixo |

---

## 5. Monetização — análise

### 5.1 Estratégia recomendada (já cabeada)

**Anúncios:**
- **Intersticial** após `Math.max(2, partidasDesdeUltimo) ≥ 2`. Aparece quando o jogador clica em "Nova partida" ou "Menu" no end game.
- **Rewarded** opcional para "Dica do Mestre" e "Desfazer". Implementação no game_screen ainda pendente (chips visíveis na action bar mas sem handler) — fácil de adicionar.

**IAP:**
- **`remove_ads` non-consumable** a R\$ 9,90 / US\$ 1.99 / €1.99 — preço de "snack". Remove intersticiais. Rewarded continuam disponíveis (opcional, jogador escolhe).

### 5.2 Por que R\$ 9,90 está bem precificado

- Abaixo do "limiar de medo" (R\$ 10 mentalmente vira "tem que pensar"; R\$ 9,90 é "tá tudo bem").
- Acima do mínimo da Play Store (R\$ 1,90 é "preço de spam").
- Alinhado com benchmarks: Threes! (R\$ 14,90), Two Dots remove ads (R\$ 9,90), Mini Metro (R\$ 12,90).
- Em US\$ 1.99 fica no tier 2 de IAP — preço-âncora clássico, suposto altíssimo conversion vs tier 1.

### 5.3 Métricas-alvo (hipóteses pra validar)

- **Taxa de conversão de IAP:** 1-3% dos usuários ativos. Game casual abstrato tende a 1.5-2%.
- **eCPM intersticial:** US\$ 5-15 (BR), US\$ 15-30 (US). Com cap a cada 2 partidas e ~6 partidas/sessão, ~1.5 ad/sessão.
- **Quebra de even ARPU:** com 100 instalações orgânicas → ~5 partidas/instalação → ~10 ads totais → US\$ 0.10 ARPU ads + ~1.5% × US\$ 1.99 = US\$ 0.03 ARPU IAP → ~US\$ 0.13 ARPU total. Sem CAC isso é margem; com US\$ 0.10 CAC fica próximo do breakeven.

### 5.4 Configuração técnica pendente

Antes do release de produção:

1. **AdMob console:** criar app + 2 ad units (intersticial + rewarded) para Android e iOS. Substituir os IDs de teste em `lib/services/ads_service.dart`.
2. **AndroidManifest.xml** (gerado por `flutter create`): adicionar
   ```xml
   <meta-data
     android:name="com.google.android.gms.ads.APPLICATION_ID"
     android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
   ```
3. **iOS Info.plist:** adicionar `GADApplicationIdentifier` e `SKAdNetworkItems` (lista atualizada no SDK do AdMob).
4. **Play Console:** criar produto não-consumível `remove_ads`, ativar pagamento, definir preço Tier 5 (≈ R\$ 9,90).
5. **App Store Connect:** in-app purchase `remove_ads` (non-consumable), Tier 2 (US\$ 1.99), localizado PT/EN/ES.
6. **LGPD/GDPR:** Implementar consent gate antes do AdMob (Google User Messaging Platform — `package:google_mobile_ads` já tem hook).
7. **Sandbox testing:** testar IAP no TestFlight (iOS) e Internal Testing (Play). Validar que `purchases.restorePurchases()` funciona após reinstalação.

### 5.5 Sugestões adicionais de monetização (futuro)

- **Skin pack premium** R\$ 14,90 (3 temas: Andrômeda, Big Bang, Pulsar).
- **"Profile boost" assinatura mensal** R\$ 4,90/mês: stats avançados, daily puzzles ilimitados (vs 1/dia free), prioridade no Codemagic do Kaio :)
- **Eventos sazonais:** Halloween com skin temporária grátis pra quem joga 10 partidas em 7 dias.

Cuidado com: **não monetizar progressão de jogabilidade**. Skins ok, dicas/desfazer rewarded ok, mas NUNCA "energia que recarrega" ou "pague pra ter mais peças" — quebra o jogo abstrato.

---

## 6. Lista de coisas pra arrumar / polir

Coisas pequenas notadas durante a revisão:

### Bugs / inconsistências
- **`_AboutTile`** tem TODOs vazios pros links de Privacidade/Termos/Créditos. Antes do release, precisa de URLs reais (host static no GitHub Pages? Notion público?).
- **Rewarded ads chips** mencionados na action bar (DICA / DESFAZER) ainda não têm implementação. O `AdsService.showRewarded()` já existe — falta o glue.
- **Tutorial step 5 (Ressonância)** tem ilustração esquemática simples (⊕ ✕2 + ⊕). Designer pode melhorar com uma animação curta da onda destruindo 2 peças.
- **Force line painter** desenha gradient de pixel-pra-pixel mas pode estar ligeiramente fora de alinhamento dependendo de DPR. Validar em devices.
- **`onAnimationComplete`** na BoardWidget pode ser chamado depois do `dispose` em corner cases (navegação rápida). Adicionar guard.

### Performance
- **Master AI em board vazio** com depth 5 e branching ~50: ~50^5 nós no pior caso. Alpha-beta corta MUITO, mas considere iterative deepening pra cap de 1s.
- **CustomPaint do force line** repinta cada frame durante a animação. Cachear ou usar `RepaintBoundary`.

### Acessibilidade
- **VoiceOver/TalkBack:** peças não têm semantics labels. Adicionar `Semantics(label: '⊕ player charged', child: PieceWidget(...))`.
- **Toque longo na peça do oponente** mencionado no spec ("consulta de polaridade") não foi implementado.

### Conteúdo
- **Tutorial obrigatório** só na primeira execução — não dá pra ver de novo facilmente (tem "Como jogar" no menu mas só texto, sem animação). Adicionar "Refazer tutorial" em Ajustes.

---

## 7. Próximos passos imediatos (ordem)

1. **Testar manualmente** num device Android com `flutter run`. Validar:
   - Fluxo splash → menu → dificuldade → jogo → fim → nova partida
   - Tutorial completo
   - Tela de Ajustes (mudar idioma, toggle reduced motion)
   - IAP "Remover anúncios" — vai falhar sem produto configurado, mas o botão deve aparecer
2. **Configurar AdMob e produtos IAP** (item 5.4 acima)
3. **Implementar stats service** (cód curto, alto impacto)
4. **Daily puzzle** (ROI top de retenção)
5. **Card visual de share** (ROI top de growth)

---

## 8. O que NÃO entregamos (ainda) e por quê

- **Daily puzzle, stats e skins**: escopo grande, melhor em iteração seguinte com playtests guiando.
- **Hint/undo rewarded ad handlers**: chips visíveis na UI mas sem callback. Service `AdsService.showRewarded()` está pronto — adicionar handler é 30min de trabalho mas precisa de visual de "jogada sugerida" no tabuleiro (highlight da casa por 3s) — design não definiu ainda.
- **Som e música**: `HapticsHelper` é completo, mas SFX e música ambient não foram adicionados (sem assets de áudio). `flutter_soloud` ou `audioplayers` é a stack natural pra Flutter.
- **Multiplayer assíncrono**: spec original diz "sem backend, sem multiplayer". Mantemos. Se quiser depois, dá pra adicionar partidas-por-código (passar tabuleiro como string compactada por link).
- **Análise de eventos / GA4**: spec menciona como pendência. Recomendo Firebase Analytics (gratuito até alto volume) com 5-6 eventos chave (`match_started`, `match_ended`, `hint_used`, `ad_dismissed`, `iap_initiated`, `iap_completed`).

---

*Documento de revisão por sessão Claude Code · v0.2.0 · maio 2026.*
