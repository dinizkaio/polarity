import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade — versão 6 (construção de padrões).
///
/// Mudança de paradigma: o jogo deixa de ser sobre **destruição** e passa a
/// ser sobre **construção de padrões**. Peças não são mais eliminadas em
/// colisões — apenas reposicionadas. Pontuação vem de linhas/colunas/diagonais.
///
/// **Movimento:**
///
/// 1. **Atração orbital (solo):** peça oposta vizinha do epicentro pula por
///    cima dele e cai na casa simétrica do outro lado (com wrap toroidal).
///    A casa simétrica está sempre vazia por construção: quando ela tem
///    peça oposta, a regra de PAR já é acionada primeiro.
///
/// 2. **Atração em par (swap):** se há peças opostas em DOIS lados do
///    epicentro (ex: N e S), elas tentam atravessar simultaneamente —
///    trocam de posição. Nenhuma é destruída.
///
/// 3. **Repulsão:** peça mesma polaridade tenta mover 1 casa pra longe do
///    epicentro (com wrap). Se a casa-destino estiver ocupada, **fica
///    parada** — sem cadeia, sem destruição.
///
/// 4. **Flip:** trocar polaridade vale 1 turno; a onda magnética dispara
///    imediatamente com a peça flipada como epicentro.
///
/// **Pontuação por padrões (no fim de cada turno):**
///
/// Identifica, em cada uma das 12 linhas possíveis (5 horizontais, 5
/// verticais, 2 diagonais), a maior subsequência consecutiva do mesmo dono:
///
/// | Comprimento | Polaridade | Pontos |
/// |---|---|---|
/// | 3 | qualquer | +1 |
/// | 4 | qualquer | +3 |
/// | 5 | mista | +5 |
/// | 5 | toda igual | +10 |
///
/// Pontuação acontece quando uma linha SUPERA seu próprio recorde histórico
/// (por dono). Evita farming passivo. Quando atinge 5, peças voltam pro
/// estoque do dono (reciclagem), recorde da linha reseta — pode pontuar de
/// novo na reconstrução.
///
/// **Fim de jogo:**
/// - Primeiro a chegar a 15 pontos vence imediatamente
/// - OU 20 turnos esgotados, vence quem tem mais pontos
/// - OU stalemate por inércia (4 ações vazias)
class GameLogic {
  /// 8 direções em ordem fixa. Pares opostos: (0,4), (1,5), (2,6), (3,7).
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

