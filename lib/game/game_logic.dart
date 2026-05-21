import 'dart:math';

import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade — versão 7.
///
/// **Movimento (sem destruição em colisão):**
///
/// 1. Pares opostos detectados primeiro → SWAP (ambas opostas ao epicentro,
///    em direções contrárias).
///
/// 2. Solo: peças MINHAS (mesmo dono que o epicentro) processadas antes das
///    do oponente. Em cada categoria, ordem fixa N→NE→E→SE→S→SW→W→NW.
///    - Oposta → atração orbital pra casa simétrica (com wrap).
///    - Mesma polaridade → repulsão 1 casa pra longe (com wrap). Se destino
///      ocupado, fica parada.
///
/// **Pontuação por padrões (recontagem total a cada turno):**
///
/// No fim de cada ação, varre as 12 linhas. Pra cada uma com run >= 3 do
/// mesmo dono, soma pontos ao placar:
///
/// | Run | Polaridade | Pontos |
/// |---|---|---|
/// | 3 | qualquer | +1 |
/// | 4 | qualquer | +3 |
/// | 5 | mista | +5 |
/// | 5 | toda igual | +10 |
///
/// Formações ativas pontuam DE NOVO em cada turno em que permanecem
/// completas. Manter formação por vários turnos é estrategicamente
/// valioso, mas o oponente pode mover suas peças via ondas magnéticas
/// pra quebrá-las.
///
/// **Efeito do 5-em-linha:** quando uma 5-em-linha se FORMA (delta vs estado
/// anterior), o dono tira 1 peça aleatória do oponente do tabuleiro
/// (destruída permanentemente — não volta pro estoque).
///
/// **Fim de jogo:**
/// - Primeiro a chegar a 15 pontos vence imediatamente
/// - OU [state.maxTurns] turnos esgotados, vence quem tem mais pontos
/// - OU stalemate por inércia (4 ações vazias)
class GameLogic {
  static const List<List<int>> dirs = [
    [-1, 0],  // 0 N
    [-1, 1],  // 1 NE
    [0, 1],   // 2 E
    [1, 1],   // 3 SE
    [1, 0],   // 4 S
    [1, -1],  // 5 SW
    [0, -1],  // 6 W
    [-1, -1], // 7 NW
  ];

  static const List<List<int>> oppositePairs = [
    [0, 4],
    [1, 5],
    [2, 6],
    [3, 7],
  ];

  static int _idCounter = 0;
  static int _nextId() => ++_idCounter;

  static int _wrapAxis(int v) {
    final n = GameState.boardSize;
    return ((v % n) + n) % n;
  }

