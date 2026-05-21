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
  idle,
  choosingPolarity,
  selectingPiece,
  previewing,
  resolving,
  aiThinking,
  ended,
}

/// Provider principal. Orquestra estado + IA + animações.
///
/// Suporta dois modos:
/// - **vs IA** (padrão): jogador humano contra a IA.
/// - **local 1×1** (`localMultiplayer = true`): duas pessoas no mesmo
///   dispositivo, alternando turnos. Sem IA, ambos `PieceOwner.player`
///   e `PieceOwner.ai` representam jogadores humanos (P1 e P2).
class GameProvider extends ChangeNotifier {
  AiDifficulty _difficulty;
  int _maxTurns;
  final bool _localMultiplayer;
  bool _previewEnabled;
  final AiEngine _ai;

  late GameState _state;
  GamePhase _phase = GamePhase.idle;
  List<AnimationEvent> _pendingEvents = const [];

  ({int row, int col})? _selectedEmptyCell;
  ({int row, int col})? _selectedPiece;

  // Estado de preview de jogada
  ActionResult? _previewResult;
  GameAction? _previewAction;
  Polarity? _previewPolarity;

  GameProvider({
    AiDifficulty difficulty = AiDifficulty.apprentice,
    int maxTurns = GameState.defaultMaxTurns,
    bool localMultiplayer = false,
    bool previewEnabled = false,
  })  : _difficulty = difficulty,
        _maxTurns = maxTurns,
        _localMultiplayer = localMultiplayer,
        _previewEnabled = previewEnabled,
        _ai = AiEngine() {
    _state = GameState.newGame(maxTurns: maxTurns);
    _bootstrapTurn();
  }

  bool get previewEnabled => _previewEnabled;
  set previewEnabled(bool v) {
    if (_previewEnabled == v) return;
    _previewEnabled = v;
    notifyListeners();
  }

  ActionResult? get previewResult => _previewResult;
  GameAction? get previewAction => _previewAction;
  Polarity? get previewPolarity => _previewPolarity;

  int get maxTurns => _maxTurns;
  bool get localMultiplayer => _localMultiplayer;

  /// Quem está jogando agora é humano? No modo local, sempre é.
  /// No modo vs IA, só se for o PieceOwner.player.
  bool get currentTurnIsHuman {
    if (_localMultiplayer) return true;
    return _state.currentPlayer == PieceOwner.player;
  }

  void _bootstrapTurn() {
    if (_localMultiplayer) {
      _phase = GamePhase.idle;
      return;
    }
    if (_state.currentPlayer == PieceOwner.ai && !_state.isGameOver) {
      _phase = GamePhase.aiThinking;
      _scheduleAiTurn();
    }
  }

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

  void newGame() {
    _state = GameState.newGame(maxTurns: _maxTurns);
    _phase = GamePhase.idle;
    _pendingEvents = const [];
    _selectedEmptyCell = null;
    _selectedPiece = null;
    _bootstrapTurn();
    notifyListeners();
  }

  void tapCell(int row, int col) {
    if (_phase != GamePhase.idle &&
        _phase != GamePhase.choosingPolarity &&
        _phase != GamePhase.selectingPiece) {
      return;
    }
    if (!currentTurnIsHuman) return;

    final piece = _state.pieceAt(row, col);
    final owner = _state.currentPlayer;

    if (piece == null) {
      if ((_state.stock[owner] ?? 0) <= 0) return;
      _selectedEmptyCell = (row: row, col: col);
      _selectedPiece = null;
      _phase = GamePhase.choosingPolarity;
      notifyListeners();
    } else if (piece.owner == owner) {
      _selectedPiece = (row: row, col: col);
      _selectedEmptyCell = null;
      _phase = GamePhase.selectingPiece;
      notifyListeners();
    }
  }

  void cancelSelection() {
    _selectedEmptyCell = null;
    _selectedPiece = null;
    _previewResult = null;
    _previewAction = null;
    _previewPolarity = null;
    _phase = GamePhase.idle;
    notifyListeners();
  }

  /// Place de uma peça: se preview ligado, entra em modo previewing.
  /// Senão, executa direto.
  void confirmPlace(Polarity polarity) {
    final cell = _selectedEmptyCell;
    if (cell == null) return;
    if (!currentTurnIsHuman) return;
    final action = PlaceAction(row: cell.row, col: cell.col, polarity: polarity);
    if (_previewEnabled) {
      _enterPreview(action, polarity);
    } else {
      _executeAction(action);
    }
  }

  /// Flip para uma polaridade: se preview ligado, entra em modo previewing.
  /// Senão, executa direto.
  void confirmFlip(Polarity targetPolarity) {
    final cell = _selectedPiece;
    if (cell == null) return;
    if (!currentTurnIsHuman) return;
    final action = FlipAction(
      row: cell.row,
      col: cell.col,
      targetPolarity: targetPolarity,
    );
    if (_previewEnabled) {
      _enterPreview(action, targetPolarity);
    } else {
      _executeAction(action);
    }
  }

  void _enterPreview(GameAction action, Polarity polarity) {
    final result = GameLogic.applyAction(_state, action);
    if (result == null) return;
    _previewAction = action;
    _previewPolarity = polarity;
    _previewResult = result;
    _phase = GamePhase.previewing;
    notifyListeners();
  }

  /// Confirma a jogada visualizada — executa de verdade (com animações).
  void confirmPreview() {
    final action = _previewAction;
    if (action == null) return;
    _previewResult = null;
    _previewAction = null;
    _previewPolarity = null;
    _executeAction(action);
  }

  /// Cancela o preview e volta pra seleção anterior.
  void cancelPreview() {
    final wasPlace = _previewAction is PlaceAction;
    _previewResult = null;
    _previewAction = null;
    _previewPolarity = null;
    _phase = wasPlace
        ? (_selectedEmptyCell != null ? GamePhase.choosingPolarity : GamePhase.idle)
        : (_selectedPiece != null ? GamePhase.selectingPiece : GamePhase.idle);
    notifyListeners();
  }

  /// Quantas peças neutras [owner] tem no tabuleiro (limite é 2).
  int neutralsOwnedBy(PieceOwner owner) =>
      GameLogic.countNeutralsFor(_state, owner);

  bool canPlaceNeutral(PieceOwner owner) => neutralsOwnedBy(owner) < 2;

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

  void onAnimationComplete() {
    _pendingEvents = const [];

    if (_state.isGameOver) {
      _phase = GamePhase.ended;
      notifyListeners();
      return;
    }

    if (_localMultiplayer) {
      // Próximo turno também humano — não agenda IA
      _phase = GamePhase.idle;
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

  void _scheduleAiTurn() {
    final delayMs = 700 + (DateTime.now().millisecondsSinceEpoch % 500);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_state.currentPlayer != PieceOwner.ai || _state.isGameOver) return;
      final action = _ai.pickAction(_state, _difficulty);
      if (action == null) return;
      _executeAction(action);
    });
  }
}
