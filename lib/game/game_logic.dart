import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade — versão 5 (passagem orbital + pares).
///
/// **Atração agora salta pelo epicentro** (em vez de mover em direção a ele).
/// A peça oposta vizinha "pula por cima" do epicentro e aterrissa na casa
/// simétrica do outro lado. Resolve o problema de tabuleiro vazio: peças
/// agora podem coexistir vizinhas sem se aniquilar a cada ação.
///
/// 1. **Tabuleiro toroidal:** peças nunca caem fora. Movimento que sairia
///    pela borda reaparece no lado oposto.
///
/// 2. **Atração (passagem orbital):**
///    - Solo: peça oposta a step S do epicentro pula pra step S do LADO
///      OPOSTO (posição simétrica em relação ao epicentro). Charge +1.
///    - Pares: peças opostas em ambos os lados (ex: N e S) tentam atravessar
///      o epicentro simultaneamente; colidem no meio → ambas aniquiladas
///      (epicentro intacto). Esta é a jogada-chave do jogo.
///    - Destino ocupado (raro, geralmente via wrap): atraída destruída.
///
/// 3. **Repulsão:**
///    - Peça mesma polaridade tenta mover 1 casa para longe do epicentro
///      (+1 charge). Vetor: (dr, dc) saindo do epicentro.
///    - Destino calculado COM wrap toroidal.
///    - Se destino é vazio → move.
///    - Se destino é ocupado → repelida destruída, destino sobrevive.
///    - Sem cadeia — single hit.
///
/// 4. **Carga (Pulsar):** peça com 3+ charges, como epicentro, alcance da
///    onda dobra para 2 (vaza por casas vazias). Charge zera após disparar.
///
/// 5. **Ressonância:** destruir 2+ peças do oponente em uma onda → +1
///    no estoque (3+ → +2), respeitando teto de 10.
///
/// 6. **Fim por stalemate:** ambos estoques zerados E nenhuma peça com
///    vizinho a ≤ alcance máximo → partida termina, decide por maior
///    onBoard com desempate por destroyed.
///
/// 7. **Primeiro jogador aleatório:** `GameState.newGame()` sorteia 50/50.
class GameLogic {
  /// 8 direções em ordem fixa: [dRow, dCol]. Índices:
  /// 0=N · 1=NE · 2=E · 3=SE · 4=S · 5=SW · 6=W · 7=NW.
  /// Pares opostos: (0,4) (1,5) (2,6) (3,7).
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

  /// Pares de direções opostas. Cada elemento é [indexA, indexB].
  static const List<List<int>> oppositePairs = [
    [0, 4],  // N + S
    [1, 5],  // NE + SW
    [2, 6],  // E + W
    [3, 7],  // SE + NW
  ];

  /// Alcance da onda. Pulsar dobra.
  static const int normalRange = 1;
  static const int chargedRange = 2;

  static int _idCounter = 0;
  static int _nextId() => ++_idCounter;

  /// Wrap toroidal: traz coordenadas pra dentro do tabuleiro.
  static int _wrapAxis(int v) {
    final n = GameState.boardSize;
    return ((v % n) + n) % n;
  }

  static Cell _wrap(int r, int c) => Cell(_wrapAxis(r), _wrapAxis(c));

  /// Aplica a ação. Retorna `null` se inválida.
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

    // ─── 1) Detecção: qual vizinho está em cada direção (1ª peça encontrada) ───
    // Para alcance 2, a onda "vaza" por uma casa vazia adjacente ao epicentro
    // e pega a peça a 2 casas. Sem wrap aqui — vizinhança magnética é local.
    final neighborByDir = <int, _Neighbor>{};
    for (int i = 0; i < dirs.length; i++) {
      final dr = dirs[i][0];
      final dc = dirs[i][1];
      for (int step = 1; step <= range; step++) {
        final nr = er + dr * step;
        final nc = ec + dc * step;
        // Detecção de vizinho NÃO usa wrap — só vê peças "em linha de visão"
        // dentro do tabuleiro real.
        if (nr < 0 || nr >= GameState.boardSize || nc < 0 || nc >= GameState.boardSize) {
          break;
        }
        if (board[nr][nc] != null) {
          neighborByDir[i] = _Neighbor(row: nr, col: nc, step: step);
          break;
        }
      }
    }