  static ActionResult? applyAction(GameState state, GameAction action) {
    if (state.isGameOver) return null;
    final owner = state.currentPlayer;
    final board = state.cloneBoard();
    final stock = Map<PieceOwner, int>.from(state.stock);
    final onBoard = Map<PieceOwner, int>.from(state.onBoard);
    final points = Map<PieceOwner, int>.from(state.points);
    final linesMaxLength = state.cloneLinesMaxLength();
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

    // ─── Detecta vizinhos imediatos (alcance 1) ───
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

    // ─── 1) Atração em par (swap) ───
    for (final pair in oppositePairs) {
      final iA = pair[0];
      final iB = pair[1];
      final cA = neighborByDir[iA];
      final cB = neighborByDir[iB];
      if (cA == null || cB == null) continue;
      final pA = board[cA.row][cA.col]!;
      final pB = board[cB.row][cB.col]!;
      if (pA.polarity == piece.polarity || pB.polarity == piece.polarity) continue;
      // Ambos opostos ao epicentro → swap
      events.add(ForceEvent(from: Cell(er, ec), to: cA, kind: ForceKind.attract));
      events.add(ForceEvent(from: Cell(er, ec), to: cB, kind: ForceKind.attract));
      board[cA.row][cA.col] = pB;
      board[cB.row][cB.col] = pA;
      events.add(SwapEvent(cellA: cA, cellB: cB, pieceA: pA, pieceB: pB));
      processed.add(iA);
      processed.add(iB);
    }

    // ─── 2) Atração solo (pula pra casa simétrica) ───
    for (int i = 0; i < dirs.length; i++) {
      if (processed.contains(i)) continue;
      final c = neighborByDir[i];
      if (c == null) continue;
      final p = board[c.row][c.col]!;
      if (p.polarity == piece.polarity) continue; // só opostos
      // Casa simétrica via wrap toroidal
      final tr = _wrapAxis(er - dirs[i][0]);
      final tc = _wrapAxis(ec - dirs[i][1]);
      events.add(ForceEvent(from: Cell(er, ec), to: c, kind: ForceKind.attract));
      if (board[tr][tc] != null) {
        // Casa ocupada — fica parada (caso raro com peça amiga oposta direção)
        continue;
      }
      board[c.row][c.col] = null;
      board[tr][tc] = p;
      events.add(MoveEvent(from: c, to: Cell(tr, tc), piece: p));
      processed.add(i);
    }

    // ─── 3) Repulsão (peça mesma polaridade, 1 casa, sem cadeia) ───
    for (int i = 0; i < dirs.length; i++) {
      if (processed.contains(i)) continue;
      final c = neighborByDir[i];
      if (c == null) continue;
      final p = board[c.row][c.col]!;
      if (p.polarity != piece.polarity) continue; // só mesma polaridade
      events.add(ForceEvent(from: Cell(er, ec), to: c, kind: ForceKind.repel));
      final tr = _wrapAxis(c.row + dirs[i][0]);
      final tc = _wrapAxis(c.col + dirs[i][1]);
      if (board[tr][tc] != null) continue; // destino ocupado, fica parada
      board[c.row][c.col] = null;
      board[tr][tc] = p;
      events.add(MoveEvent(from: c, to: Cell(tr, tc), piece: p));
      processed.add(i);
    }

    // ─── 4) Pontuação por linhas (após todos os movimentos) ───
    _scoreLines(
      board: board,
      points: points,
      linesMaxLength: linesMaxLength,
      stock: stock,
      onBoard: onBoard,
      events: events,
    );

    // ─── 5) Stalemate counter ───
    final hadEffect = events.any((e) => e is MoveEvent || e is SwapEvent || e is LineCompletedEvent);
    final isEmptyAction = action is FlipAction && !hadEffect;
    final newEmptyCount = isEmptyAction ? state.consecutiveEmptyActions + 1 : 0;

    // ─── 6) Fim de jogo ───
    final actionsTaken = state.actionsTaken + 1;
    final other = owner.opponent;
    PieceOwner? winner;
    bool gameEnded = false;

    // Vitória por pontos (15+)
    final playerPts = points[PieceOwner.player] ?? 0;
    final aiPts = points[PieceOwner.ai] ?? 0;
    if (playerPts >= GameState.winningPoints && playerPts > aiPts) {
      winner = PieceOwner.player;
      gameEnded = true;
    } else if (aiPts >= GameState.winningPoints && aiPts > playerPts) {
      winner = PieceOwner.ai;
      gameEnded = true;
    } else if (playerPts >= GameState.winningPoints && aiPts >= GameState.winningPoints) {
      // Ambos passaram do limiar no mesmo turno — desempata pelos pontos absolutos
      winner = playerPts > aiPts ? PieceOwner.player : (aiPts > playerPts ? PieceOwner.ai : null);
      gameEnded = true;
    } else if (actionsTaken >= GameState.maxActions) {
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
      linesMaxLength: linesMaxLength,
      consecutiveEmptyActions: newEmptyCount,
      actionsTaken: actionsTaken,
      currentPlayer: other,
      winner: winner,
    );

    return ActionResult(newState: newState, events: events);
  }

