import 'dart:math';

import 'piece.dart';

/// Estado imutável do jogo. `copyWith` para evoluir; nunca mutar in-place.
class GameState {
  static const int boardSize = 5;
  static const int stockSize = 10;
  static const int defaultMaxTurns = 20;
  static const int stalemateThreshold = 4;
  /// 20 linhas pontuáveis:
  /// - 5 linhas horizontais (length 5)
  /// - 5 colunas (length 5)
  /// - 5 diagonais NW-SE (length 5, 4, 4, 3, 3) — incluindo principal
  /// - 5 diagonais NE-SW (length 5, 4, 4, 3, 3) — incluindo antiprincipal
  /// Todas com ≥ 3 células (3-em-linha é o menor padrão pontuável).
  static const int totalLines = 20;

  /// board[row][col] — nullable. row 0 é topo.
  final List<List<Piece?>> board;
  final Map<PieceOwner, int> stock;
  final Map<PieceOwner, int> onBoard;

  /// Pontuação acumulada da partida.
  final Map<PieceOwner, int> points;

  /// Quais linhas (0..11) têm 5-em-linha do mesmo dono ATUALMENTE.
  /// Usado pra detectar quando uma 5-em-linha se forma de NOVO (delta) —
  /// nesses momentos, o dono tira 1 peça aleatória do oponente.
  final Map<int, PieceOwner> linesWithFive;

  /// Quantos turnos a partida tem (cada turno = 2 ações). Configurável pela
  /// dificuldade: Aprendiz = 20, Adepto/Mestre = 30/40/50.
  final int maxTurns;

  /// Contador de ações consecutivas sem efeito (flip que não causou Move).
  final int consecutiveEmptyActions;

  final int actionsTaken;
  final PieceOwner currentPlayer;
  final PieceOwner? winner;

  const GameState._({
    required this.board,
    required this.stock,
    required this.onBoard,
    required this.points,
    required this.linesWithFive,
    required this.maxTurns,
    required this.consecutiveEmptyActions,
    required this.actionsTaken,
    required this.currentPlayer,
    required this.winner,
  });

  /// Cria nova partida. Primeiro jogador é aleatório (50/50).
  /// [maxTurns] define o número de turnos (cada turno = 2 ações).
  factory GameState.newGame({
    PieceOwner? startingPlayer,
    Random? rng,
    int maxTurns = defaultMaxTurns,
  }) {
    final firstPlayer = startingPlayer ??
        ((rng ?? Random()).nextBool() ? PieceOwner.player : PieceOwner.ai);
    return GameState._(
      board: List.generate(boardSize, (_) => List<Piece?>.filled(boardSize, null, growable: false)),
      stock: {PieceOwner.player: stockSize, PieceOwner.ai: stockSize},
      onBoard: {PieceOwner.player: 0, PieceOwner.ai: 0},
      points: {PieceOwner.player: 0, PieceOwner.ai: 0},
      linesWithFive: const {},
      maxTurns: maxTurns,
      consecutiveEmptyActions: 0,
      actionsTaken: 0,
      currentPlayer: firstPlayer,
      winner: null,
    );
  }

  GameState copyWith({
    List<List<Piece?>>? board,
    Map<PieceOwner, int>? stock,
    Map<PieceOwner, int>? onBoard,
    Map<PieceOwner, int>? points,
    Map<int, PieceOwner>? linesWithFive,
    int? maxTurns,
    int? consecutiveEmptyActions,
    int? actionsTaken,
    PieceOwner? currentPlayer,
    PieceOwner? winner,
  }) {
    return GameState._(
      board: board ?? this.board,
      stock: stock ?? this.stock,
      onBoard: onBoard ?? this.onBoard,
      points: points ?? this.points,
      linesWithFive: linesWithFive ?? this.linesWithFive,
      maxTurns: maxTurns ?? this.maxTurns,
      consecutiveEmptyActions: consecutiveEmptyActions ?? this.consecutiveEmptyActions,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
    );
  }

  /// Clona o tabuleiro pra mutações controladas dentro do motor.
  List<List<Piece?>> cloneBoard() =>
      board.map((row) => List<Piece?>.from(row)).toList(growable: false);

  /// Número máximo de ações da partida (cada turno = 2 ações).
  int get maxActions => maxTurns * 2;

  /// Turno atual exibido na UI (1..maxTurns).
  int get displayTurn => (actionsTaken ~/ 2) + 1;
  int get maxDisplayTurns => maxTurns;

  bool get isGameOver => winner != null;

  Piece? pieceAt(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return null;
    return board[row][col];
  }
}

