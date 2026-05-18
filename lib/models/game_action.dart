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
  const FlipAction({required this.row, required this.col});

  @override
  String toString() => 'Flip($row,$col)';
}
