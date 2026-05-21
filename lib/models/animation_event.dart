import 'piece.dart';

/// Eventos emitidos pelo motor do jogo em ordem temporal.
/// A UI consome esses eventos como fila e renderiza cada um com seu timing.
sealed class AnimationEvent {
  const AnimationEvent();
}

class PlaceEvent extends AnimationEvent {
  final Cell at;
  final Piece piece;
  const PlaceEvent({required this.at, required this.piece});
}

class FlipEvent extends AnimationEvent {
  final Cell at;
  final Piece piece;
  const FlipEvent({required this.at, required this.piece});
}

class EpicenterEvent extends AnimationEvent {
  final Cell at;
  const EpicenterEvent(this.at);
}

enum ForceKind { attract, repel }

class ForceEvent extends AnimationEvent {
  final Cell from;
  final Cell to;
  final ForceKind kind;
  const ForceEvent({required this.from, required this.to, required this.kind});
}

class MoveEvent extends AnimationEvent {
  final Cell from;
  final Cell to;
  final Piece piece;
  const MoveEvent({
    required this.from,
    required this.to,
    required this.piece,
  });
}

/// Par de peças opostas trocando de posição (atração em par).
class SwapEvent extends AnimationEvent {
  final Cell cellA;
  final Cell cellB;
  final Piece pieceA;
  final Piece pieceB;
  const SwapEvent({
    required this.cellA,
    required this.cellB,
    required this.pieceA,
    required this.pieceB,
  });
}

/// Linha (5) ou subsequência (3/4) completada por um jogador. Carrega
/// pontuação ganha. Se length == 5, peças são removidas (reciclagem).
class LineCompletedEvent extends AnimationEvent {
  final List<Cell> cells;
  final PieceOwner owner;
  final int length; // 3, 4 ou 5
  final bool uniformPolarity;
  final int pointsEarned;
  final bool recycled; // true se length == 5 (peças removidas + estoque)

  const LineCompletedEvent({
    required this.cells,
    required this.owner,
    required this.length,
    required this.uniformPolarity,
    required this.pointsEarned,
    required this.recycled,
  });
}

class EndEvent extends AnimationEvent {
  final PieceOwner? winner;
  const EndEvent(this.winner);
}

/// Peça destruída — usado quando 5-em-linha tira uma peça do oponente.
class DestroyEvent extends AnimationEvent {
  final Cell from;
  final Piece piece;
  const DestroyEvent({required this.from, required this.piece});
}
