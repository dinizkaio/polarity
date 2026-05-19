import 'package:flutter_test/flutter_test.dart';
import 'package:polaridade/game/game_logic.dart';
import 'package:polaridade/models/animation_event.dart';
import 'package:polaridade/models/game_action.dart';
import 'package:polaridade/models/game_state.dart';
import 'package:polaridade/models/piece.dart';

void main() {
  group('GameLogic — Place', () {
    test('coloca peça em casa vazia, decrementa estoque', () {
      final state = GameState.newGame(startingPlayer: PieceOwner.player);
      final r = GameLogic.applyAction(
        state,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.plus),
      );
      expect(r, isNotNull);
      final s = r!.newState;
      expect(s.pieceAt(2, 2)?.polarity, Polarity.plus);
      expect(s.pieceAt(2, 2)?.owner, PieceOwner.player);
      expect(s.stock[PieceOwner.player], GameState.stockSize - 1);
      expect(s.onBoard[PieceOwner.player], 1);
      expect(s.currentPlayer, PieceOwner.ai);
      expect(s.actionsTaken, 1);
    });

    test('Place em casa ocupada retorna null', () {
      var state = GameState.newGame(startingPlayer: PieceOwner.player);
      var r = GameLogic.applyAction(
        state,
        const PlaceAction(row: 0, col: 0, polarity: Polarity.plus),
      );
      state = r!.newState;
      final r2 = GameLogic.applyAction(
        state,
        const PlaceAction(row: 0, col: 0, polarity: Polarity.minus),
      );
      expect(r2, isNull);
    });

    test('stockSize é 10 e maxActions é 40', () {
      expect(GameState.stockSize, 10);
      expect(GameState.maxActions, 40);
    });
  });

  group('GameLogic — Atração orbital', () {
    test('solo: peça oposta atravessa o epicentro pro lado simétrico', () {
      // ⊕ player em (2,1). IA epicentro ⊖ em (2,2): a peça em (2,1)
      // ATRAVESSA o epicentro pra posição simétrica (2,3).
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 1, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      // Peça atravessou pro outro lado
      expect(ns.pieceAt(2, 1), isNull);
      expect(ns.pieceAt(2, 2)?.polarity, Polarity.minus);
      expect(ns.pieceAt(2, 3)?.polarity, Polarity.plus);
      expect(ns.pieceAt(2, 3)?.owner, PieceOwner.player);
      // Charge +1 por sobreviver à força
      expect(ns.pieceAt(2, 3)?.charge, 1);
      // Nenhuma destruição
      final hasDestroy = r.events.any((e) => e is DestroyEvent);
      expect(hasDestroy, isFalse);
    });

    test('solo: simétrica com wrap toroidal', () {
      // ⊕ em (0,1). IA epicentro ⊖ em (0,0). Posição simétrica = (0,-1) = wrap (0,4).
      // Peça vai pra (0,4).
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 1, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 0, col: 0, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(0, 1), isNull);
      expect(ns.pieceAt(0, 4)?.polarity, Polarity.plus);
    });

    test('par oposto: ambas tentam atravessar e se aniquilam', () {
      // ⊕ em (2,1) e (2,3). IA epicentro ⊖ em (2,2). Ambas tentariam trocar
      // de lado (cada uma pra onde a outra está) → colidem → ambas destruídas.
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 1, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.minus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 3, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(2, 1), isNull);
      expect(ns.pieceAt(2, 3), isNull);
      expect(ns.pieceAt(2, 2)?.polarity, Polarity.minus);
      expect(ns.destroyed[PieceOwner.ai], 2);
      final hasResonance = r.events.any((e) => e is ResonanceEvent);
      expect(hasResonance, isTrue);
    });
  });

  group('GameLogic — Stalemate por inércia', () {
    test('4 flips consecutivos sem efeito → partida termina', () {
      // Coloca 2 peças muito distantes: (0,0) player ⊕ e (4,4) AI ⊖.
      // Distância >= 4 — alcance máximo é 2, então não interagem.
      // Depois força flips alternando — devem todos ser sem efeito.
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.minus))!.newState;
      // Agora flips: player flippa (0,0), AI flippa (4,4), 4 vezes.
      // Cada flip deve ter consecutiveEmptyActions incrementado.
      expect(s.consecutiveEmptyActions, 0); // placements zeraram
      s = GameLogic.applyAction(s, const FlipAction(row: 0, col: 0))!.newState;
      expect(s.consecutiveEmptyActions, 1);
      s = GameLogic.applyAction(s, const FlipAction(row: 4, col: 4))!.newState;
      expect(s.consecutiveEmptyActions, 2);
      s = GameLogic.applyAction(s, const FlipAction(row: 0, col: 0))!.newState;
      expect(s.consecutiveEmptyActions, 3);
      s = GameLogic.applyAction(s, const FlipAction(row: 4, col: 4))!.newState;
      // 4ª ação vazia: partida deve ter terminado
      expect(s.isGameOver, isTrue);
    });

    test('placement reseta o contador', () {
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.minus))!.newState;
      // Flip sem efeito (peças isoladas)
      s = GameLogic.applyAction(s, const FlipAction(row: 0, col: 0))!.newState;
      expect(s.consecutiveEmptyActions, 1);
      // Placement nova → reseta
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.minus))!.newState;
      expect(s.consecutiveEmptyActions, 0);
    });
  });

  group('GameState — primeiro jogador aleatório', () {
    test('newGame sem startingPlayer pode dar qualquer um dos dois', () {
      var sawPlayer = false;
      var sawAi = false;
      for (int i = 0; i < 100; i++) {
        final s = GameState.newGame();
        if (s.currentPlayer == PieceOwner.player) sawPlayer = true;
        if (s.currentPlayer == PieceOwner.ai) sawAi = true;
        if (sawPlayer && sawAi) break;
      }
      expect(sawPlayer, isTrue);
      expect(sawAi, isTrue);
    });
  });

  group('GameLogic — Repulsão toroidal', () {
    test('repulsão na borda faz wrap pro outro lado se destino vazio', () {
      // ⊕ em (0,0). Coloca ⊕ em (0,1): repulsão de (0,0) em direção W = (0,-1) = wrap (0,4).
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.minus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 0, col: 1, polarity: Polarity.plus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(0, 0), isNull);
      expect(ns.pieceAt(0, 4)?.polarity, Polarity.plus);
      // Destino vazio — nenhuma destruição
      expect(ns.destroyed[PieceOwner.player], 0);
    });
  });

  group('GameLogic — Carga', () {
    test('peça acumula charge ao sobreviver a uma força', () {
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.minus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 3, polarity: Polarity.plus))!.newState;
      expect(s.pieceAt(2, 1)?.charge, 1);
    });
  });

  group('GameLogic — Ações legais', () {
    test('jogo inicial: 25 × 2 polaridades = 50 places, 0 flips', () {
      final s = GameState.newGame(startingPlayer: PieceOwner.player);
      final actions = GameLogic.legalActions(s);
      final places = actions.whereType<PlaceAction>().length;
      final flips = actions.whereType<FlipAction>().length;
      expect(places, 50);
      expect(flips, 0);
    });

    test('após 1 peça do jogador: IA tem 48 places + 0 flips', () {
      var s = GameState.newGame(startingPlayer: PieceOwner.player);
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.plus))!.newState;
      final actions = GameLogic.legalActions(s);
      final places = actions.whereType<PlaceAction>().length;
      final flips = actions.whereType<FlipAction>().length;
      expect(places, 48);
      expect(flips, 0);
    });
  });
}
