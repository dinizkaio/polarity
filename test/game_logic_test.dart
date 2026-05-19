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
  });

  group('GameLogic — Atração (passagem orbital)', () {
    test('atração: peça oposta cruza pro outro lado do epicentro', () {
      // ⊕ player em (2,1). IA coloca ⊖ em (2,2): ⊕ é atraído e cruza pra (2,3).
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 1, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 2, col: 2, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(2, 1), isNull);
      expect(ns.pieceAt(2, 2)?.polarity, Polarity.minus);
      expect(ns.pieceAt(2, 3)?.polarity, Polarity.plus);
      expect(ns.pieceAt(2, 3)?.charge, 1);
    });

    test('atração: casa simétrica fora do tabuleiro → peça destruída', () {
      // ⊕ player em (0,1). IA coloca ⊖ em (0,0): atração tenta (0,-1) → fora.
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 1, polarity: Polarity.plus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 0, col: 0, polarity: Polarity.minus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(0, 1), isNull);
      expect(ns.destroyed[PieceOwner.ai], 1);
      final hasDestroy = r.events.any((e) => e is DestroyEvent);
      expect(hasDestroy, isTrue);
    });
  });

  group('GameLogic — Repulsão', () {
    test('repulsão empurra vizinho uma casa', () {
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.plus))!.newState;
      // Player ⊕ em (2,3): vizinho W ⊕ em (2,2) → repelido a (2,1)
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

    test('peça empurrada pra fora do tabuleiro é destruída', () {
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 4, col: 4, polarity: Polarity.minus))!.newState;
      final r = GameLogic.applyAction(
        s,
        const PlaceAction(row: 1, col: 0, polarity: Polarity.plus),
      );
      expect(r, isNotNull);
      final ns = r!.newState;
      expect(ns.pieceAt(0, 0), isNull);
      expect(ns.onBoard[PieceOwner.player], 1);
      // É a própria peça destruída — não conta como "destroyed by other"
      expect(ns.destroyed[PieceOwner.player], 0);
      expect(ns.destroyed[PieceOwner.ai], 0);
      final hasDestroy = r.events.any((e) => e is DestroyEvent);
      expect(hasDestroy, isTrue);
    });
  });

  group('GameLogic — Carga', () {
    test('peça acumula charge ao sobreviver a uma força', () {
      var s = GameState.newGame();
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 2, col: 2, polarity: Polarity.plus))!.newState;
      s = GameLogic.applyAction(
          s, const PlaceAction(row: 0, col: 0, polarity: Polarity.minus))!.newState;
      // ⊕ em (2,3) → empurra (2,2) pra (2,1), que ganha charge 1
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
