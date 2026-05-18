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
class AiEngine {
  final Random _rng;
  AiEngine([int? seed]) : _rng = Random(seed);

  /// Escolhe a melhor ação para o jogador da vez (assume currentPlayer == AI).
  /// Retorna null se não houver ação válida (não deveria ocorrer em jogo válido).
  GameAction? pickAction(GameState state, AiDifficulty difficulty) {
    final actions = GameLogic.legalActions(state);
    if (actions.isEmpty) return null;

    // Embaralha pra variar quando empates de score existem
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
        maximizing: false, // próximo é o oponente
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
        if (alpha >= beta) break; // poda
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

  /// Função de avaliação heurística.
  /// Pesos calibrados via self-play; ajustar com base em telemetria de balance.
  double _evaluate(GameState state, PieceOwner me) {
    final them = me == PieceOwner.player ? PieceOwner.ai : PieceOwner.player;

    // Terminal: bonus/penalty grande
    if (state.winner != null) {
      return state.winner == me ? 1000.0 : -1000.0;
    }

    final myOnBoard = state.onBoard[me] ?? 0;
    final theirOnBoard = state.onBoard[them] ?? 0;
    final myStock = state.stock[me] ?? 0;
    final theirStock = state.stock[them] ?? 0;

    // Pesos: peças no tabuleiro valem mais que estoque; oponente vale ~1.5x (mais
    // valioso eliminar do que preservar — pressão estratégica).
    double score = 0.0;
    score += myOnBoard * 10.0;
    score -= theirOnBoard * 15.0;
    score += myStock * 2.0;
    score -= theirStock * 2.0;

    // Penaliza peças minhas em borda (vulneráveis a empurrão pra fora)
    for (int r = 0; r < GameState.boardSize; r++) {
      for (int c = 0; c < GameState.boardSize; c++) {
        final p = state.board[r][c];
        if (p == null) continue;
        final isEdge = r == 0 ||
            r == GameState.boardSize - 1 ||
            c == 0 ||
            c == GameState.boardSize - 1;
        if (!isEdge) continue;
        if (p.owner == me) {
          score -= 1.5;
        } else {
          score += 1.5;
        }
      }
    }

    return score;
  }
}
