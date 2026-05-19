import 'package:flutter_test/flutter_test.dart';
import 'package:polaridade/game/ai.dart';
import 'package:polaridade/game/game_logic.dart';
import 'package:polaridade/models/game_state.dart';

void main() {
  group('AiEngine', () {
    test('pickAction sempre retorna ação legal (apprentice)', () {
      final ai = AiEngine(0);
      var s = GameState.newGame();
      final action = ai.pickAction(s, AiDifficulty.apprentice);
      expect(action, isNotNull);
      final r = GameLogic.applyAction(s, action!);
      expect(r, isNotNull);
    });

    test('pickAction sempre retorna ação legal (master)', () {
      final ai = AiEngine(0);
      var s = GameState.newGame();
      // Master no início (board vazio) deve terminar em tempo razoável
      final stopwatch = Stopwatch()..start();
      final action = ai.pickAction(s, AiDifficulty.master);
      stopwatch.stop();
      expect(action, isNotNull);
      // Sanity: depth 5 no início pode ser pesado, mas deve caber em <10s nos testes
      expect(stopwatch.elapsed.inSeconds, lessThan(10));
    });

    test('IA é determinística com seed fixo', () {
      final ai1 = AiEngine(42);
      final ai2 = AiEngine(42);
      var s = GameState.newGame();
      final a1 = ai1.pickAction(s, AiDifficulty.adept);
      final a2 = ai2.pickAction(s, AiDifficulty.adept);
      expect(a1.toString(), a2.toString());
    });
  });
}
