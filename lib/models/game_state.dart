import 'piece.dart';

/// Estado imutável do jogo. `copyWith` para evoluir; nunca mutar in-place.
class GameState {
  static const int boardSize = 5;
  static const int stockSize = 6;
  static const int maxActions = 20; // 10 ações por jogador

  /// board[row][col] — nullable. row 0 é topo.
  final List<List<Piece?>> board;
  final Map<PieceOwner, int> stock;
  final Map<PieceOwner, int> onBoard;
  final int actionsTaken;
  final PieceOwner currentPlayer;
  final PieceOwner? winner;

  const GameState._({
    required this.board,
    required this.stock,
    required this.onBoard,
    required this.actionsTaken,
    required this.currentPlayer,
    required this.winner,
  });

  factory GameState.newGame() => GameState._(
    board: List.generate(boardSize, (_) => List<Piece?>.filled(boardSize, null, growable: false)),
    stock: {PieceOwner.player: stockSize, PieceOwner.ai: stockSize},
    onBoard: {PieceOwner.player: 0, PieceOwner.ai: 0},
    actionsTaken: 0,
    currentPlayer: PieceOwner.player,
    winner: null,
  );

  GameState copyWith({
    List<List<Piece?>>? board,
    Map<PieceOwner, int>? stock,
    Map<PieceOwner, int>? onBoard,
    int? actionsTaken,
    PieceOwner? currentPlayer,
    PieceOwner? winner,
  }) {
    return GameState._(
      board: board ?? this.board,
      stock: stock ?? this.stock,
      onBoard: onBoard ?? this.onBoard,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
    );
  }

  /// Clona o tabuleiro pra mutações controladas dentro do motor.
  List<List<Piece?>> cloneBoard() =>
      board.map((row) => List<Piece?>.from(row)).toList(growable: false);

  /// Turno atual exibido na UI (1..maxActions/2). Cada turno = 1 ação do jogador + 1 da IA.
  int get displayTurn => (actionsTaken ~/ 2) + 1;
  int get maxDisplayTurns => maxActions ~/ 2;

  bool get isGameOver => winner != null;

  Piece? pieceAt(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return null;
    return board[row][col];
  }
}
