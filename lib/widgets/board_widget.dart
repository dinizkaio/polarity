import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
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
  ForceEvent? _currentForce;
  LineCompletedEvent? _activeLine;
  final Map<int, _LineFlash> _lineFlashes = {};
  final Map<int, _Recycle> _recycles = {};
  int _effectIdCounter = 0;

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
    for (final f in _lineFlashes.values) {
      f.controller.dispose();
    }
    for (final r in _recycles.values) {
      r.controller.dispose();
    }
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
    _currentForce = null;
    _activeLine = null;
    _animating = false;
    setState(() {});
    if (mounted) context.read<GameProvider>().onAnimationComplete();
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

      case EpicenterEvent(:final at):
        setState(() => _epicenter = at);
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

      case SwapEvent(:final cellA, :final cellB, :final pieceA, :final pieceB):
        HapticsHelper.medium(settings);
        setState(() {
          _displayBoard[cellA.row][cellA.col] = pieceB;
          _displayBoard[cellB.row][cellB.col] = pieceA;
        });
        await _wait((350 * mult).round());

      case DestroyEvent(:final from, :final piece):
        HapticsHelper.heavy(settings);
        _spawnRecycle(from, _haloColor(piece));
        setState(() => _displayBoard[from.row][from.col] = null);
        await _wait((500 * mult).round());

      case LineCompletedEvent():
        HapticsHelper.heavy(settings);
        _spawnLineFlash(event);
        if (event.recycled) {
          for (final cell in event.cells) {
            final p = _displayBoard[cell.row][cell.col];
            if (p != null) _spawnRecycle(cell, _haloColor(p));
          }
          setState(() {
            for (final cell in event.cells) {
              _displayBoard[cell.row][cell.col] = null;
            }
          });
        }
        setState(() => _activeLine = event);
        await _wait((event.recycled ? 800 : 500) * mult ~/ 1);
        setState(() => _activeLine = null);

      case EndEvent():
        await _wait((600 * mult).round());
    }
    if (event is ForceEvent || event is MoveEvent || event is SwapEvent) {
      await _wait((60 * mult).round());
    }
  }

  Future<void> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  Color _haloColor(Piece p) =>
      p.polarity == Polarity.plus ? AppColors.haloPlus : AppColors.haloMinus;

  void _spawnLineFlash(LineCompletedEvent event) {
    final id = ++_effectIdCounter;
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: event.recycled ? 800 : 500),
    );
    final flash = _LineFlash(
      id: id,
      cells: event.cells,
      color: event.uniformPolarity ? AppColors.haloPlus : AppColors.ink,
      controller: controller,
      recycled: event.recycled,
    );
    setState(() => _lineFlashes[id] = flash);
    controller.forward().whenComplete(() {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _lineFlashes.remove(id));
      controller.dispose();
    });
  }

  void _spawnRecycle(Cell at, Color color) {
    final id = ++_effectIdCounter;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final r = _Recycle(id: id, cell: at, color: color, controller: controller);
    setState(() => _recycles[id] = r);
    controller.forward().whenComplete(() {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _recycles.remove(id));
      controller.dispose();
    });
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
          // Linhas completas: flash dourado/branco sobre as células
          ..._lineFlashes.values.map(
            (f) => Positioned.fill(
              key: ValueKey('lf_${f.id}'),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: f.controller,
                  builder: (_, __) => CustomPaint(
                    painter: _LineFlashPainter(
                      cells: f.cells,
                      color: f.color,
                      progress: f.controller.value,
                      cellSize: cellSize,
                      gap: gap,
                      padding: padding,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Reciclagem: peças subindo até desaparecer
          ..._recycles.values.map(
            (r) => Positioned.fill(
              key: ValueKey('rc_${r.id}'),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: r.controller,
                  builder: (_, __) => CustomPaint(
                    painter: _RecyclePainter(
                      cell: r.cell,
                      color: r.color,
                      progress: r.controller.value,
                      cellSize: cellSize,
                      gap: gap,
                      padding: padding,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay de preview de jogada
          if (game.phase == GamePhase.previewing && game.previewResult != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PreviewOverlayPainter(
                    events: game.previewResult!.events,
                    cellSize: cellSize,
                    gap: gap,
                    padding: padding,
                  ),
                ),
              ),
            ),
          if (game.phase == GamePhase.previewing && game.previewResult != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: _PreviewToast(
                    state: game.state,
                    result: game.previewResult!,
                  ),
                ),
              ),
            ),
          // Toast de pontuação
          if (_activeLine != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _activeLine!.uniformPolarity
                            ? [const Color(0xCCFFC15B), const Color(0xCCFFEBC2)]
                            : [const Color(0xCCC4B8FF), const Color(0xCCF5F2FF)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.haloPlus.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.lineToast(_activeLine!.length, _activeLine!.pointsEarned),
                      style: AppTypography.uiButton(color: AppColors.bgVoid).copyWith(fontSize: 13),
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
    final isPreviewing =
        game.phase == GamePhase.previewing && game.previewResult != null;
    // Em modo preview, renderiza o board PROJETADO (resultado da ação) com opacity.
    final pieceToShow = isPreviewing
        ? game.previewResult!.newState.board[row][col]
        : _displayBoard[row][col];
    final isSelected = game.selectedPiece?.row == row && game.selectedPiece?.col == col;
    final isTargetable = game.phase == GamePhase.choosingPolarity &&
        game.selectedEmptyCell?.row == row &&
        game.selectedEmptyCell?.col == col;
    final isEpicenter = _epicenter?.row == row && _epicenter?.col == col;
    final piece = pieceToShow;

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
              : Opacity(
                  opacity: isPreviewing ? 0.55 : 1.0,
                  child: AnimatedScale(
                    scale: isEpicenter ? 1.18 : (isSelected ? 1.08 : 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
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
        colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.95)],
      ).createShader(Rect.fromPoints(from, to))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawLine(from, to, paint);
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

class _LineFlash {
  final int id;
  final List<Cell> cells;
  final Color color;
  final AnimationController controller;
  final bool recycled;
  const _LineFlash({
    required this.id,
    required this.cells,
    required this.color,
    required this.controller,
    required this.recycled,
  });
}

/// Pinta um glow contínuo sobre as células da run. Para 5-em-linha
/// (recycled), o glow é mais forte e dura mais.
class _LineFlashPainter extends CustomPainter {
  final List<Cell> cells;
  final Color color;
  final double progress;
  final double cellSize;
  final double gap;
  final double padding;

  const _LineFlashPainter({
    required this.cells,
    required this.color,
    required this.progress,
    required this.cellSize,
    required this.gap,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pulse: começa intenso, suaviza
    final intensity = (1.0 - progress).clamp(0.0, 1.0);
    for (final cell in cells) {
      final cx = padding + cell.col * (cellSize + gap) + cellSize / 2;
      final cy = padding + cell.row * (cellSize + gap) + cellSize / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: cellSize, height: cellSize),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.55 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_LineFlashPainter old) => old.progress != progress;
}

class _Recycle {
  final int id;
  final Cell cell;
  final Color color;
  final AnimationController controller;
  const _Recycle({
    required this.id,
    required this.cell,
    required this.color,
    required this.controller,
  });
}

/// Anima a peça "subindo" até desaparecer — representa o retorno ao estoque.
class _RecyclePainter extends CustomPainter {
  final Cell cell;
  final Color color;
  final double progress;
  final double cellSize;
  final double gap;
  final double padding;

  const _RecyclePainter({
    required this.cell,
    required this.color,
    required this.progress,
    required this.cellSize,
    required this.gap,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = padding + cell.col * (cellSize + gap) + cellSize / 2;
    final cy = padding + cell.row * (cellSize + gap) + cellSize / 2;
    final rise = cellSize * 0.6 * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Aro luminoso ascendente
    canvas.drawCircle(
      Offset(cx, cy - rise),
      cellSize * 0.35 * (1 + progress * 0.3),
      Paint()
        ..color = color.withValues(alpha: 0.6 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pequenas partículas subindo
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi;
      final radius = cellSize * 0.15;
      final px = cx + radius * math.cos(angle);
      final py = cy - rise + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(px, py),
        cellSize * 0.04 * alpha,
        Paint()
          ..color = color.withValues(alpha: 0.8 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RecyclePainter old) => old.progress != progress;
}

/// Overlay desenhado quando `phase == previewing`. Mostra:
/// - Setinhas dos movimentos previstos (origem → destino)
/// - Halo dourado nas células de runs novas (LineCompletedEvents)
/// - X vermelho nas peças que serão roubadas (DestroyEvents)
class _PreviewOverlayPainter extends CustomPainter {
  final List<AnimationEvent> events;
  final double cellSize;
  final double gap;
  final double padding;

  const _PreviewOverlayPainter({
    required this.events,
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
    // 1. Halo dourado nas células de runs novas (LineCompletedEvent)
    for (final e in events) {
      if (e is! LineCompletedEvent) continue;
      final color = e.uniformPolarity ? AppColors.haloPlus : AppColors.ink;
      for (final cell in e.cells) {
        final c = _center(cell);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: cellSize, height: cellSize),
          const Radius.circular(12),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // 2. Setinhas de movimento (MoveEvent) e swap (SwapEvent)
    for (final e in events) {
      if (e is MoveEvent) {
        _drawArrow(canvas, _center(e.from), _center(e.to), AppColors.haloMinus);
      } else if (e is SwapEvent) {
        _drawArrow(canvas, _center(e.cellA), _center(e.cellB), AppColors.haloMinus);
        _drawArrow(canvas, _center(e.cellB), _center(e.cellA), AppColors.haloMinus);
      }
    }

    // 3. X vermelho nas peças destruídas (DestroyEvent)
    for (final e in events) {
      if (e is! DestroyEvent) continue;
      final c = _center(e.from);
      final paint = Paint()
        ..color = AppColors.critical
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      final r = cellSize * 0.28;
      canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), paint);
      canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawLine(from, to, paint);
    // Cabeça da seta
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len;
    final uy = dy / len;
    const headLen = 10.0;
    const headWide = 6.0;
    final tip = to;
    final base = Offset(to.dx - ux * headLen, to.dy - uy * headLen);
    final left = Offset(base.dx - uy * headWide, base.dy + ux * headWide);
    final right = Offset(base.dx + uy * headWide, base.dy - ux * headWide);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.95));
  }

  @override
  bool shouldRepaint(_PreviewOverlayPainter old) => old.events != events;
}

/// Toast mostrado no topo do tabuleiro durante o preview de jogada.
/// Indica pontos projetados + se há roubo de peça.
class _PreviewToast extends StatelessWidget {
  final GameState state;
  final ActionResult result;

  const _PreviewToast({required this.state, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = state.currentPlayer;
    final them = me.opponent;
    final myPtsDiff = (result.newState.points[me] ?? 0) - (state.points[me] ?? 0);
    final theirPtsDiff = (result.newState.points[them] ?? 0) - (state.points[them] ?? 0);
    final stealCount = result.events.whereType<DestroyEvent>().length;

    final buf = StringBuffer(l10n.previewLabel);
    if (myPtsDiff > 0) buf.write('  ·  +$myPtsDiff');
    if (theirPtsDiff > 0) buf.write('  ·  ${l10n.previewOppGains(theirPtsDiff)}');
    if (stealCount > 0) buf.write('  ·  ${l10n.previewSteal(stealCount)}');
    if (myPtsDiff == 0 && theirPtsDiff == 0 && stealCount == 0) {
      buf.write('  ·  ${l10n.previewNoEffect}');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgVoid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.haloMinus.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.haloMinus.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Text(
        buf.toString(),
        style: AppTypography.monoSmall(color: AppColors.ink, size: 11),
      ),
    );
  }
}
