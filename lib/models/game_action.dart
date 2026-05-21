import 'piece.dart';

/// Tipo de ação que o jogador da vez pode tomar.
sealed class GameAction {
  const GameAction();
}

class PlaceAction extends GameAction {
  final int row;
  final int col;
  final Polarity polarity;
  const PlaceAction({required this.row, required this.col, required this.polarity});

  @override
  String toString() => 'Place($row,$col,$polarity)';
}

class FlipAction extends GameAction {
  final int row;
  final int col;
  final Polarity targetPolarity;
  const FlipAction({
    required this.row,
    required this.col,
    required this.targetPolarity,
  });

  @override
  String toString() => 'Flip($row,$col→$targetPolarity)';
}
