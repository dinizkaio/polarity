# Polaridade

> Atração, repulsão, vitória — jogo de tabuleiro abstrato com peças magnetizadas.

5×5, single-player vs IA (3 níveis), 1–3 min por partida. Flutter / Dart, com i18n PT/EN/ES.

## v0.4.0 — diferenças em relação ao briefing original

**Mudança de paradigma**: jogo deixou de ser sobre destruição e virou sobre **construção de padrões**. Peças não são mais aniquiladas — apenas reposicionadas. Vence quem forma mais linhas/colunas/diagonais.

- **`pubspec.yaml` já está versionado** com todas as deps (provider, hive, google_fonts, google_mobile_ads, in_app_purchase).
- **Localizações hand-rolled** em `lib/l10n/strings_*.dart`. Não precisa rodar `flutter gen-l10n` — os `.arb` em `l10n/` ficam como documentação.
- **Física v6 (sem destruição)**:
  - **Atração orbital solo**: peça oposta pula pelo epicentro pra casa simétrica (com wrap toroidal).
  - **Atração em par**: opostos dos dois lados do epicentro trocam de posição (swap).
  - **Repulsão**: peça empurrada 1 casa pra longe; se destino ocupado, fica parada. Sem cadeia.
  - **Flip de polaridade** vale 1 jogada e ativa onda imediata.
- **Pontuação por linhas**: 3 em linha = +1, 4 = +3, 5 (mistas) = +5, 5 (mesma polaridade) = +10. Quando completa 5, peças voltam ao estoque do dono (reciclagem).
- **Vitória**: primeiro a 15 pontos OU mais pontos ao fim de 20 turnos.
- **20 turnos × 10 peças** + início aleatório 50/50.
- **Fim antecipado por stalemate por inércia** (4 flips consecutivos sem efeito).
- **Monetização cabeada**: `lib/services/ads_service.dart` (intersticial + rewarded) e `lib/services/purchases_service.dart` (IAP remove_ads). Antes do release, trocar os IDs de teste no `ads_service.dart` pelos IDs reais de produção e configurar produto `remove_ads` na Play Console / App Store Connect (R$ 9,90 / US$ 1.99 / €1.99).
- **Design study preservado** em `design_study/`.

Ao rodar `flutter create . --platforms=android,ios` o Flutter cria android/, ios/ etc — ele não vai mexer no pubspec.yaml já existente nem nos arquivos em `lib/`. Confirme o nome do projeto (`polaridade`) e o org (`app.polaridade`).

---

## Instruções para o Claude Code (subir no GitHub)

Este zip contém o **conteúdo autoral** do projeto (lib/, l10n/, pubspec.yaml, testes). As pastas `android/` e `ios/` ainda **não existem** — elas precisam ser geradas pelo Flutter SDK local para garantir compatibilidade de versão. Siga este roteiro:

### 1. Bootstrap do projeto Flutter

A partir do diretório raiz do repositório (vazio ou com apenas estes arquivos extraídos):

```bash
# 1. Gera android/, ios/, linux/, macos/, web/, windows/ shells
flutter create . \
  --org app.polaridade \
  --project-name polaridade \
  --description "Polaridade — Atração, repulsão, vitória." \
  --platforms=android,ios

# 2. Baixa dependências
flutter pub get

# 3. Gera arquivo de localizações a partir dos .arb
flutter gen-l10n
```

Após esses comandos, o projeto deve estar completo e pronto pra rodar. Se o `flutter create` reclamar de arquivos existentes em `lib/`, ignore — eles serão preservados (o Flutter só sobrescreve se for um projeto novo).

### 2. Verificação

```bash
flutter analyze         # deve passar sem erros
flutter test            # roda testes de game_logic e ai
flutter run             # roda em emulador/dispositivo conectado
```

### 3. Build de APK release

```bash
flutter build apk --release
# Saída: build/app/outputs/flutter-apk/app-release.apk
```

Para build de bundle (AAB) pra Play Store:

```bash
flutter build appbundle --release
# Saída: build/app/outputs/bundle/release/app-release.aab
```

### 4. Codemagic CI (opcional, recomendado)

Kaio já tem workflow `ios-release` configurado para o Session Flow. Para o Polaridade Android, criar um workflow novo no `codemagic.yaml`:

```yaml
workflows:
  android-release:
    name: Android Release
    instance_type: mac_mini_m2
    environment:
      flutter: stable
      vars:
        PACKAGE_NAME: "app.polaridade.game"
    scripts:
      - flutter packages pub get
      - flutter gen-l10n
      - flutter analyze
      - flutter test
      - flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/app-release.apk
```

### 5. Commit inicial

```bash
git add .
git commit -m "Initial commit: Polaridade v0.1.0"
git push origin main
```

---

## Estrutura

