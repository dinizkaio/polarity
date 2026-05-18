import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade. Funções puras, sem UI.
///
/// Especificação: 8 vizinhos do epicentro reagem na ORDEM FIXA
/// N → NE → E → SE → S → SW → W → NW. Onda única — peças que se movem
/// por reação NÃO geram nova onda.
class GameLogic {
  /// 8 direções em ordem fixa: [dRow, dCol]
  static const List<List<int>> dirs = [
    [-1, 0],  // N
    [-1, 1],  // NE
    [0, 1],   // E
    [1, 1],   // SE
    [1, 0],   // S
    [1, -1],  // SW
    [0, -1],  // W
    [-1, -1], // NW
  ];

  static int _idCounter = 0;
  static int _nextId() => ++_idCounter;

  static bool _inBounds(int r, int c) =>
      r >= 0 && r < GameState.boardSize && c >= 0 && c < GameState.boardSize;

  /// Resultado da aplicação de uma ação: novo estado + lista ordenada de eventos pra animar.
  /// Retorna null se a ação for inválida.
  static ActionResult? applyAction(GameState state, GameAction action) {
    if (state.isGameOver) return null;
    final owner = state.currentPlayer;
    final board = state.cloneBoard();
    final stock = Map<PieceOwner, int>.from(state.stock);
    final onBoard = Map<PieceOwner, int>.from(state.onBoard);
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

    // Resolve onda na ordem fixa
    for (final dir in dirs) {
      final dr = dir[0];
      final dc = dir[1];
      final nr = er + dr;
      final nc = ec + dc;
      if (!_inBounds(nr, nc)) continue;
      final neighbor = board[nr][nc];
      if (neighbor == null) continue;

      final same = neighbor.polarity == piece.polarity;

      if (!same) {
        // Atração: vizinho move 1 casa em direção ao epicentro (-dr, -dc)
        final tr = nr - dr;
        final tc = nc - dc;
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nr, nc),
          kind: ForceKind.attract,
        ));
        // Destino é a casa do epicentro (ocupada) → atração SEMPRE bloqueia
        // se peça vizinha for adjacente. Implementação: se destino fora ou ocupado → shake.
        if (!_inBounds(tr, tc) || board[tr][tc] != null) {
          events.add(ShakeEvent(Cell(nr, nc)));
        } else {
          board[tr][tc] = neighbor;
          board[nr][nc] = null;
          events.add(MoveEvent(
            from: Cell(nr, nc),
            to: Cell(tr, tc),
            piece: neighbor,
          ));
        }
      } else {
        // Repulsão: cadeia ao longo de +dir
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nr, nc),
          kind: ForceKind.repel,
        ));

        // Coleta cadeia de peças consecutivas a partir do vizinho
        final chain = <List<int>>[];
        int cr = nr;
        int cc = nc;
        while (_inBounds(cr, cc) && board[cr][cc] != null) {
          chain.add([cr, cc]);
          cr += dr;
          cc += dc;
        }

        // Aplica do fim pro começo (assim a primeira posição libera espaço pra próxima)
        for (int k = chain.length - 1; k >= 0; k--) {
          final pr = chain[k][0];
          final pc = chain[k][1];
          final tr = pr + dr;
          final tc = pc + dc;
          final moving = board[pr][pc]!;
          board[pr][pc] = null;
          if (!_inBounds(tr, tc)) {
            // Peça sai do tabuleiro → remoção pura
            onBoard[moving.owner] = (onBoard[moving.owner] ?? 0) - 1;
            events.add(DestroyEvent(
              from: Cell(pr, pc),
              direction: [dr, dc],
              piece: moving,
            ));
          } else {
            board[tr][tc] = moving;
            events.add(MoveEvent(
              from: Cell(pr, pc),
              to: Cell(tr, tc),
              piece: moving,
              chainIndex: chain.length - 1 - k,
            ));
          }
        }
      }
    }

    // Check de vitória
    final actionsTaken = state.actionsTaken + 1;
    final other = owner == PieceOwner.player ? PieceOwner.ai : PieceOwner.player;
    PieceOwner? winner;

    if ((onBoard[other] ?? 0) == 0 && (stock[other] ?? 0) == 0) {
      winner = owner;
    } else if ((onBoard[owner] ?? 0) == 0 && (stock[owner] ?? 0) == 0) {
      winner = other;
    } else if (actionsTaken >= GameState.maxActions) {
      final p = onBoard[PieceOwner.player] ?? 0;
      final a = onBoard[PieceOwner.ai] ?? 0;
      if (p > a) {
        winner = PieceOwner.player;
      } else if (a > p) {
        winner = PieceOwner.ai;
      } else {
        // Regra do "pie" simplificada: empate → P2 (IA)
        winner = PieceOwner.ai;
      }
    }

    if (winner != null) events.add(EndEvent(winner));

    final newState = state.copyWith(
      board: board,
      stock: stock,
      onBoard: onBoard,
      actionsTaken: actionsTaken,
      currentPlayer: other,
      winner: winner,
    );

    return ActionResult(newState: newState, events: events);
  }

  /// Lista todas as ações legais para o jogador da vez.
  static List<GameAction> legalActions(GameState state) {
    final actions = <GameAction>[];
    final owner = state.currentPlayer;

    // Place: se ainda há estoque
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

    // Flip: peças do dono atual
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
