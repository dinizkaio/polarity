import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animation_event.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'piece_widget.dart';

/// Tabuleiro 5x5. Anima eventos da fila do GameProvider em sequência.
class BoardWidget extends StatefulWidget {
  final double size;
  const BoardWidget({super.key, required this.size});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with TickerProviderStateMixin {
  /// Eventos que já foram aplicados visualmente (versão "renderizada" do tabuleiro).
  /// Pode divergir do state.board do provider durante a animação.
  List<List<Piece?>> _displayBoard =
      List.generate(GameState.boardSize, (_) => List<Piece?>.filled(GameState.boardSize, null));

  // Animação corrente
  bool _animating = false;
  Cell? _epicenter;
  Cell? _shakingCell;
  ForceEvent? _currentForce;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    _displayBoard = game.state.cloneBoard();

    game.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    final game = context.read<GameProvider>();
    if (game.phase == GamePhase.resolving && !_animating && game.pendingEvents.isNotEmpty) {
      _runAnimationQueue();
    } else if (game.phase != GamePhase.resolving && !_animating) {
      // Sincroniza display board com state quando não estamos animando
      final stateBoard = game.state.cloneBoard();
      if (!_boardsEqual(_displayBoard, stateBoard)) {
        setState(() => _displayBoard = stateBoard);
      }
    }
  }

  bool _boardsEqual(List<List<Piece?>> a, List<List<Piece?>> b) {
    for (int r = 0; r < GameState.boardSize; r++) {
      for (int c = 0; c < GameState.boardSize; c++) {
        if (a[r][c]?.id != b[r][c]?.id) return false;
        if (a[r][c]?.polarity != b[r][c]?.polarity) return false;
      }
    }
    return true;
  }

  Future<void> _runAnimationQueue() async {
    _animating = true;
    final game = context.read<GameProvider>();
    final settings = context.read<SettingsProvider>();
    final mult = settings.animationDurationMultiplier;

    final events = List<AnimationEvent>.from(game.pendingEvents);

    for (final event in events) {
      if (!mounted) return;
      await _animateEvent(event, mult);
    }

    if (!mounted) return;
    _epicenter = null;
    _currentForce = null;
    _shakingCell = null;
    _animating = false;
    setState(() {});
    // Notifica provider que animação acabou
    if (mounted) {
      context.read<GameProvider>().onAnimationComplete();
    }
  }

  Future<void> _animateEvent(AnimationEvent event, double mult) async {
    switch (event) {
      case PlaceEvent(:final at, :final piece):
        setState(() => _displayBoard[at.row][at.col] = piece);
        await _wait((400 * mult).round());

      case FlipEvent(:final at, :final piece):
        setState(() => _displayBoard[at.row][at.col] = piece);
        await _wait((450 * mult).round());

      case EpicenterEvent(:final at):
        setState(() => _epicenter = at);
        await _wait((150 * mult).round());

      case ForceEvent():
        setState(() => _currentForce = event);
        await _wait((220 * mult).round());
        setState(() => _currentForce = null);

      case MoveEvent(:final from, :final to, :final piece):
        // Aplica movimento. (Em produção, animar com Tween via AnimatedPositioned.)
        setState(() {
          _displayBoard[from.row][from.col] = null;
          _displayBoard[to.row][to.col] = piece;
        });
        await _wait((300 * mult).round());

      case ShakeEvent(:final at):
        setState(() => _shakingCell = at);
        await _wait((200 * mult).round());
        setState(() => _shakingCell = null);

      case DestroyEvent(:final from):
        setState(() => _displayBoard[from.row][from.col] = null);
        await _wait((500 * mult).round());

      case EndEvent():
        // Pausa dramática antes do modal de fim
        await _wait((600 * mult).round());
    }
    // Pequeno delay entre vizinhos pra cascata
    if (event is ForceEvent || event is MoveEvent || event is ShakeEvent) {
      await _wait((60 * mult).round());
    }
  }

  Future<void> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final gap = 4.0;
    final padding = 6.0;
    final cellSize = (widget.size - padding * 2 - gap * (GameState.boardSize - 1)) / GameState.boardSize;

    return Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const RadialGradient(
          colors: [Color(0xFF1A1545), Color(0xFF0A0A24)],
          stops: [0.0, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: GameState.boardSize,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
        ),
        itemCount: GameState.boardSize * GameState.boardSize,
        itemBuilder: (context, index) {
          final row = index ~/ GameState.boardSize;
          final col = index % GameState.boardSize;
          return _buildCell(game, settings, row, col, cellSize);
        },
      ),
    );
  }

  Widget _buildCell(GameProvider game, SettingsProvider settings, int row, int col, double cellSize) {
    final piece = _displayBoard[row][col];
    final isSelected = game.selectedPiece?.row == row && game.selectedPiece?.col == col;
    final isTargetable = game.phase == GamePhase.choosingPolarity &&
        game.selectedEmptyCell?.row == row &&
        game.selectedEmptyCell?.col == col;
    final isEpicenter = _epicenter?.row == row && _epicenter?.col == col;
    final isShaking = _shakingCell?.row == row && _shakingCell?.col == col;

    Color cellBg = Colors.white.withValues(alpha: 0.025);
    BoxBorder? border;
    if (isTargetable) {
      cellBg = AppColors.haloMinus.withValues(alpha: 0.15);
      border = Border.all(color: AppColors.haloMinus.withValues(alpha: 0.6), width: 1.5);
    }

    return GestureDetector(
      onTap: _animating || game.phase == GamePhase.aiThinking || game.phase == GamePhase.resolving
          ? null
          : () => game.tapCell(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Center(
          child: piece == null
              ? const SizedBox.shrink()
              : AnimatedScale(
                  scale: isEpicenter ? 1.18 : (isSelected ? 1.08 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: isShaking ? const Offset(0.05, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 80),
                    child: PieceWidget(
                      piece: piece,
                      size: cellSize,
                      colorblindMode: settings.colorblind,
                      selected: isSelected,
                      epicenter: isEpicenter,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