  static ActionResult? applyAction(GameState state, GameAction action,
      {Random? rng}) {
    if (state.isGameOver) return null;
    final random = rng ?? Random();
    final owner = state.currentPlayer;
    final board = state.cloneBoard();
    final stock = Map<PieceOwner, int>.from(state.stock);
    final onBoard = Map<PieceOwner, int>.from(state.onBoard);
    final points = Map<PieceOwner, int>.from(state.points);
    final events = <AnimationEvent>[];

    int er;
    int ec;
    Piece piece;

    switch (action) {
      case PlaceAction(:final row, :final col, :final polarity):
        if (board[row][col] != null) return null;
        if ((stock[owner] ?? 0) <= 0) return null;
        piece = Piece(id: _nextId(), owner: owner, polarity: polarity);
        board[row][col] = piece;
        stock[owner] = (stock[owner] ?? 0) - 1;
        onBoard[owner] = (onBoard[owner] ?? 0) + 1;
        er = row;
        ec = col;
        events.add(PlaceEvent(at: Cell(row, col), piece: piece));

      case FlipAction(:final row, :final col):
        final existing = board[row][col];
        if (existing == null || existing.owner != owner) return null;
        piece = existing.copyWith(polarity: existing.polarity.opposite);
        board[row][col] = piece;
        er = row;
        ec = col;
        events.add(FlipEvent(at: Cell(row, col), piece: piece));
    }

    events.add(EpicenterEvent(Cell(er, ec)));

    // ─── Detecta vizinhos imediatos (alcance 1, sem wrap pra detecção) ───
    final neighborByDir = <int, Cell>{};
    for (int i = 0; i < dirs.length; i++) {
      final nr = er + dirs[i][0];
      final nc = ec + dirs[i][1];
      if (nr < 0 || nr >= GameState.boardSize || nc < 0 || nc >= GameState.boardSize) {
        continue;
      }
      if (board[nr][nc] != null) {
        neighborByDir[i] = Cell(nr, nc);
      }
    }

    final processed = <int>{};

    // ─── 1) Atração em par (swap) — processada primeiro, regardless dono ───
    for (final pair in oppositePairs) {
      final iA = pair[0];
      final iB = pair[1];
      final cA = neighborByDir[iA];
      final cB = neighborByDir[iB];
      if (cA == null || cB == null) continue;
      final pA = board[cA.row][cA.col]!;
      final pB = board[cB.row][cB.col]!;
      if (pA.polarity == piece.polarity || pB.polarity == piece.polarity) continue;
      events.add(ForceEvent(from: Cell(er, ec), to: cA, kind: ForceKind.attract));
      events.add(ForceEvent(from: Cell(er, ec), to: cB, kind: ForceKind.attract));
      board[cA.row][cA.col] = pB;
      board[cB.row][cB.col] = pA;
      events.add(SwapEvent(cellA: cA, cellB: cB, pieceA: pA, pieceB: pB));
      processed.add(iA);
      processed.add(iB);
    }

    // ─── 2) Solos do MESMO DONO primeiro (prioridade) ───
    _processSolos(
      board: board, neighborByDir: neighborByDir, processed: processed,
      epicenter: Cell(er, ec), epicenterPolarity: piece.polarity,
      onlyOwner: owner, events: events,
    );

    // ─── 3) Solos do OPONENTE ───
    _processSolos(
      board: board, neighborByDir: neighborByDir, processed: processed,
      epicenter: Cell(er, ec), epicenterPolarity: piece.polarity,
      onlyOwner: owner.opponent, events: events,
    );

    // ─── 4) Detecta linhas com 5-em-linha (delta vs estado anterior) ───
    final newLinesWithFive = <int, PieceOwner>{};
    for (int lineIdx = 0; lineIdx < GameState.totalLines; lineIdx++) {
      final cells = _lineCells(lineIdx);
      final pieces = cells.map((c) => board[c.row][c.col]).toList();
      final run = _findLongestRun(pieces);
      if (run.length == 5 && run.startIndex == 0 && run.owner != null) {
        newLinesWithFive[lineIdx] = run.owner!;
      }
    }
    // Linhas que ficaram completas AGORA mas não estavam no estado anterior
    // → tira 1 peça do oponente pra cada uma
    for (final entry in newLinesWithFive.entries) {
      final wasAlready = state.linesWithFive[entry.key] == entry.value;
      if (wasAlready) continue;
      _stealOpponentPiece(
        board: board, owner: entry.value, onBoard: onBoard,
        events: events, random: random,
      );
    }

    // ─── 5) Recontagem total de pontos (todas as formações ativas) ───
    final lineEvents = <LineCompletedEvent>[];
    for (int lineIdx = 0; lineIdx < GameState.totalLines; lineIdx++) {
      final cells = _lineCells(lineIdx);
      final pieces = cells.map((c) => board[c.row][c.col]).toList();
      final run = _findLongestRun(pieces);
      if (run.owner == null || run.length < 3) continue;
      final pts = _pointsForLength(run.length, run.uniformPolarity);
      points[run.owner!] = (points[run.owner!] ?? 0) + pts;
      final runCells = cells.sublist(run.startIndex, run.startIndex + run.length);
      lineEvents.add(LineCompletedEvent(
        cells: runCells,
        owner: run.owner!,
        length: run.length,
        uniformPolarity: run.uniformPolarity,
        pointsEarned: pts,
        recycled: false,
      ));
    }
    events.addAll(lineEvents);

    // ─── 6) Stalemate counter ───
    final hadEffect = events.any((e) =>
        e is MoveEvent || e is SwapEvent || e is DestroyEvent || lineEvents.isNotEmpty);
    final isEmptyAction = action is FlipAction && !hadEffect;
    final newEmptyCount = isEmptyAction ? state.consecutiveEmptyActions + 1 : 0;

    // ─── 7) Fim de jogo ───
    final actionsTaken = state.actionsTaken + 1;
    final other = owner.opponent;
    PieceOwner? winner;
    bool gameEnded = false;

    final playerPts = points[PieceOwner.player] ?? 0;
    final aiPts = points[PieceOwner.ai] ?? 0;
    if (playerPts >= GameState.winningPoints && playerPts > aiPts) {
      winner = PieceOwner.player;
      gameEnded = true;
    } else if (aiPts >= GameState.winningPoints && aiPts > playerPts) {
      winner = PieceOwner.ai;
      gameEnded = true;
    } else if (playerPts >= GameState.winningPoints && aiPts >= GameState.winningPoints) {
      winner = playerPts > aiPts ? PieceOwner.player : (aiPts > playerPts ? PieceOwner.ai : null);
      gameEnded = true;
    } else if (actionsTaken >= state.maxActions) {
      gameEnded = true;
      winner = _decideWinnerByPoints(points, onBoard);
    } else if (newEmptyCount >= GameState.stalemateThreshold) {
      gameEnded = true;
      winner = _decideWinnerByPoints(points, onBoard);
    }

    if (gameEnded) events.add(EndEvent(winner));

    final newState = state.copyWith(
      board: board,
      stock: stock,
      onBoard: onBoard,
      points: points,
      linesWithFive: newLinesWithFive,
      consecutiveEmptyActions: newEmptyCount,
      actionsTaken: actionsTaken,
      currentPlayer: other,
      winner: winner,
    );

    return ActionResult(newState: newState, events: events);
  }

