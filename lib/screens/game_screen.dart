import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai.dart';
import '../l10n/app_localizations.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ads_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptics_helper.dart';
import '../widgets/action_bar.dart';
import '../widgets/board_widget.dart';
import '../widgets/cosmic_backdrop.dart';
import '../widgets/end_game_modal.dart';
import '../widgets/game_header.dart';
import '../widgets/player_tray.dart';

class GameScreen extends StatelessWidget {
  final AiDifficulty difficulty;
  final int maxTurns;
  final bool localMultiplayer;
  const GameScreen({
    super.key,
    required this.difficulty,
    this.maxTurns = 20,
    this.localMultiplayer = false,
  });

  /// Resolve se preview deve estar ativo para esta combinação.
  static bool resolvePreviewEnabled(
    PreviewMode mode,
    AiDifficulty difficulty,
    bool localMultiplayer,
  ) {
    switch (mode) {
      case PreviewMode.always:
        return true;
      case PreviewMode.never:
        return false;
      case PreviewMode.auto:
        if (localMultiplayer) return true;
        return difficulty == AiDifficulty.apprentice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final previewEnabled = resolvePreviewEnabled(
      settings.previewMode,
      difficulty,
      localMultiplayer,
    );
    return ChangeNotifierProvider(
      create: (_) => GameProvider(
        difficulty: difficulty,
        maxTurns: maxTurns,
        localMultiplayer: localMultiplayer,
        previewEnabled: previewEnabled,
      ),
      child: _GameScreenBody(previewEnabled: previewEnabled),
    );
  }
}

class _GameScreenBody extends StatefulWidget {
  final bool previewEnabled;
  const _GameScreenBody({required this.previewEnabled});

  @override
  State<_GameScreenBody> createState() => _GameScreenBodyState();
}

class _GameScreenBodyState extends State<_GameScreenBody> {
  bool _paused = false;
  bool _endShown = false;

  @override
  void didUpdateWidget(covariant _GameScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewEnabled != widget.previewEnabled) {
      // Settings mudou: propaga pro provider
      context.read<GameProvider>().previewEnabled = widget.previewEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    // Feedback háptico em fim de partida
    if (game.phase == GamePhase.ended && !_endShown) {
      _endShown = true;
      // No modo local, sempre dispara vitória (alguém ganhou).
      // No modo vs IA, só se o player venceu.
      final shouldCelebrate = game.localMultiplayer
          ? game.state.winner != null
          : game.state.winner == PieceOwner.player;
      if (shouldCelebrate) {
        HapticsHelper.victoryPattern(settings);
      } else {
        HapticsHelper.medium(settings);
      }
    }

    // Nomes dos jogadores conforme o modo
    final p1Name = game.localMultiplayer ? l10n.gamePlayer1 : l10n.gamePlayer;
    final p2Name = game.localMultiplayer ? l10n.gamePlayer2 : l10n.gameAi;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_paused) {
          setState(() => _paused = false);
          return;
        }
        _confirmQuit(context);
      },
      child: Scaffold(
        body: CosmicBackdrop(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GameHeader(
                        state: game.state,
                        onPause: () => setState(() => _paused = true),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PlayerTray(
                        owner: PieceOwner.ai,
                        name: p2Name,
                        stockCount: game.state.stock[PieceOwner.ai] ?? 0,
                        onBoardCount: game.state.onBoard[PieceOwner.ai] ?? 0,
                        points: game.state.points[PieceOwner.ai] ?? 0,
                        isCurrent: game.state.currentPlayer == PieceOwner.ai,
                        isThinking: !game.localMultiplayer &&
                            game.phase == GamePhase.aiThinking,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.maxWidth.clamp(0.0, 360.0);
                          return BoardWidget(size: size);
                        },
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PlayerTray(
                        owner: PieceOwner.player,
                        name: p1Name,
                        stockCount: game.state.stock[PieceOwner.player] ?? 0,
                        onBoardCount: game.state.onBoard[PieceOwner.player] ?? 0,
                        points: game.state.points[PieceOwner.player] ?? 0,
                        isCurrent: game.state.currentPlayer == PieceOwner.player &&
                            game.phase != GamePhase.aiThinking,
                      ),
                    ),
                    const ActionBar(),
                  ],
                ),
                if (_paused)
                  PauseModal(
                    onResume: () => setState(() => _paused = false),
                    onRestart: () {
                      setState(() {
                        _paused = false;
                        _endShown = false;
                      });
                      context.read<GameProvider>().newGame();
                    },
                    onQuit: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                  ),
                if (game.phase == GamePhase.ended)
                  EndGameModal(
                    winner: game.state.winner,
                    playerPoints: game.state.points[PieceOwner.player] ?? 0,
                    aiPoints: game.state.points[PieceOwner.ai] ?? 0,
                    totalTurns: game.state.displayTurn,
                    localMultiplayer: game.localMultiplayer,
                    onNewGame: () async {
                      // Mostra intersticial (no-op se anúncios removidos ou frequência não atingida)
                      await context.read<AdsService>().maybeShowInterstitialAfterMatch();
                      if (!mounted) return;
                      setState(() => _endShown = false);
                      context.read<GameProvider>().newGame();
                    },
                    onMenu: () async {
                      await context.read<AdsService>().maybeShowInterstitialAfterMatch();
                      if (!mounted) return;
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resultado copiado!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: Text(l10n.quitConfirmTitle),
        content: Text(l10n.quitConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.quitConfirmNo),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text(l10n.quitConfirmYes, style: const TextStyle(color: AppColors.quit)),
          ),
        ],
      ),
    );
  }
}