```
lib/
├── main.dart                     # Entry point: inicializa Hive, runApp
├── app.dart                      # MaterialApp com i18n e tema
├── theme/                        # Tokens de cor, tipografia, ThemeData
├── models/                       # Piece, GameState, GameAction, AnimationEvent
├── game/
│   ├── game_logic.dart           # Motor de regras (puro, sem UI)
│   └── ai.dart                   # Minimax + poda alpha-beta (3 níveis)
├── providers/
│   ├── settings_provider.dart    # Preferências (Hive)
│   └── game_provider.dart        # State machine do jogo
├── widgets/                      # Componentes reutilizáveis
├── screens/                      # 7 telas (splash, menu, dificuldade, jogo, tutorial, ajustes, regras)
├── utils/
│   └── haptics_helper.dart       # Háptica que respeita preferências
└── l10n/
    └── app_localizations.dart    # GERADO por flutter gen-l10n a partir dos .arb

l10n/
├── app_pt.arb                    # Português (template)
├── app_en.arb                    # Inglês
└── app_es.arb                    # Espanhol

test/
├── game_logic_test.dart
└── ai_test.dart
```

## Regras do jogo (resumo)

- Tabuleiro 5×5, 2 jogadores, 6 peças no estoque cada
- Cada peça tem polaridade ⊕ ou ⊖
- Por turno, 1 ação: **colocar** peça nova (escolhendo polaridade) OU **girar** polaridade de peça própria
- A peça que sofre a ação é o **epicentro**. Os 8 vizinhos reagem na ordem fixa **N→NE→E→SE→S→SW→W→NW**:
  - **Atração** (polaridades opostas): vizinho é puxado 1 casa em direção ao epicentro. Bloqueia se a casa de destino estiver ocupada (tipicamente: o próprio epicentro) → animação de shake.
  - **Repulsão** (polaridades iguais): vizinho é empurrado 1 casa para longe. Pode formar cadeia. Peça empurrada para fora do tabuleiro é **removida permanentemente**.
- Onda **única**: peças que se movem por reação NÃO geram nova onda.
- Vitória: oponente sem peças (tabuleiro + estoque), OU após 20 ações totais (10 turnos × 2 jogadores) quem tem mais peças no tabuleiro vence. Empate → P2 (IA) vence.

## Stack técnica

- Flutter (canal stable, ≥3.24)
- Provider para state management
- Hive para persistência local de preferências
- google_fonts para Space Grotesk, Manrope, JetBrains Mono
- flutter_localizations + intl para i18n PT/EN/ES

## Pendências

- [ ] AdMob não está integrado. Stubs marcados com `// TODO: mostrar intersticial AdMob aqui` em `lib/screens/game_screen.dart`. Descomentar `google_mobile_ads` no `pubspec.yaml`, configurar app IDs no `android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist`, e plugar nos handlers `onNewGame` / `onMenu`.
- [ ] Linha de força (`ForceEvent`) é consumida pelo BoardWidget mas não renderizada visualmente — atualmente só dispara o efeito de epicentro. Para adicionar uma linha animada do epicentro até o vizinho, criar `lib/widgets/force_line.dart` com CustomPaint sobre o tabuleiro durante ~220ms (dourada para attract, laranja para repel).
- [ ] Linhas de força visuais
- [ ] Ícone do app (`ios-icon` e `android/app/src/main/res/mipmap-*`) — usar `flutter_launcher_icons` quando tiver o asset final
- [ ] Splash nativa (`flutter_native_splash`) — opcional, a splash em Dart já existe
- [ ] Telemetria: GA4 / Firebase Analytics
- [ ] Política de privacidade e termos (links em Ajustes → Sobre estão como TODO)
- [ ] Testes E2E (golden tests para peças e tabuleiro)

## Notas de implementação

- **Imutabilidade**: GameState é imutável; cada ação produz um novo state via `copyWith`. Permite undo trivial (basta empilhar states).
- **Animações como eventos**: GameLogic emite uma lista ordenada de `AnimationEvent`s. O `BoardWidget` consome essa fila em sequência, com timings calibrados pra reação magnética parecer fluida (~150–500ms por evento, multiplicador de velocidade nos ajustes).
- **IA**: minimax com poda alpha-beta. Profundidades 1/3/5 são suficientes — board 5×5 com no máximo 25 peças e ~50 ações iniciais. Master roda em <1s no início, <300ms quando o tabuleiro está cheio. Heurística pesa peças no tabuleiro 1.5x para o oponente (pressão estratégica) e penaliza peças próprias em bordas.
- **Regra do pie** simplificada: empate em 20 ações → IA vence. Decisão deliberada para evitar UX confusa de "trocar de lado" num jogo casual de 1-3 min.

## Licença

Proprietária. © 2026 Kaio Diniz.