  /// Calcula pontuação e reciclagem para todas as linhas do tabuleiro.
  /// Modifica `points`, `linesMaxLength`, `stock`, `onBoard` e empilha
  /// LineCompletedEvent em `events`.
  static void _scoreLines({
    required List<List<Piece?>> board,
    required Map<PieceOwner, int> points,
    required Map<int, Map<PieceOwner, int>> linesMaxLength,
    required Map<PieceOwner, int> stock,
    required Map<PieceOwner, int> onBoard,
    required List<AnimationEvent> events,
  }) {
    // Fase 1: detecta e remove 5-em-linha (reciclagem). Pode haver múltiplas
    // 5-em-linhas no mesmo turno (raro, mas possível).
    bool changed = true;
    while (changed) {
      changed = false;
      for (int lineIdx = 0; lineIdx < GameState.totalLines; lineIdx++) {
        final cells = _lineCells(lineIdx);
        final pieces = cells.map((c) => board[c.row][c.col]).toList();
        final run = _findLongestRun(pieces);
        if (run.owner == null || run.length < 5) continue;
        if (run.startIndex != 0 || run.length != 5) continue; // 5-em-linha = linha inteira
        final owner = run.owner!;
        final uniform = run.uniformPolarity;
        final pts = uniform ? 10 : 5;
        points[owner] = (points[owner] ?? 0) + pts;
        // Remove peças, devolve estoque
        for (final cell in cells) {
          final p = board[cell.row][cell.col];
          if (p == null) continue;
          board[cell.row][cell.col] = null;
          onBoard[p.owner] = (onBoard[p.owner] ?? 0) - 1;
          stock[p.owner] = ((stock[p.owner] ?? 0) + 1).clamp(0, GameState.stockSize);
        }
        // Reseta histórico desta linha
        linesMaxLength[lineIdx]?[owner] = 0;
        events.add(LineCompletedEvent(
          cells: cells,
          owner: owner,
          length: 5,
          uniformPolarity: uniform,
          pointsEarned: pts,
          recycled: true,
        ));
        changed = true;
        break; // recomeça loop com board atualizado
      }
    }

    // Fase 2: detecta runs 3 e 4 — pontua apenas se SUPERA o recorde da linha
    for (int lineIdx = 0; lineIdx < GameState.totalLines; lineIdx++) {
      final cells = _lineCells(lineIdx);
      final pieces = cells.map((c) => board[c.row][c.col]).toList();
      final run = _findLongestRun(pieces);
      if (run.owner == null || run.length < 3 || run.length == 5) continue;
      final owner = run.owner!;
      final prevMax = linesMaxLength[lineIdx]?[owner] ?? 0;
      if (run.length <= prevMax) continue;
      // Pontua pelos NÍVEIS novos atingidos (cumulativo entre prevMax+1..run.length)
      int gained = 0;
      for (int level = prevMax + 1; level <= run.length; level++) {
        gained += _pointsForLevel(level, run.uniformPolarity);
      }
      points[owner] = (points[owner] ?? 0) + gained;
      linesMaxLength[lineIdx]?[owner] = run.length;
      // Cells da run (subsequência) — não a linha inteira
      final runCells = cells.sublist(run.startIndex, run.startIndex + run.length);
      events.add(LineCompletedEvent(
        cells: runCells,
        owner: owner,
        length: run.length,
        uniformPolarity: run.uniformPolarity,
        pointsEarned: gained,
        recycled: false,
      ));
    }
  }

  static int _pointsForLevel(int level, bool uniform) {
    switch (level) {
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

  /// Retorna as 5 células da linha [lineIdx]:
  /// 0..4 → linhas horizontais (rows 0..4)
  /// 5..9 → colunas (cols 0..4)
  /// 10 → diagonal principal (0,0)..(4,4)
  /// 11 → antidiagonal (0,4)..(4,0)
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

  /// Encontra a maior subsequência consecutiva do mesmo dono numa linha.
  /// Retorna comprimento, dono, índice inicial e se a polaridade é uniforme.
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

  /// Decide vencedor em fim por contagem (max ações ou stalemate).
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
    return null; // empate técnico
  }

  /// Lista todas as ações legais para o jogador da vez.
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
