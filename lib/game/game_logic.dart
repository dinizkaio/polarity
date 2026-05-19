import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade — versão 2 (física revista).
///
/// Mudanças em relação à v1:
///
/// 1. **Atração agora produz movimento real ("passagem orbital"):**
///    Vizinho de polaridade oposta é atraído com força tal que passa pelo
///    epicentro e cai do outro lado, na casa simétrica (er - dr, ec - dc).
///    Se essa casa estiver ocupada, a cadeia continua na mesma direção.
///    Se sair do tabuleiro → peça destruída. Isso resolve a falha da v1
///    onde a atração nunca produzia movimento (sempre bloqueada pelo
///    próprio epicentro).
///
/// 2. **Carga (Charge):** peças acumulam +1 charge cada vez que sobrevivem
///    a uma força. Quando charge atinge 3 (`Piece.maxCharge`), a peça
///    fica **carregada**. Carregadas como EPICENTRO têm alcance 2 — a onda
///    alcança peças a 1 e 2 casas. Após disparar como epicentro, charge zera.
///
/// 3. **Ressonância:** se uma única onda destrói 2+ peças do oponente, o
///    dono do epicentro ganha +1 peça no estoque (até o limite). 3+ → +2.
///
/// 4. **Desempate justo:** empate em ações máximas é resolvido pelas
///    destruições totais (`state.destroyed`). Empate persistente → empate
///    técnico (sem mais regra do pie arbitrária).
///
/// 5. **Vizinhos reagem em ordem fixa N→NE→E→SE→S→SW→W→NW.** Onda única —
///    peças que se movem por reação NÃO geram nova onda.
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

  /// Distância de alcance da onda. Peça carregada como epicentro estende
  /// para 2 casas.
  static const int normalRange = 1;
  static const int chargedRange = 2;

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
    final destroyed = Map<PieceOwner, int>.from(state.destroyed);
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

    final epicenterWasCharged = piece.isCharged;
    events.add(EpicenterEvent(Cell(er, ec), isCharged: epicenterWasCharged));

    final range = epicenterWasCharged ? chargedRange : normalRange;
    int destroyedThisWave = 0;

    // Resolve onda. Para cada direção, procura a PRIMEIRA peça dentro do
    // alcance. Se range = 2, a peça a 1 casa reage normalmente; se 1 casa
    // está vazia, olha a 2 casas (a onda "vaza" através do vazio).
    for (final dir in dirs) {
      final dr = dir[0];
      final dc = dir[1];

      int? nr;
      int? nc;
      for (int step = 1; step <= range; step++) {
        final cr = er + dr * step;
        final cc = ec + dc * step;
        if (!_inBounds(cr, cc)) break;
        if (board[cr][cc] != null) {
          nr = cr;
          nc = cc;
          break;
        }
      }
      if (nr == null || nc == null) continue;

      final neighbor = board[nr][nc]!;
      final same = neighbor.polarity == piece.polarity;

      if (!same) {
        // ─── ATRAÇÃO (passagem orbital) ───
        // Peça oposta passa pelo epicentro e cai na casa simétrica.
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nr, nc),
          kind: ForceKind.attract,
        ));

        final moveDr = -dr;
        final moveDc = -dc;
        final landingR = er + moveDr; // casa simétrica do outro lado do epicentro
        final landingC = ec + moveDc;

        if (!_inBounds(landingR, landingC)) {
          // Sai do tabuleiro → destruída
          board[nr][nc] = null;
          onBoard[neighbor.owner] = (onBoard[neighbor.owner] ?? 0) - 1;
          if (neighbor.owner != owner) {
            destroyed[owner] = (destroyed[owner] ?? 0) + 1;
            destroyedThisWave++;
          }
          events.add(DestroyEvent(
            from: Cell(nr, nc),
            direction: [moveDr, moveDc],
            piece: neighbor,
          ));
        } else if (board[landingR][landingC] == null) {
          // Casa simétrica vazia → aterrissa com +1 charge
          board[nr][nc] = null;
          final landed = neighbor.bumpCharge();
          board[landingR][landingC] = landed;
          events.add(MoveEvent(
            from: Cell(nr, nc),
            to: Cell(landingR, landingC),
            piece: landed,
          ));
          if (landed.charge > neighbor.charge) {
            events.add(ChargeEvent(
              at: Cell(landingR, landingC),
              newCharge: landed.charge,
              becameCharged: landed.isCharged && !neighbor.isCharged,
            ));
          }
        } else {
          // Cadeia: empurra o que estiver depois da casa simétrica
          final chainOut = _resolveChainPush(
            board: board,
            startR: landingR,
            startC: landingC,
            dr: moveDr,
            dc: moveDc,
            ownerOfEpicenter: owner,
            onBoard: onBoard,
            destroyed: destroyed,
            events: events,
            firstChainIndex: 1,
          );
          destroyedThisWave += chainOut.destroyed;
          // Casa simétrica agora vazia → peça atraída ocupa
          board[nr][nc] = null;
          final landed = neighbor.bumpCharge();
          board[landingR][landingC] = landed;
          events.add(MoveEvent(
            from: Cell(nr, nc),
            to: Cell(landingR, landingC),
            piece: landed,
            chainIndex: 0,
          ));
          if (landed.charge > neighbor.charge) {
            events.add(ChargeEvent(
              at: Cell(landingR, landingC),
              newCharge: landed.charge,
              becameCharged: landed.isCharged && !neighbor.isCharged,
            ));
          }
        }
      } else {
        // ─── REPULSÃO ───
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nr, nc),
          kind: ForceKind.repel,
        ));
        final chainOut = _resolveChainPush(
          board: board,
          startR: nr,
          startC: nc,
          dr: dr,
          dc: dc,
          ownerOfEpicenter: owner,
          onBoard: onBoard,
          destroyed: destroyed,
          events: events,
          firstChainIndex: 0,
        );
        destroyedThisWave += chainOut.destroyed;
      }
    }

    if (epicenterWasCharged) {
      final reset = piece.resetCharge();
      board[er][ec] = reset;
      piece = reset;
      events.add(ChargeEvent(at: Cell(er, ec), newCharge: 0));
    }

    int bonus = 0;
    if (destroyedThisWave >= 2) {
      bonus = destroyedThisWave >= 3 ? 2 : 1;
      final current = stock[owner] ?? 0;
      final maxStock = GameState.stockSize;
      final effective = (current + bonus).clamp(0, maxStock) - current;
      if (effective > 0) {
        stock[owner] = current + effective;
      }
      events.add(ResonanceEvent(
        owner: owner,
        destroyedCount: destroyedThisWave,
        bonus: effective,
      ));
    }

    final actionsTaken = state.actionsTaken + 1;
    final other = owner.opponent;
    PieceOwner? winner;
    bool reachedMax = false;

    if ((onBoard[other] ?? 0) == 0 && (stock[other] ?? 0) == 0) {
      winner = owner;
    } else if ((onBoard[owner] ?? 0) == 0 && (stock[owner] ?? 0) == 0) {
      winner = other;
    } else if (actionsTaken >= GameState.maxActions) {
      reachedMax = true;
      final p = onBoard[PieceOwner.player] ?? 0;
      final a = onBoard[PieceOwner.ai] ?? 0;
      if (p > a) {
        winner = PieceOwner.player;
      } else if (a > p) {
        winner = PieceOwner.ai;
      } else {
        final dp = destroyed[PieceOwner.player] ?? 0;
        final da = destroyed[PieceOwner.ai] ?? 0;
        if (dp > da) {
          winner = PieceOwner.player;
        } else if (da > dp) {
          winner = PieceOwner.ai;
        } else {
          winner = null; // empate técnico
        }
      }
    }

    if (winner != null || reachedMax) {
      events.add(EndEvent(winner));
    }

    final newState = state.copyWith(
      board: board,
      stock: stock,
      onBoard: onBoard,
      destroyed: destroyed,
      actionsTaken: actionsTaken,
      currentPlayer: other,
      winner: winner,
    );

    return ActionResult(newState: newState, events: events);
  }

  /// Resolve cadeia de empurrão a partir de uma posição inicial na direção (dr,dc).
  /// Peças consecutivas são deslocadas; última pode ser destruída se sair do tabuleiro.
  /// Modifica `board`, `onBoard`, `destroyed` e empilha eventos.
  /// Retorna quantas peças DO OPONENTE foram destruídas.
  static _ChainOut _resolveChainPush({
    required List<List<Piece?>> board,
    required int startR,
    required int startC,
    required int dr,
    required int dc,
    required PieceOwner ownerOfEpicenter,
    required Map<PieceOwner, int> onBoard,
    required Map<PieceOwner, int> destroyed,
    required List<AnimationEvent> events,
    required int firstChainIndex,
  }) {
    final chain = <List<int>>[];
    int cr = startR;
    int cc = startC;
    while (_inBounds(cr, cc) && board[cr][cc] != null) {
      chain.add([cr, cc]);
      cr += dr;
      cc += dc;
    }
    if (chain.isEmpty) return const _ChainOut(0);

    int dest = 0;
    for (int k = chain.length - 1; k >= 0; k--) {
      final pr = chain[k][0];
      final pc = chain[k][1];
      final tr = pr + dr;
      final tc = pc + dc;
      final moving = board[pr][pc]!;
      board[pr][pc] = null;
      if (!_inBounds(tr, tc)) {
        onBoard[moving.owner] = (onBoard[moving.owner] ?? 0) - 1;
        if (moving.owner != ownerOfEpicenter) {
          destroyed[ownerOfEpicenter] = (destroyed[ownerOfEpicenter] ?? 0) + 1;
          dest++;
        }
        events.add(DestroyEvent(
          from: Cell(pr, pc),
          direction: [dr, dc],
          piece: moving,
        ));
      } else {
        final landed = moving.bumpCharge();
        board[tr][tc] = landed;
        events.add(MoveEvent(
          from: Cell(pr, pc),
          to: Cell(tr, tc),
          piece: landed,
          chainIndex: firstChainIndex + (chain.length - 1 - k),
        ));
        if (landed.charge > moving.charge) {
          events.add(ChargeEvent(
            at: Cell(tr, tc),
            newCharge: landed.charge,
            becameCharged: landed.isCharged && !moving.isCharged,
          ));
        }
      }
    }
    return _ChainOut(dest);
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

class _ChainOut {
  final int destroyed;
  const _ChainOut(this.destroyed);
}
