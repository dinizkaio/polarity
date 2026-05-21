import 'dart:math';

import 'piece.dart';

/// Estado imutável do jogo. `copyWith` para evoluir; nunca mutar in-place.
class GameState {
  static const int boardSize = 5;
  static const int stockSize = 10;
  static const int maxActions = 40; // 20 turnos × 2 jogadores
  static const int stalemateThreshold = 4;
  static const int winningPoints = 15;
  static const int totalLines = 12; // 5 rows + 5 cols + 2 diagonals

  /// board[row][col] — nullable. row 0 é topo.
  final List<List<Piece?>> board;
  final Map<PieceOwner, int> stock;
  final Map<PieceOwner, int> onBoard;

  /// Pontuação acumulada da partida.
  final Map<PieceOwner, int> points;

  /// Histórico: máximo comprimento alcançado em cada linha (0..11) por cada
  /// dono. Pontuação 3/4/5 só ganha quando a linha SUPERA seu próprio recorde.
  /// Resetada pra zero quando uma linha completa 5 (reciclagem) — permite
  /// pontuar de novo na próxima reconstrução.
  final Map<int, Map<PieceOwner, int>> linesMaxLength;

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
    required this.linesMaxLength,
    required this.consecutiveEmptyActions,
    required this.actionsTaken,
    required this.currentPlayer,
    required this.winner,
  });

  /// Cria nova partida. Primeiro jogador é aleatório (50/50) — "a gravidade
  /// decide". Pra testes determinísticos, passar [startingPlayer] explícito.
  factory GameState.newGame({PieceOwner? startingPlayer, Random? rng}) {
    final firstPlayer = startingPlayer ??
        ((rng ?? Random()).nextBool() ? PieceOwner.player : PieceOwner.ai);
    return GameState._(
      board: List.generate(boardSize, (_) => List<Piece?>.filled(boardSize, null, growable: false)),
      stock: {PieceOwner.player: stockSize, PieceOwner.ai: stockSize},
      onBoard: {PieceOwner.player: 0, PieceOwner.ai: 0},
      points: {PieceOwner.player: 0, PieceOwner.ai: 0},
      linesMaxLength: {
        for (int i = 0; i < totalLines; i++)
          i: {PieceOwner.player: 0, PieceOwner.ai: 0}
      },
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
    Map<int, Map<PieceOwner, int>>? linesMaxLength,
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
      linesMaxLength: linesMaxLength ?? this.linesMaxLength,
      consecutiveEmptyActions: consecutiveEmptyActions ?? this.consecutiveEmptyActions,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
    );
  }

  /// Clona o tabuleiro pra mutações controladas dentro do motor.
  List<List<Piece?>> cloneBoard() =>
      board.map((row) => List<Piece?>.from(row)).toList(growable: false);

  /// Clone profundo do linesMaxLength.
  Map<int, Map<PieceOwner, int>> cloneLinesMaxLength() {
    return {
      for (final entry in linesMaxLength.entries)
        entry.key: Map<PieceOwner, int>.from(entry.value)
    };
  }

  /// Turno atual exibido na UI (1..maxActions/2). Cada turno = 1 ação do jogador + 1 da IA.
  int get displayTurn => (actionsTaken ~/ 2) + 1;
  int get maxDisplayTurns => maxActions ~/ 2;

  bool get isGameOver => winner != null;

  Piece? pieceAt(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return null;
    return board[row][col];
  }
}
