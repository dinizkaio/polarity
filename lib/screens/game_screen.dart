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
  const GameScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(difficulty: difficulty),
      child: const _GameScreenBody(),
    );
  }
}

class _GameScreenBody extends StatefulWidget {
  const _GameScreenBody();

  @override
  State<_GameScreenBody> createState() => _GameScreenBodyState();
}

class _GameScreenBodyState extends State<_GameScreenBody> {
  bool _paused = false;
  bool _endShown = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    // Feedback háptico em fim de partida
    if (game.phase == GamePhase.ended && !_endShown) {
      _endShown = true;
      if (game.state.winner == PieceOwner.player) {
        HapticsHelper.victoryPattern(settings);
      } else {
        HapticsHelper.medium(settings);
      }
    }

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
                        name: l10n.gameAi,
                        stockCount: game.state.stock[PieceOwner.ai] ?? 0,
                        onBoardCount: game.state.onBoard[PieceOwner.ai] ?? 0,
                        isCurrent: game.state.currentPlayer == PieceOwner.ai,
                        isThinking: game.phase == GamePhase.aiThinking,
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
                        name: l10n.gamePlayer,
                        stockCount: game.state.stock[PieceOwner.player] ?? 0,
                        onBoardCount: game.state.onBoard[PieceOwner.player] ?? 0,
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
                    playerPieces: game.state.onBoard[PieceOwner.player] ?? 0,
                    aiPieces: game.state.onBoard[PieceOwner.ai] ?? 0,
                    playerDestroyed: game.state.destroyed[PieceOwner.player] ?? 0,
                    aiDestroyed: game.state.destroyed[PieceOwner.ai] ?? 0,
                    totalTurns: game.state.displayTurn,
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
