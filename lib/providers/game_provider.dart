import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/ai.dart';
import '../game/game_logic.dart';
import '../models/animation_event.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Fase do jogo do ponto de vista da UI.
enum GamePhase {
  idle,          // sua vez, aguardando input
  choosingPolarity, // tocou casa vazia, precisa escolher ⊕ ou ⊖
  selectingPiece,   // selecionou peça sua, mostrando preview de flip
  resolving,        // animando reação magnética
  aiThinking,       // IA calculando
  ended,            // partida terminou
}

/// Provider principal. Orquestra estado + IA + animações.
///
/// A UI escuta `gameState`, `phase`, e `currentEvents` (eventos a animar).
/// Após animar todos os eventos, a UI chama `onAnimationComplete()` para avançar.
class GameProvider extends ChangeNotifier {
  AiDifficulty _difficulty;
  final AiEngine _ai;

  GameState _state = GameState.newGame();
  GamePhase _phase = GamePhase.idle;
  List<AnimationEvent> _pendingEvents = const [];

  // Estado da UI durante o turno do jogador
  ({int row, int col})? _selectedEmptyCell; // tocou casa vazia
  ({int row, int col})? _selectedPiece;     // tocou peça sua

  GameProvider({AiDifficulty difficulty = AiDifficulty.apprentice})
      : _difficulty = difficulty,
        _ai = AiEngine();

  GameState get state => _state;
  GamePhase get phase => _phase;
  AiDifficulty get difficulty => _difficulty;
  List<AnimationEvent> get pendingEvents => _pendingEvents;
  ({int row, int col})? get selectedEmptyCell => _selectedEmptyCell;
  ({int row, int col})? get selectedPiece => _selectedPiece;

  set difficulty(AiDifficulty v) {
    _difficulty = v;
    notifyListeners();
  }

  /// Reset completo. Use ao iniciar nova partida.
  void newGame() {
    _state = GameState.newGame();
    _phase = GamePhase.idle;
    _pendingEvents = const [];
    _selectedEmptyCell = null;
    _selectedPiece = null;
    notifyListeners();
  }

  /// Jogador tocou em uma casa. Decide o que fazer com base no estado da casa.
  void tapCell(int row, int col) {
    if (_phase != GamePhase.idle &&
        _phase != GamePhase.choosingPolarity &&
        _phase != GamePhase.selectingPiece) {
      return;
    }
    if (_state.currentPlayer != PieceOwner.player) return;

    final piece = _state.pieceAt(row, col);

    if (piece == null) {
      // Casa vazia → entra em modo de escolha de polaridade
      if ((_state.stock[PieceOwner.player] ?? 0) <= 0) {
        // Sem peças no estoque, não pode colocar — só pode flipar
        return;
      }
      _selectedEmptyCell = (row: row, col: col);
      _selectedPiece = null;
      _phase = GamePhase.choosingPolarity;
      notifyListeners();
    } else if (piece.owner == PieceOwner.player) {
      // Peça do jogador → modo de flip
      _selectedPiece = (row: row, col: col);
      _selectedEmptyCell = null;
      _phase = GamePhase.selectingPiece;
      notifyListeners();
    }
    // Peças do oponente: ignora (sem ação)
  }

  /// Cancela seleção atual (jogador desistiu da ação).
  void cancelSelection() {
    _selectedEmptyCell = null;
    _selectedPiece = null;
    _phase = GamePhase.idle;
    notifyListeners();
  }

  /// Confirma colocação com a polaridade escolhida.
  void confirmPlace(Polarity polarity) {
    final cell = _selectedEmptyCell;
    if (cell == null) return;
    if (_state.currentPlayer != PieceOwner.player) return;
    _executeAction(PlaceAction(row: cell.row, col: cell.col, polarity: polarity));
  }

  /// Confirma flip da peça selecionada.
  void confirmFlip() {
    final cell = _selectedPiece;
    if (cell == null) return;
    if (_state.currentPlayer != PieceOwner.player) return;
    _executeAction(FlipAction(row: cell.row, col: cell.col));
  }

  /// Aplica ação, prepara eventos para animar e bloqueia UI.
  void _executeAction(GameAction action) {
    final result = GameLogic.applyAction(_state, action);
    if (result == null) return;

    _state = result.newState;
    _pendingEvents = result.events;
    _phase = GamePhase.resolving;
    _selectedEmptyCell = null;
    _selectedPiece = null;
    notifyListeners();
  }

  /// Chamado pela UI quando todas as animações de _pendingEvents acabaram.
  /// Avança o jogo (turno da IA ou volta pro jogador).
  void onAnimationComplete() {
    _pendingEvents = const [];

    if (_state.isGameOver) {
      _phase = GamePhase.ended;
      notifyListeners();
      return;
    }

    if (_state.currentPlayer == PieceOwner.ai) {
      _phase = GamePhase.aiThinking;
      notifyListeners();
      _scheduleAiTurn();
    } else {
      _phase = GamePhase.idle;
      notifyListeners();
    }
  }

  /// Agenda turno da IA com pequeno delay pra parecer humano.
  void _scheduleAiTurn() {
    // 700ms-1200ms aleatório — varia pra não parecer mecânico
    final delayMs = 700 + (DateTime.now().millisecondsSinceEpoch % 500);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_state.currentPlayer != PieceOwner.ai || _state.isGameOver) return;
      final action = _ai.pickAction(_state, _difficulty);
      if (action == null) return;
      _executeAction(action);
    });
  }
}