  /// Processa atrações orbitais e repulsões para vizinhos pertencentes a
  /// [onlyOwner]. Modifica `board` e `events`. Marca direções em `processed`.
  static void _processSolos({
    required List<List<Piece?>> board,
    required Map<int, Cell> neighborByDir,
    required Set<int> processed,
    required Cell epicenter,
    required Polarity epicenterPolarity,
    required PieceOwner onlyOwner,
    required List<AnimationEvent> events,
  }) {
    final er = epicenter.row;
    final ec = epicenter.col;

    for (int i = 0; i < dirs.length; i++) {
      if (processed.contains(i)) continue;
      final c = neighborByDir[i];
      if (c == null) continue;
      final p = board[c.row][c.col];
      if (p == null || p.owner != onlyOwner) continue;

      if (p.polarity != epicenterPolarity) {
        // Atração orbital solo: pula pra casa simétrica
        events.add(ForceEvent(from: epicenter, to: c, kind: ForceKind.attract));
        final tr = _wrapAxis(er - dirs[i][0]);
        final tc = _wrapAxis(ec - dirs[i][1]);
        if (board[tr][tc] != null) {
          // Casa simétrica ocupada (raro com priorização) → fica parada
          processed.add(i);
          continue;
        }
        board[c.row][c.col] = null;
        board[tr][tc] = p;
        events.add(MoveEvent(from: c, to: Cell(tr, tc), piece: p));
      } else {
        // Repulsão: 1 casa pra longe
        events.add(ForceEvent(from: epicenter, to: c, kind: ForceKind.repel));
        final tr = _wrapAxis(c.row + dirs[i][0]);
        final tc = _wrapAxis(c.col + dirs[i][1]);
        if (board[tr][tc] != null) {
          processed.add(i);
          continue;
        }
        board[c.row][c.col] = null;
        board[tr][tc] = p;
        events.add(MoveEvent(from: c, to: Cell(tr, tc), piece: p));
      }
      processed.add(i);
    }
  }

  /// Tira 1 peça aleatória do oponente do tabuleiro. Destrutiva (não volta
  /// ao estoque). Sem efeito se oponente não tem peças no board.
  static void _stealOpponentPiece({
    required List<List<Piece?>> board,
    required PieceOwner owner,
    required Map<PieceOwner, int> onBoard,
    required List<AnimationEvent> events,
    required Random random,
  }) {
    final opponent = owner.opponent;
    final candidates = <Cell>[];
    for (int r = 0; r < GameState.boardSize; r++) {
      for (int c = 0; c < GameState.boardSize; c++) {
        final p = board[r][c];
        if (p?.owner == opponent) candidates.add(Cell(r, c));
      }
    }
    if (candidates.isEmpty) return;
    final cell = candidates[random.nextInt(candidates.length)];
    final piece = board[cell.row][cell.col]!;
    board[cell.row][cell.col] = null;
    onBoard[opponent] = (onBoard[opponent] ?? 0) - 1;
    events.add(DestroyEvent(from: cell, piece: piece));
  }

