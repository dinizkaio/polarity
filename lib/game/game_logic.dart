import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Motor de regras do Polaridade — versão 3 (física toroidal com pares).
///
/// Diferenças em relação à v2:
///
/// 1. **Tabuleiro toroidal (wrap-around):** peças nunca caem fora. Empurrão
///    além da borda → reaparece pelo lado oposto (Pac-Man / toro).
///
/// 2. **Atração clássica + colisão destrutiva:** peça oposta tenta mover 1
///    casa em direção ao epicentro. Se a casa-destino estiver ocupada (pelo
///    epicentro ou por outra peça), a peça atraída é DESTRUÍDA. A peça onde
///    ela "cairia" também é destruída — EXCETO se for o epicentro (que é
///    indestrutível na sua própria onda).
///
/// 3. **Atração em pares opostos:** as 4 duplas de direções contrárias
///    (N+S, E+W, NE+SW, NW+SE) são processadas como unidade. Se há peças
///    opostas dos DOIS lados, ambas convergem e se aniquilam (epicentro fica).
///    Estratégia central: posicionar epicentro entre dois inimigos opostos.
///
/// 4. **Repulsão sem destruição:** peça empurrada que sairia do tabuleiro
///    faz wrap pro lado oposto. Continua a cadeia até achar casa vazia.
///    Em tabuleiro cheio, o motor limita a [boardSize] iterações por
///    segurança e descarta o movimento (estado inválido — não acontece na
///    prática porque o jogo termina antes).
///
/// 5. **Carga (Pulsar):** peça com 3+ charges vira pulsar. Como epicentro,
///    a onda tem alcance 2 — a peça oposta/igual pode estar a 1 OU 2 casas
///    (a onda "vaza" por uma casa vazia). Charge zera após disparar.
///
/// 6. **Ressonância:** destruir 2+ peças do oponente na mesma onda dá +1
///    no estoque (3+ → +2), respeitando o teto.
///
/// 7. **Fim por stalemate:** se ambos estoques = 0 E nenhuma peça tem
///    vizinho a 1 ou 2 casas (alcance máximo), a partida termina mesmo
///    com turnos restantes. Decide pelo maior `onBoard`, desempate por
///    `destroyed`.
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
        // Par completo: ambas opostas → colidem e morrem
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
        destroyedThisWave += _attractSingle(
          board: board,
          epi: Cell(er, ec),
          neighbor: nA!,
          dirIndex: iA,
          owner: owner,
          onBoard: onBoard,
          destroyed: destroyed,
          events: events,
        );
        attractedHandled.add(iA);
      } else if (isBOpposite) {
        destroyedThisWave += _attractSingle(
          board: board,
          epi: Cell(er, ec),
          neighbor: nB!,
          dirIndex: iB,
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
      _chainPushToroidal(
        board: board,
        startR: n.row,
        startC: n.col,
        dr: dirs[i][0],
        dc: dirs[i][1],
        epicenterR: er,
        epicenterC: ec,
        events: events,
        ownerOfEpicenter: owner,
        onBoard: onBoard,
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

  /// Atração de uma única peça oposta (sem par contrário). Move 1 casa em
  /// direção ao epicentro. Se a casa-destino é o epicentro → atraída destruída.
  /// Se é outra peça (caso alcance 2) → ambas destruídas. Se vazia → move.
  static int _attractSingle({
    required List<List<Piece?>> board,
    required Cell epi,
    required _Neighbor neighbor,
    required int dirIndex,
    required PieceOwner owner,
    required Map<PieceOwner, int> onBoard,
    required Map<PieceOwner, int> destroyed,
    required List<AnimationEvent> events,
  }) {
    events.add(ForceEvent(
      from: epi,
      to: Cell(neighbor.row, neighbor.col),
      kind: ForceKind.attract,
    ));

    final dr = dirs[dirIndex][0];
    final dc = dirs[dirIndex][1];
    // Destino: 1 casa em direção contrária a (dr,dc), ou seja, mais perto do epicentro
    final tr = neighbor.row - dr;
    final tc = neighbor.col - dc;
    final n = GameState.boardSize;
    if (tr < 0 || tr >= n || tc < 0 || tc >= n) {
      // Destino fora — fica parada (não destrói, não move)
      events.add(ShakeEvent(Cell(neighbor.row, neighbor.col)));
      return 0;
    }

    final attracted = board[neighbor.row][neighbor.col]!;

    final destPiece = board[tr][tc];
    if (destPiece == null) {
      // Move pra casa vazia (com +1 charge)
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

    // Casa-destino ocupada. Se é o epicentro: só a atraída destruída (epicentro é indestrutível na sua onda).
    final isEpicenter = tr == epi.row && tc == epi.col;
    if (isEpicenter) {
      board[neighbor.row][neighbor.col] = null;
      onBoard[attracted.owner] = (onBoard[attracted.owner] ?? 0) - 1;
      final killed = attracted.owner != owner ? 1 : 0;
      if (killed > 0) destroyed[owner] = (destroyed[owner] ?? 0) + 1;
      events.add(DestroyEvent(
        from: Cell(neighbor.row, neighbor.col),
        direction: [-dr, -dc],
        piece: attracted,
      ));
      return killed;
    }

    // Outra peça (não-epicentro): ambas destruídas
    board[neighbor.row][neighbor.col] = null;
    onBoard[attracted.owner] = (onBoard[attracted.owner] ?? 0) - 1;
    int killed = 0;
    if (attracted.owner != owner) {
      destroyed[owner] = (destroyed[owner] ?? 0) + 1;
      killed++;
    }
    events.add(DestroyEvent(
      from: Cell(neighbor.row, neighbor.col),
      direction: [-dr, -dc],
      piece: attracted,
    ));

    board[tr][tc] = null;
    onBoard[destPiece.owner] = (onBoard[destPiece.owner] ?? 0) - 1;
    if (destPiece.owner != owner) {
      destroyed[owner] = (destroyed[owner] ?? 0) + 1;
      killed++;
    }
    events.add(DestroyEvent(
      from: Cell(tr, tc),
      direction: [-dr, -dc],
      piece: destPiece,
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

  /// Cadeia de empurrão com wrap toroidal. Empurra peças sucessivas até achar
  /// casa vazia OU até bater no epicentro (cuja casa nunca é empurrada).
  /// Sem destruição — repulsão nunca mata.
  static void _chainPushToroidal({
    required List<List<Piece?>> board,
    required int startR,
    required int startC,
    required int dr,
    required int dc,
    required int epicenterR,
    required int epicenterC,
    required List<AnimationEvent> events,
    required PieceOwner ownerOfEpicenter,
    required Map<PieceOwner, int> onBoard,
  }) {
    final maxSteps = GameState.boardSize;
    final chain = <List<int>>[];
    int cr = startR;
    int cc = startC;
    int? destR;
    int? destC;
    for (int step = 0; step <= maxSteps; step++) {
      // O epicentro nunca é deslocado — para a cadeia antes de chegar nele
      if (cr == epicenterR && cc == epicenterC) break;
      if (board[cr][cc] == null) {
        destR = cr;
        destC = cc;
        break;
      }
      chain.add([cr, cc]);
      cr = _wrapAxis(cr + dr);
      cc = _wrapAxis(cc + dc);
    }
    if (destR == null || chain.isEmpty) return; // sem casa livre, ninguém se move

    int firstFreeR = destR;
    int firstFreeC = destC!;
    for (int k = chain.length - 1; k >= 0; k--) {
      final pr = chain[k][0];
      final pc = chain[k][1];
      final tr = firstFreeR;
      final tc = firstFreeC;
      final moving = board[pr][pc]!;
      board[pr][pc] = null;
      final landed = moving.bumpCharge();
      board[tr][tc] = landed;
      events.add(MoveEvent(
        from: Cell(pr, pc),
        to: Cell(tr, tc),
        piece: landed,
        chainIndex: chain.length - 1 - k,
      ));
      if (landed.charge > moving.charge) {
        events.add(ChargeEvent(
          at: Cell(tr, tc),
          newCharge: landed.charge,
          becameCharged: landed.isCharged && !moving.isCharged,
        ));
      }
      firstFreeR = pr;
      firstFreeC = pc;
    }
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
