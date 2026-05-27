import 'dart:math';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import 'game_logic.dart';

enum AiDifficulty {
  apprentice(depth: 1),
  adept(depth: 3),
  master(depth: 5);

  final int depth;
  const AiDifficulty({required this.depth});
}

/// IA com minimax + poda alpha-beta. Heurística da v6 prioriza:
/// - pontuação já marcada (peso máximo)
/// - peças em formações potenciais (runs 2, 3, 4)
/// - peças no tabuleiro / estoque
class AiEngine {
  final Random _rng;
  AiEngine([int? seed]) : _rng = Random(seed);

  GameAction? pickAction(GameState state, AiDifficulty difficulty) {
    final actions = GameLogic.legalActions(state);
    if (actions.isEmpty) return null;
    actions.shuffle(_rng);

    final maximizing = state.currentPlayer;
    GameAction? best;
    double bestScore = double.negativeInfinity;

    for (final action in actions) {
      final result = GameLogic.applyAction(state, action);
      if (result == null) continue;
      final score = _minimax(
        result.newState,
        depth: difficulty.depth - 1,
        alpha: double.negativeInfinity,
        beta: double.infinity,
        maximizingOwner: maximizing,
        maximizing: false,
      );
      if (score > bestScore) {
        bestScore = score;
        best = action;
      }
    }

    return best ?? actions.first;
  }

  double _minimax(
    GameState state, {
    required int depth,
    required double alpha,
    required double beta,
    required PieceOwner maximizingOwner,
    required bool maximizing,
  }) {
    if (depth <= 0 || state.isGameOver) {
      return _evaluate(state, maximizingOwner);
    }
    final actions = GameLogic.legalActions(state);
    if (actions.isEmpty) return _evaluate(state, maximizingOwner);

    if (maximizing) {
      double value = double.negativeInfinity;
      for (final action in actions) {
        final r = GameLogic.applyAction(state, action);
        if (r == null) continue;
        value = max(
          value,
          _minimax(
            r.newState,
            depth: depth - 1,
            alpha: alpha,
            beta: beta,
            maximizingOwner: maximizingOwner,
            maximizing: false,
          ),
        );
        alpha = max(alpha, value);
        if (alpha >= beta) break;
      }
      return value;
    } else {
      double value = double.infinity;
      for (final action in actions) {
        final r = GameLogic.applyAction(state, action);
        if (r == null) continue;
        value = min(
          value,
          _minimax(
            r.newState,
            depth: depth - 1,
            alpha: alpha,
            beta: beta,
            maximizingOwner: maximizingOwner,
            maximizing: true,
          ),
        );
        beta = min(beta, value);
        if (alpha >= beta) break;
      }
      return value;
    }
  }

  double _evaluate(GameState state, PieceOwner me) {
    final them = me.opponent;

    if (state.winner != null) {
      return state.winner == me ? 10000.0 : -10000.0;
    }
    if (state.isGameOver && state.winner == null) {
      return 0.0;
    }

    double score = 0.0;

    // Pontuação já marcada — peso dominante
    final myPts = state.points[me] ?? 0;
    final theirPts = state.points[them] ?? 0;
    score += myPts * 20.0;
    score -= theirPts * 22.0;

    // Material no tabuleiro e estoque
    score += (state.onBoard[me] ?? 0) * 3.0;
    score -= (state.onBoard[them] ?? 0) * 3.0;
    score += (state.stock[me] ?? 0) * 1.0;
    score -= (state.stock[them] ?? 0) * 1.0;

    // Formações potenciais (runs 2, 3, 4) em cada linha
    for (int lineIdx = 0; lineIdx < GameState.totalLines; lineIdx++) {
      final cells = _lineCells(lineIdx);
      final pieces = cells.map((c) => state.board[c.row][c.col]).toList();
      final run = _findLongestRunInLine(pieces);
      if (run.owner == null || run.length < 2) continue;
      final lineScore = _runPotential(run.length);
      if (run.owner == me) {
        score += lineScore;
      } else {
        score -= lineScore;
      }
    }

    return score;
  }

  static double _runPotential(int length) {
    switch (length) {
      case 2:
        return 1.0;
      case 3:
        return 4.0;
      case 4:
        return 10.0;
      default:
        return 0.0;
    }
  }

  /// Espelha GameLogic._lineCells — 20 linhas pontuáveis no tabuleiro 5x5
  /// (5 horizontais + 5 colunas + 5 diagonais NW-SE + 5 diagonais NE-SW).
  static List<Cell> _lineCells(int lineIdx) {
    final n = GameState.boardSize;
    if (lineIdx < 5) {
      final row = lineIdx;
      return [for (int c = 0; c < n; c++) Cell(row, c)];
    } else if (lineIdx < 10) {
      final col = lineIdx - 5;
      return [for (int r = 0; r < n; r++) Cell(r, col)];
    }
    switch (lineIdx) {
      case 10:
        return [for (int i = 0; i < 5; i++) Cell(i, i)];
      case 11:
        return [for (int i = 0; i < 4; i++) Cell(i, i + 1)];
      case 12:
        return [for (int i = 0; i < 3; i++) Cell(i, i + 2)];
      case 13:
        return [for (int i = 0; i < 4; i++) Cell(i + 1, i)];
      case 14:
        return [for (int i = 0; i < 3; i++) Cell(i + 2, i)];
      case 15:
        return [for (int i = 0; i < 5; i++) Cell(i, n - 1 - i)];
      case 16:
        return [for (int i = 0; i < 4; i++) Cell(i, 3 - i)];
      case 17:
        return [for (int i = 0; i < 3; i++) Cell(i, 2 - i)];
      case 18:
        return [for (int i = 0; i < 4; i++) Cell(i + 1, n - 1 - i)];
      case 19:
        return [for (int i = 0; i < 3; i++) Cell(i + 2, n - 1 - i)];
      default:
        return const [];
    }
  }

  static _RunMin _findLongestRunInLine(List<Piece?> pieces) {
    PieceOwner? bestOwner;
    int bestLen = 0;
    PieceOwner? curOwner;
    int curLen = 0;
    for (final p in pieces) {
      if (p == null) {
        if (curLen > bestLen) {
          bestLen = curLen;
          bestOwner = curOwner;
        }
        curOwner = null;
        curLen = 0;
        continue;
      }
      if (p.owner != curOwner) {
        if (curLen > bestLen) {
          bestLen = curLen;
          bestOwner = curOwner;
        }
        curOwner = p.owner;
        curLen = 1;
      } else {
        curLen++;
      }
    }
    if (curLen > bestLen) {
      bestLen = curLen;
      bestOwner = curOwner;
    }
    return _RunMin(owner: bestOwner, length: bestLen);
  }
}

class _RunMin {
  final PieceOwner? owner;
  final int length;
  const _RunMin({required this.owner, required this.length});
}
