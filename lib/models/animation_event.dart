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
  final bool isCharged;
  const EpicenterEvent(this.at, {this.isCharged = false});
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

/// Disparado quando o charge da peça muda (cresce ou zera).
class ChargeEvent extends AnimationEvent {
  final Cell at;
  final int newCharge;
  final bool becameCharged;
  const ChargeEvent({
    required this.at,
    required this.newCharge,
    this.becameCharged = false,
  });
}

/// Cadeia destruiu 2+ peças do oponente em uma única onda → ressonância.
/// O dono do epicentro ganha [bonus] peças de volta no estoque (até stockSize).
class ResonanceEvent extends AnimationEvent {
  final PieceOwner owner;
  final int destroyedCount;
  final int bonus;
  const ResonanceEvent({
    required this.owner,
    required this.destroyedCount,
    required this.bonus,
  });
}

class EndEvent extends AnimationEvent {
  final PieceOwner? winner;
  const EndEvent(this.winner);
}