    // ─── 2) Atração: processa pares opostos ───
    // Para cada par (N+S, E+W, NE+SW, NW+SE):
    //   - se há peça oposta nos dois lados: ambas destruídas
    //   - se há em um só: tenta mover em direção ao epicentro
    final attractedHandled = <int>{}; // direções já processadas via atração
    for (final pair in oppositePairs) {
      final iA = pair[0];
      final iB = pair[1];
      final nA = neighborByDir[iA];
      final nB = neighborByDir[iB];

      final pA = nA != null ? board[nA.row][nA.col] : null;
      final pB = nB != null ? board[nB.row][nB.col] : null;

      final isAOpposite = pA != null && pA.polarity != piece.polarity;
      final isBOpposite = pB != null && pB.polarity != piece.polarity;

      if (isAOpposite && isBOpposite) {
        // Par completo: ambas tentam atravessar e colidem → aniquilação mútua
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nA!.row, nA.col),
          kind: ForceKind.attract,
        ));
        events.add(ForceEvent(
          from: Cell(er, ec),
          to: Cell(nB!.row, nB.col),
          kind: ForceKind.attract,
        ));
        destroyedThisWave += _annihilate(board, pA!, nA, owner, onBoard, destroyed, events);
        destroyedThisWave += _annihilate(board, pB!, nB, owner, onBoard, destroyed, events);
        attractedHandled.add(iA);
        attractedHandled.add(iB);
      } else if (isAOpposite) {
        // Solo A → atravessa pelo epicentro pro lado B (posição simétrica)
        destroyedThisWave += _attractAcross(
          board: board,
          epicenterR: er,
          epicenterC: ec,
          neighbor: nA!,
          fromDirIndex: iA,
          toDirIndex: iB,
          owner: owner,
          onBoard: onBoard,
          destroyed: destroyed,
          events: events,
        );
        attractedHandled.add(iA);
      } else if (isBOpposite) {
        destroyedThisWave += _attractAcross(
          board: board,
          epicenterR: er,
          epicenterC: ec,
          neighbor: nB!,
          fromDirIndex: iB,
          toDirIndex: iA,
          owner: owner,
          onBoard: onBoard,
          destroyed: destroyed,
          events: events,
        );
        attractedHandled.add(iB);
      }
    }

    // ─── 3) Repulsão: direção a direção, com wrap, sem destruição ───
    for (int i = 0; i < dirs.length; i++) {
      if (attractedHandled.contains(i)) continue;
      final n = neighborByDir[i];
      if (n == null) continue;
      final neighborPiece = board[n.row][n.col];
      if (neighborPiece == null) continue;
      // Mesma polaridade ou já foi tratada como atração? Repulsão só se igual.
      if (neighborPiece.polarity != piece.polarity) continue;

      events.add(ForceEvent(
        from: Cell(er, ec),
        to: Cell(n.row, n.col),
        kind: ForceKind.repel,
      ));
      destroyedThisWave += _repelSingle(
        board: board,
        neighbor: n,
        dr: dirs[i][0],
        dc: dirs[i][1],
        epicenterR: er,
        epicenterC: ec,
        owner: owner,
        onBoard: onBoard,
        destroyed: destroyed,
        events: events,
      );
    }

    // Charge do epicentro: se era carregado, zera
    if (epicenterWasCharged) {
      final reset = piece.resetCharge();
      board[er][ec] = reset;
      piece = reset;
      events.add(ChargeEvent(at: Cell(er, ec), newCharge: 0));
    }

    // Ressonância
    int bonus = 0;
    if (destroyedThisWave >= 2) {
      bonus = destroyedThisWave >= 3 ? 2 : 1;
      final current = stock[owner] ?? 0;
      final effective = (current + bonus).clamp(0, GameState.stockSize) - current;
      if (effective > 0) {
        stock[owner] = current + effective;
      }
      events.add(ResonanceEvent(
        owner: owner,
        destroyedCount: destroyedThisWave,
        bonus: effective,
      ));
    }

    // Fim de partida
    final actionsTaken = state.actionsTaken + 1;
    final other = owner.opponent;
    PieceOwner? winner;
    bool gameEnded = false;

    if ((onBoard[other] ?? 0) == 0 && (stock[other] ?? 0) == 0) {
      winner = owner;
      gameEnded = true;
    } else if ((onBoard[owner] ?? 0) == 0 && (stock[owner] ?? 0) == 0) {
      winner = other;
      gameEnded = true;
    } else if (actionsTaken >= GameState.maxActions) {
      gameEnded = true;
      winner = _decideTiedWinner(onBoard, destroyed);
    } else if (_isStalemate(board, stock)) {
      gameEnded = true;
      winner = _decideTiedWinner(onBoard, destroyed);
    }

    if (gameEnded) events.add(EndEvent(winner));

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

  /// Atração solo (sem par contrário): peça atravessa o epicentro e aterrissa
  /// na posição simétrica (mesmo step, lado oposto). Destino calculado com
  /// wrap toroidal. Se destino vazio → move (+1 charge). Se ocupado → atraída
  /// destruída (consistente com regra ativa/passiva).
  static int _attractAcross({
    required List<List<Piece?>> board,
    required int epicenterR,
    required int epicenterC,
    required _Neighbor neighbor,
    required int fromDirIndex,
    required int toDirIndex,
    required PieceOwner owner,
    required Map<PieceOwner, int> onBoard,
    required Map<PieceOwner, int> destroyed,
    required List<AnimationEvent> events,
  }) {
    events.add(ForceEvent(
      from: Cell(epicenterR, epicenterC),
      to: Cell(neighbor.row, neighbor.col),
      kind: ForceKind.attract,
    ));

    final toDir = dirs[toDirIndex];
    // Posição simétrica: epicentro + dirOposto × step (com wrap)
    final tr = _wrapAxis(epicenterR + toDir[0] * neighbor.step);
    final tc = _wrapAxis(epicenterC + toDir[1] * neighbor.step);

    final attracted = board[neighbor.row][neighbor.col]!;
    final destPiece = board[tr][tc];

    if (destPiece == null) {
      // Casa simétrica vazia → atravessa
      board[neighbor.row][neighbor.col] = null;
      final landed = attracted.bumpCharge();
      board[tr][tc] = landed;
      events.add(MoveEvent(
        from: Cell(neighbor.row, neighbor.col),
        to: Cell(tr, tc),
        piece: landed,
      ));
      if (landed.charge > attracted.charge) {
        events.add(ChargeEvent(
          at: Cell(tr, tc),
          newCharge: landed.charge,
          becameCharged: landed.isCharged && !attracted.isCharged,
        ));
      }
      return 0;
    }

    // Destino ocupado (caso raro, via wrap em board cheio) → atraída morre
    board[neighbor.row][neighbor.col] = null;
    onBoard[attracted.owner] = (onBoard[attracted.owner] ?? 0) - 1;
    int killed = 0;
    if (attracted.owner != owner) {
      destroyed[owner] = (destroyed[owner] ?? 0) + 1;
      killed = 1;
    }
    events.add(DestroyEvent(
      from: Cell(neighbor.row, neighbor.col),
      direction: toDir,
      piece: attracted,
    ));
    return killed;
  }

  /// Aniquilação direta (par de opostos colide). Destrói a peça na posição
  /// do vizinho. Conta destruição se o dono for diferente do epicentro.
  static int _annihilate(
    List<List<Piece?>> board,
    Piece piece,
    _Neighbor at,
    PieceOwner ownerOfEpicenter,
    Map<PieceOwner, int> onBoard,
    Map<PieceOwner, int> destroyed,
    List<AnimationEvent> events,
  ) {
    board[at.row][at.col] = null;
    onBoard[piece.owner] = (onBoard[piece.owner] ?? 0) - 1;
    int killed = 0;
    if (piece.owner != ownerOfEpicenter) {
      destroyed[ownerOfEpicenter] = (destroyed[ownerOfEpicenter] ?? 0) + 1;
      killed = 1;
    }
    events.add(DestroyEvent(
      from: Cell(at.row, at.col),
      direction: const [0, 0],
      piece: piece,
    ));
    return killed;
  }

  /// Repulsão single-hit com wrap toroidal. A peça repelida tenta mover 1
  /// casa na direção (dr, dc). Destino é calculado COM wrap. Se destino é
  /// vazio → move (+1 charge). Se ocupado → repelida destruída, destino
  /// sobrevive. Sem cadeia.
  /// Retorna quantas peças do oponente foram destruídas.
  static int _repelSingle({
    required List<List<Piece?>> board,
    required _Neighbor neighbor,
    required int dr,
    required int dc,
    required int epicenterR,
    required int epicenterC,
    required PieceOwner owner,
    required Map<PieceOwner, int> onBoard,
    required Map<PieceOwner, int> destroyed,
    required List<AnimationEvent> events,
  }) {
    final tr = _wrapAxis(neighbor.row + dr);
    final tc = _wrapAxis(neighbor.col + dc);

    final repelled = board[neighbor.row][neighbor.col]!;

    // Destino é o epicentro (caso wrap) ou outra peça → repelida destruída
    final destPiece = board[tr][tc];
    if (destPiece != null) {
      board[neighbor.row][neighbor.col] = null;
      onBoard[repelled.owner] = (onBoard[repelled.owner] ?? 0) - 1;
      int killed = 0;
      if (repelled.owner != owner) {
        destroyed[owner] = (destroyed[owner] ?? 0) + 1;
        killed = 1;
      }
      events.add(DestroyEvent(
        from: Cell(neighbor.row, neighbor.col),
        direction: [dr, dc],
        piece: repelled,
      ));
      return killed;
    }

    // Destino vazio → move
    board[neighbor.row][neighbor.col] = null;
    final landed = repelled.bumpCharge();
    board[tr][tc] = landed;
    events.add(MoveEvent(
      from: Cell(neighbor.row, neighbor.col),
      to: Cell(tr, tc),
      piece: landed,
    ));
    if (landed.charge > repelled.charge) {
      events.add(ChargeEvent(
        at: Cell(tr, tc),
        newCharge: landed.charge,
        becameCharged: landed.isCharged && !repelled.isCharged,
      ));
    }
    return 0;
  }

  /// Stalemate: nenhuma peça tem vizinho a até chargedRange casas.
  /// Pré-condição já checada pelo caller: ambos estoques = 0.
  static bool _isStalemate(List<List<Piece?>> board, Map<PieceOwner, int> stock) {
    if ((stock[PieceOwner.player] ?? 0) > 0) return false;
    if ((stock[PieceOwner.ai] ?? 0) > 0) return false;

    final n = GameState.boardSize;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (board[r][c] == null) continue;
        for (final dir in dirs) {
          for (int step = 1; step <= chargedRange; step++) {
            final nr = r + dir[0] * step;
            final nc = c + dir[1] * step;
            if (nr < 0 || nr >= n || nc < 0 || nc >= n) break;
            if (board[nr][nc] != null) return false; // tem vizinho
          }
        }
      }
    }
    return true;
  }

  /// Decide vencedor numa situação de fim por contagem (max ações ou stalemate).
  static PieceOwner? _decideTiedWinner(
    Map<PieceOwner, int> onBoard,
    Map<PieceOwner, int> destroyed,
  ) {
    final p = onBoard[PieceOwner.player] ?? 0;
    final a = onBoard[PieceOwner.ai] ?? 0;
    if (p > a) return PieceOwner.player;
    if (a > p) return PieceOwner.ai;
    final dp = destroyed[PieceOwner.player] ?? 0;
    final da = destroyed[PieceOwner.ai] ?? 0;
    if (dp > da) return PieceOwner.player;
    if (da > dp) return PieceOwner.ai;
    return null; // empate técnico
  }

  /// Ações legais para o jogador da vez.
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

class _Neighbor {
  final int row;
  final int col;
  final int step;
  const _Neighbor({required this.row, required this.col, required this.step});
}