  static int _pointsForLength(int length, bool uniform) {
    switch (length) {
      case 3:
        return 1;
      case 4:
        return 3;
      case 5:
        return uniform ? 10 : 5;
      default:
        return 0;
    }
  }

  static List<Cell> _lineCells(int lineIdx) {
    final n = GameState.boardSize;
    if (lineIdx < 5) {
      final row = lineIdx;
      return [for (int c = 0; c < n; c++) Cell(row, c)];
    } else if (lineIdx < 10) {
      final col = lineIdx - 5;
      return [for (int r = 0; r < n; r++) Cell(r, col)];
    } else if (lineIdx == 10) {
      return [for (int i = 0; i < n; i++) Cell(i, i)];
    } else {
      return [for (int i = 0; i < n; i++) Cell(i, n - 1 - i)];
    }
  }

  static _RunResult _findLongestRun(List<Piece?> pieces) {
    PieceOwner? bestOwner;
    int bestLength = 0;
    int bestStart = 0;
    bool bestUniform = false;

    PieceOwner? curOwner;
    int curStart = 0;
    int curLength = 0;
    Polarity? curPolarity;
    bool curUniform = true;

    void flush() {
      if (curLength > bestLength && curOwner != null) {
        bestOwner = curOwner;
        bestLength = curLength;
        bestStart = curStart;
        bestUniform = curUniform;
      }
    }

    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      if (p == null) {
        flush();
        curOwner = null;
        curLength = 0;
        curPolarity = null;
        curUniform = true;
        continue;
      }
      if (p.owner != curOwner) {
        flush();
        curOwner = p.owner;
        curStart = i;
        curLength = 1;
        curPolarity = p.polarity;
        curUniform = true;
      } else {
        curLength++;
        if (curPolarity != null && p.polarity != curPolarity) curUniform = false;
      }
    }
    flush();

    return _RunResult(
      owner: bestOwner,
      length: bestLength,
      startIndex: bestStart,
      uniformPolarity: bestUniform,
    );
  }

  static PieceOwner? _decideWinnerByPoints(
    Map<PieceOwner, int> points,
    Map<PieceOwner, int> onBoard,
  ) {
    final p = points[PieceOwner.player] ?? 0;
    final a = points[PieceOwner.ai] ?? 0;
    if (p > a) return PieceOwner.player;
    if (a > p) return PieceOwner.ai;
    final pB = onBoard[PieceOwner.player] ?? 0;
    final aB = onBoard[PieceOwner.ai] ?? 0;
    if (pB > aB) return PieceOwner.player;
    if (aB > pB) return PieceOwner.ai;
    return null;
  }

  static List<GameAction> legalActions(GameState state) {
    final actions = <GameAction>[];
    final owner = state.currentPlayer;

    if ((state.stock[owner] ?? 0) > 0) {
      for (int r = 0; r < GameState.boardSize; r++) {
        for (int c = 0; c < GameState.boardSize; c++) {
          if (state.board[r][c] == null) {
            actions.add(PlaceAction(row: r, col: c, polarity: Polarity.plus));
            actions.add(PlaceAction(row: r, col: c, polarity: Polarity.minus));
          }
        }
      }
    }

    for (int r = 0; r < GameState.boardSize; r++) {
      for (int c = 0; c < GameState.boardSize; c++) {
        final p = state.board[r][c];
        if (p != null && p.owner == owner) {
          actions.add(FlipAction(row: r, col: c));
        }
      }
    }

    return actions;
  }
}

class ActionResult {
  final GameState newState;
  final List<AnimationEvent> events;
  const ActionResult({required this.newState, required this.events});
}

class _RunResult {
  final PieceOwner? owner;
  final int length;
  final int startIndex;
  final bool uniformPolarity;
  const _RunResult({
    required this.owner,
    required this.length,
    required this.startIndex,
    required this.uniformPolarity,
  });
}
