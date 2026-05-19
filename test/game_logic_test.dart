import 'package:flutter_test/flutter_test.dart';
import 'package:polaridade/game/game_logic.dart';
import 'package:polaridade/models/animation_event.dart';
import 'package:polaridade/models/game_action.dart';
import 'package:polaridade/models/game_state.dart';
import 'package:polaridade/models/piece.dart';

void main() {
  group('GameLogic — Place', () {
    test('coloca peça em casa vazia, decrementa estoque', () {
      final state = GameState.newGame();
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
      var state = GameState.newGame();
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

  group('GameLogic — Atração clássica', () {
    test('atração solo: peça vizinha oposta vai pro epicentro → destruída', () {
      // ⊕ player em (2,1). IA coloca ⊖ em (2,2): a peça em (2,1) cairia
      // sobre o epicentro (2,2) → destruída.
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 1, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      // Peça do jogador destruída, epicentro fica
      expect(ns.pieceAt(2, 1), isNull);
      expect(ns.pieceAt(2, 2)?.polarity, Polarity.minus);
      expect(ns.destroyed[PieceOwner.ai], 1);
      final hasDestroy = r.events.any((e) => e is DestroyEvent);
      expect(hasDestroy, isTrue);
    });

    test('atração em par oposto: ambas destruídas, epicentro vive', () {
      // ⊕ em (2,1) e (2,3). IA epicentro ⊖ em (2,2). Vizinhos E e W são pares.
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 1, polarity: Polarity.plus))!.newState;
      // IA: peça neutra longe
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.minus))!.newState;
      // Player coloca em (2,3)
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 3, polarity: Polarity.plus))!.newState;
      // IA epicentro ⊖ em (2,2)
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      // Ambas player destruídas
      expect(ns.pieceAt(2, 1), isNull);
      expect(ns.pieceAt(2, 3), isNull);
      expect(ns.pieceAt(2, 2)?.polarity, Polarity.minus);
      expect(ns.destroyed[PieceOwner.ai], 2);
      // Ressonância: +1 peça no estoque da IA
      final hasResonance = r.events.any((e) => e is ResonanceEvent);
      expect(hasResonance, isTrue);
    });
  });

  group('GameLogic — Repulsão toroidal', () {
    test('repulsão na borda faz wrap pro outro lado', () {
      // ⊕ player em (0,0). IA: peça longe.
      // Player coloca ⊕ em (0,1): epicentro em (0,1), vizinho W ⊕ em (0,0) → repelido a oeste.
      // (0,-1) = wrap = (0,4). Peça vai pra (0,4).
      var s = GameState.newGame();
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
      // (0,0) saiu pelo W, wrap pra (0,4)
      expect(ns.pieceAt(0, 0), isNull);
      expect(ns.pieceAt(0, 4)?.polarity, Polarity.plus);
      // Nenhuma peça foi destruída por repulsão
      final hasDestroy = r.events.any((e) => e is DestroyEvent);
      expect(hasDestroy, isFalse);
    });

    test('repulsão empurra vizinho 1 casa quando há espaço', () {
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 3, polarity: Polarity.plus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(2, 1)?.polarity, Polarity.plus);
      expect(ns.pieceAt(2, 2), isNull);
      expect(ns.pieceAt(2, 1)?.charge, 1);
    });
  });

  group('GameLogic — Carga', () {
    test('peça acumula charge ao sobreviver a uma força', () {
      var s = GameState.newGame();
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
      final s = GameState.newGame();
      final actions = GameLogic.legalActions(s);
      final places = actions.whereType<PlaceAction>().length;
      final flips = actions.whereType<FlipAction>().length;
      expect(places, 50);
      expect(flips, 0);
    });

    test('após 1 peça do jogador: IA tem 48 places + 0 flips', () {
      var s = GameState.newGame();
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
