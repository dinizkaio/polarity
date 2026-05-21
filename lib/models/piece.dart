/// Quem é dono da peça.
enum PieceOwner {
  player,
  ai;

  PieceOwner get opponent => this == PieceOwner.player ? PieceOwner.ai : PieceOwner.player;
}

/// Polaridade da peça.
enum Polarity {
  plus,
  minus;

  Polarity get opposite => this == Polarity.plus ? Polarity.minus : Polarity.plus;
  String get symbol => this == Polarity.plus ? '⊕' : '⊖';
}

/// Uma peça no tabuleiro. Imutável.
class Piece {
  final int id;
  final PieceOwner owner;
  final Polarity polarity;

  const Piece({
    required this.id,
    required this.owner,
    required this.polarity,
  });

  Piece copyWith({Polarity? polarity}) => Piece(
    id: id,
    owner: owner,
    polarity: polarity ?? this.polarity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Piece &&
          other.id == id &&
          other.owner == owner &&
          other.polarity == polarity);

  @override
  int get hashCode => Object.hash(id, owner, polarity);

  @override
  String toString() => 'Piece(id:$id, owner:$owner, polarity:$polarity)';
}

/// Coordenada no tabuleiro [row, col].
class Cell {
  final int row;
  final int col;
  const Cell(this.row, this.col);

  Cell offsetBy(int dr, int dc) => Cell(row + dr, col + dc);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Cell && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}
