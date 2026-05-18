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
  final int chainIndex; // 0 = primeira da cadeia (mais perto do epicentro)
  const MoveEvent({
    required this.from,
    required this.to,
    required this.piece,
    this.chainIndex = 0,
  });
}

class ShakeEvent extends AnimationEvent {
  final Cell at;
  const ShakeEvent(this.at);
}

class DestroyEvent extends AnimationEvent {
  final Cell from;
  final List<int> direction; // [dr, dc] — pra UI animar saindo nessa direção
  final Piece piece;
  const DestroyEvent({required this.from, required this.direction, required this.piece});
}

class EndEvent extends AnimationEvent {
  final PieceOwner? winner; // null = empate, mas regra do pie resolve sempre
  const EndEvent(this.winner);
}
