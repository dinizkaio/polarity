import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/animation_event.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'piece_widget.dart';

/// Tabuleiro 5x5. Anima eventos da fila do GameProvider em sequência.
class BoardWidget extends StatefulWidget {
  final double size;
  const BoardWidget({super.key, required this.size});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with TickerProviderStateMixin {
  List<List<Piece?>> _displayBoard =
      List.generate(GameState.boardSize, (_) => List<Piece?>.filled(GameState.boardSize, null));

  bool _animating = false;
  Cell? _epicenter;
  bool _epicenterCharged = false;
  Cell? _shakingCell;
  ForceEvent? _currentForce;
  Cell? _chargeFlashCell;
  ResonanceEvent? _activeResonance;

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
        if (a[r][c]?.charge != b[r][c]?.charge) return false;
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
      await _animateEvent(event, mult, settings);
    }

    if (!mounted) return;
    _epicenter = null;
    _epicenterCharged = false;
    _currentForce = null;
    _shakingCell = null;
    _chargeFlashCell = null;
    _animating = false;
    setState(() {});
    if (mounted) {
      context.read<GameProvider>().onAnimationComplete();
    }
  }

  Future<void> _animateEvent(AnimationEvent event, double mult, SettingsProvider settings) async {
    switch (event) {
      case PlaceEvent(:final at, :final piece):
        HapticsHelper.medium(settings);
        setState(() => _displayBoard[at.row][at.col] = piece);
        await _wait((400 * mult).round());

      case FlipEvent(:final at, :final piece):
        HapticsHelper.selection(settings);
        setState(() => _displayBoard[at.row][at.col] = piece);
        await _wait((450 * mult).round());

      case EpicenterEvent(:final at, :final isCharged):
        setState(() {
          _epicenter = at;
          _epicenterCharged = isCharged;
        });
        await _wait((150 * mult).round());

      case ForceEvent():
        setState(() => _currentForce = event);
        await _wait((220 * mult).round());
        setState(() => _currentForce = null);

      case MoveEvent(:final from, :final to, :final piece):
        setState(() {
          _displayBoard[from.row][from.col] = null;
          _displayBoard[to.row][to.col] = piece;
        });
        await _wait((300 * mult).round());

      case ShakeEvent(:final at):
        HapticsHelper.selection(settings);
        setState(() => _shakingCell = at);
        await _wait((200 * mult).round());
        setState(() => _shakingCell = null);

      case DestroyEvent(:final from):
        HapticsHelper.heavy(settings);
        setState(() => _displayBoard[from.row][from.col] = null);
        await _wait((500 * mult).round());

      case ChargeEvent(:final at, :final newCharge):
        // Atualiza o charge na peça mostrada (caso o move já tenha sido aplicado
        // antes desse evento, a peça pode já estar aqui ou ter sido removida)
        final p = _displayBoard[at.row][at.col];
        if (p != null) {
          setState(() {
            _displayBoard[at.row][at.col] = p.copyWith(charge: newCharge);
            _chargeFlashCell = at;
          });
          await _wait((220 * mult).round());
          setState(() => _chargeFlashCell = null);
        }

      case ResonanceEvent():
        HapticsHelper.heavy(settings);
        setState(() => _activeResonance = event);
        await _wait((650 * mult).round());
        setState(() => _activeResonance = null);

      case EndEvent():
        await _wait((600 * mult).round());
    }
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
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Container(
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
              border: _epicenterCharged
                  ? Border.all(color: AppColors.haloPlus.withValues(alpha: 0.45), width: 1.5)
                  : null,
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
          ),
          // Camada de linha de força (CustomPaint)
          if (_currentForce != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ForceLinePainter(
                    force: _currentForce!,
                    cellSize: cellSize,
                    gap: gap,
                    padding: padding,
                  ),
                ),
              ),
            ),
          // Toast de ressonância
          if (_activeResonance != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xCCFFC15B), Color(0xCCFFEBC2)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.haloPlus.withValues(alpha: 0.6),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Text(
                        _activeResonance!.bonus > 0
                            ? l10n.resonanceBonusToast(_activeResonance!.bonus)
                            : l10n.gameResonance,
                        style: AppTypography.uiButton(color: AppColors.bgVoid).copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
    final isChargeFlash = _chargeFlashCell?.row == row && _chargeFlashCell?.col == col;

    Color cellBg = Colors.white.withValues(alpha: 0.025);
    BoxBorder? border;
    if (isTargetable) {
      cellBg = AppColors.haloMinus.withValues(alpha: 0.15);
      border = Border.all(color: AppColors.haloMinus.withValues(alpha: 0.6), width: 1.5);
    }

    return GestureDetector(
      onTap: _animating || game.phase == GamePhase.aiThinking || game.phase == GamePhase.resolving
          ? null
          : () {
              HapticsHelper.selection(settings);
              game.tapCell(row, col);
            },
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
                  scale: isEpicenter ? (_epicenterCharged ? 1.24 : 1.18) : (isSelected ? 1.08 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: isShaking ? const Offset(0.05, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 80),
                    child: AnimatedScale(
                      scale: isChargeFlash ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
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
      ),
    );
  }
}

class _ForceLinePainter extends CustomPainter {
  final ForceEvent force;
  final double cellSize;
  final double gap;
  final double padding;

  const _ForceLinePainter({
    required this.force,
    required this.cellSize,
    required this.gap,
    required this.padding,
  });

  Offset _center(Cell c) => Offset(
        padding + c.col * (cellSize + gap) + cellSize / 2,
        padding + c.row * (cellSize + gap) + cellSize / 2,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final from = _center(force.from);
    final to = _center(force.to);
    final color = force.kind == ForceKind.attract
        ? const Color(0xFFFFEBC2)
        : const Color(0xFFFA9A4A);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromPoints(from, to))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawLine(from, to, paint);

    // Pequeno glow no destino
    canvas.drawCircle(
      to,
      cellSize * 0.18,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_ForceLinePainter old) =>
      old.force.from != force.from ||
      old.force.to != force.to ||
      old.force.kind != force.kind;
}
