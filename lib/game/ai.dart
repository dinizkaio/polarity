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

/// IA com minimax + poda alpha-beta. Sem dependência de UI.
///
/// Avaliação considera:
/// - peças no tabuleiro (próprias × oponente)
/// - estoque
/// - destruições acumuladas (importante pra desempate)
/// - peças em borda (vulneráveis)
/// - peças carregadas (alta ameaça, alcance 2)
/// - controle do centro
class AiEngine {
  final Random _rng;
  AiEngine([int? seed]) : _rng = Random(seed);

  /// Escolhe a melhor ação para o jogador da vez (assume currentPlayer == AI).
  /// Retorna null se não houver ação válida (não deveria ocorrer em jogo válido).
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
      return state.winner == me ? 1000.0 : -1000.0;
    }
    if (state.isGameOver && state.winner == null) {
      // Empate técnico
      return 0.0;
    }

    final myOnBoard = state.onBoard[me] ?? 0;
    final theirOnBoard = state.onBoard[them] ?? 0;
    final myStock = state.stock[me] ?? 0;
    final theirStock = state.stock[them] ?? 0;
    final myDestroyed = state.destroyed[me] ?? 0;
    final theirDestroyed = state.destroyed[them] ?? 0;

    double score = 0.0;
    // Peças no tabuleiro pesam mais; oponente vale 1.5x (pressão)
    score += myOnBoard * 10.0;
    score -= theirOnBoard * 15.0;
    score += myStock * 2.0;
    score -= theirStock * 2.0;

    // Destruições acumuladas (importante pro desempate justo)
    score += myDestroyed * 3.0;
    score -= theirDestroyed * 3.0;

    final boardSize = GameState.boardSize;
    final mid = boardSize ~/ 2;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final p = state.board[r][c];
        if (p == null) continue;

        final isEdge = r == 0 || r == boardSize - 1 || c == 0 || c == boardSize - 1;
        final isCorner = (r == 0 || r == boardSize - 1) && (c == 0 || c == boardSize - 1);
        final isCenter = r == mid && c == mid;

        double cellScore = 0.0;

        // Bordas são vulneráveis a empurrão pra fora
        if (isCorner) {
          cellScore -= 2.5;
        } else if (isEdge) {
          cellScore -= 1.5;
        }
        // Centro tem controle máximo (8 vizinhos)
        if (isCenter) cellScore += 1.0;

        // Peça carregada é uma ameaça grande (alcance 2)
        if (p.isCharged) {
          cellScore += 5.0;
        } else if (p.charge > 0) {
          // Charge intermediário: alguma vantagem latente
          cellScore += 0.6 * p.charge;
        }

        if (p.owner == me) {
          score += cellScore;
        } else {
          score -= cellScore;
        }
      }
    }

    return score;
  }
}
