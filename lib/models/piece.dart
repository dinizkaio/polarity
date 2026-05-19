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
///
/// `charge` (0..maxCharge) acumula sempre que a peça sobrevive a uma força
/// (atração, repulsão ou bloqueio). Quando atinge maxCharge, a peça vira
/// **carregada**. Carregadas têm alcance 2 quando são EPICENTRO (a onda
/// magnética alcança peças a 2 casas, não só vizinhos imediatos). Após
/// disparar como epicentro, o charge zera.
class Piece {
  static const int maxCharge = 3;

  final int id;
  final PieceOwner owner;
  final Polarity polarity;
  final int charge;

  const Piece({
    required this.id,
    required this.owner,
    required this.polarity,
    this.charge = 0,
  });

  bool get isCharged => charge >= maxCharge;

  Piece copyWith({Polarity? polarity, int? charge}) => Piece(
    id: id,
    owner: owner,
    polarity: polarity ?? this.polarity,
    charge: charge ?? this.charge,
  );

  Piece bumpCharge() => copyWith(charge: (charge + 1).clamp(0, maxCharge));
  Piece resetCharge() => copyWith(charge: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Piece &&
          other.id == id &&
          other.owner == owner &&
          other.polarity == polarity &&
          other.charge == charge);

  @override
  int get hashCode => Object.hash(id, owner, polarity, charge);

  @override
  String toString() =>
      'Piece(id:$id, owner:$owner, polarity:$polarity, charge:$charge)';
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
