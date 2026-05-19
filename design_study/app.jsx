// app.jsx — Main interactive Polaridade prototype
const { useState: useStateA, useEffect: useEffectA, useRef: useRefA, useMemo: useMemoA } = React;

const G = window.PolarityGame;

// ─────────────────────────────────────────────────────────────
// GameScreen — the heart of the prototype
// ─────────────────────────────────────────────────────────────
function GameScreen({ difficulty, onExitToMenu, onGameEnd }) {
  const [state, setState] = useStateA(() => G.newGame());
  const [phase, setPhase] = useStateA('player-idle');
  // phases: player-idle | choosing-polarity-place | choosing-polarity-flip
  //         | animating | ai-thinking | game-over | paused
  const [selectedPolarity, setSelectedPolarity] = useStateA(null);
  const [selectedCell, setSelectedCell] = useStateA(null); // own piece selected
  const [pendingPlacement, setPendingPlacement] = useStateA(null); // {r, c}
  const [activeForce, setActiveForce] = useStateA(null); // current force line being shown
  const [highlightEpicenter, setHighlightEpicenter] = useStateA(null);
  const [hiddenPieces, setHiddenPieces] = useStateA(() => new Set()); // pieces in motion / destroyed
  const [movingPieces, setMovingPieces] = useStateA([]); // [{from, to, piece, startTime, ...}]
  const [destroying, setDestroying] = useStateA([]); // [{at, piece, dir}]
  const [showPause, setShowPause] = useStateA(false);

  // ─── AI turn ───────────────────────────────────────────────
  useEffectA(() => {
    if (state.currentPlayer !== 'ai' || state.winner) return;
    setPhase('ai-thinking');
    let cancelled = false;
    const thinkTime = 700 + Math.random() * 500;
    const t1 = setTimeout(() => {
      if (cancelled) return;
      const action = G.aiPickAction(state, difficulty);
      if (!action) {
        setPhase('player-idle'); // skip
        return;
      }
      const result = G.applyAction(state, action);
      if (result) {
        runAnimation(result, () => {
          setState(result.newState);
          if (result.newState.winner) {
            setPhase('game-over');
            onGameEnd && onGameEnd(result.newState);
          } else {
            setPhase('player-idle');
          }
        });
      }
    }, thinkTime);
    return () => { cancelled = true; clearTimeout(t1); };
  }, [state.currentPlayer, state.winner]);

  // ─── Animation runner ──────────────────────────────────────
  function runAnimation({ newState, animation }, onDone) {
    setPhase('animating');
    let i = 0;
    function step() {
      if (i >= animation.length) {
        // settle
        setActiveForce(null);
        setHighlightEpicenter(null);
        setMovingPieces([]);
        setDestroying([]);
        setHiddenPieces(new Set());
        onDone && onDone();
        return;
      }
      const ev = animation[i++];
      let delay = 0;
      if (ev.type === 'place' || ev.type === 'flip') {
        setHighlightEpicenter(ev.at);
        delay = 350;
      } else if (ev.type === 'epicenter') {
        setHighlightEpicenter(ev.at);
        delay = 100;
      } else if (ev.type === 'force') {
        setActiveForce({ from: ev.from, to: ev.to, kind: ev.kind, id: i });
        delay = 220;
      } else if (ev.type === 'move') {
        setActiveForce(null);
        setMovingPieces(prev => [...prev, { ...ev, id: i }]);
        setHiddenPieces(prev => new Set([...prev, `${ev.to[0]},${ev.to[1]}`])); // hide at dest until anim done
        setTimeout(() => {
          setMovingPieces(prev => prev.filter(m => m.id !== i));
          setHiddenPieces(prev => {
            const n = new Set(prev);
            n.delete(`${ev.to[0]},${ev.to[1]}`);
            return n;
          });
        }, 320);
        delay = 200;
      } else if (ev.type === 'destroy') {
        setActiveForce(null);
        setDestroying(prev => [...prev, { ...ev, id: i }]);
        setTimeout(() => setDestroying(prev => prev.filter(d => d.id !== i)), 600);
        delay = 280;
      } else if (ev.type === 'shake') {
        delay = 200;
      } else if (ev.type === 'end') {
        delay = 600;
      }
      setTimeout(step, delay);
    }
    step();
  }

  // ─── Cell click handler ────────────────────────────────────
  function handleCellClick(r, c) {
    if (phase !== 'player-idle' && phase !== 'choosing-polarity-place' && phase !== 'choosing-polarity-flip') return;
    if (state.currentPlayer !== 'player') return;
    const cell = state.board[r][c];

    if (phase === 'choosing-polarity-place' && !cell && selectedPolarity) {
      // confirm placement
      const action = { type: 'place', r, c, polarity: selectedPolarity };
      const result = G.applyAction(state, action);
      if (result) {
        setSelectedPolarity(null);
        setPendingPlacement(null);
        setSelectedCell(null);
        runAnimation(result, () => {
          setState(result.newState);
          if (result.newState.winner) {
            setPhase('game-over');
            onGameEnd && onGameEnd(result.newState);
          } else {
            setPhase('player-idle');
          }
        });
      }
      return;
    }

    // idle state
    if (cell && cell.owner === 'player') {
      // select own piece — show flip option
      setSelectedCell([r, c]);
      setPhase('choosing-polarity-flip');
      setSelectedPolarity(null);
    } else if (!cell) {
      // tap empty cell — preview placement
      setPendingPlacement([r, c]);
      setSelectedCell(null);
      setPhase('choosing-polarity-place');
      setSelectedPolarity(null);
    }
  }

  function handlePolarityPick(pol) {
    if (phase === 'choosing-polarity-place' && pendingPlacement) {
      // Setting polarity; tapping cell again confirms
      setSelectedPolarity(pol);
      // Auto-confirm — single tap experience
      const [r, c] = pendingPlacement;
      const action = { type: 'place', r, c, polarity: pol };
      const result = G.applyAction(state, action);
      if (result) {
        setSelectedPolarity(null);
        setPendingPlacement(null);
        setSelectedCell(null);
        runAnimation(result, () => {
          setState(result.newState);
          if (result.newState.winner) {
            setPhase('game-over');
            onGameEnd && onGameEnd(result.newState);
          } else {
            setPhase('player-idle');
          }
        });
      }
    }
  }

  function handleFlip() {
    if (phase !== 'choosing-polarity-flip' || !selectedCell) return;
    const [r, c] = selectedCell;
    const result = G.applyAction(state, { type: 'flip', r, c });
    if (result) {
      setSelectedCell(null);
      runAnimation(result, () => {
        setState(result.newState);
        if (result.newState.winner) {
          setPhase('game-over');
          onGameEnd && onGameEnd(result.newState);
        } else {
          setPhase('player-idle');
        }
      });
    }
  }

  function cancelSelection() {
    setSelectedCell(null);
    setPendingPlacement(null);
    setSelectedPolarity(null);
    setPhase('player-idle');
  }

  // ─── Preview ghost on pending placement ────────────────────
  const previewCells = useMemoA(() => {
    const obj = {};
    if (pendingPlacement) {
      const [r, c] = pendingPlacement;
      obj[`${r},${c}`] = { targetable: true };
      if (selectedPolarity) {
        obj[`${r},${c}`].ghost = { owner: 'player', polarity: selectedPolarity };
      }
    }
    return obj;
  }, [pendingPlacement, selectedPolarity]);

  const isPlayerTurn = state.currentPlayer === 'player' && !state.winner;

  return (
    <div className="screen game-screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg subtle"><div className="stars dim" /></div>
      <div className="col" style={{ position: 'relative', zIndex: 2, height: '100%', padding: '50px 16px 16px' }}>

        <GameHeader turn={Math.min(state.turn, 10)} maxTurns={10} onMenu={() => setShowPause(true)} />

        <div style={{ margin: '8px 0 8px' }}>
          <PlayerTray
            side="ai"
            name="Maestro Mestre"
            stock={state.stock.ai}
            onBoard={state.onBoard.ai}
            active={state.currentPlayer === 'ai' && !state.winner}
            thinking={phase === 'ai-thinking'}
          />
        </div>

        <div style={{ flex: 1, display: 'grid', placeItems: 'center', position: 'relative', margin: '4px 0' }}>
          <div style={{ width: '100%', maxWidth: 360, position: 'relative' }}>
            <BoardWithAnimation
              state={state}
              onCellClick={handleCellClick}
              previewCells={previewCells}
              selectedCell={selectedCell}
              epicenter={highlightEpicenter}
              activeForce={activeForce}
              movingPieces={movingPieces}
              destroying={destroying}
              hiddenPieces={hiddenPieces}
            />
          </div>
        </div>

        <div style={{ margin: '8px 0' }}>
          <PlayerTray
            side="player"
            name="Você"
            stock={state.stock.player}
            onBoard={state.onBoard.player}
            active={isPlayerTurn}
          />
        </div>

        <div style={{ minHeight: 110, paddingTop: 12 }}>
          <ActionBar
            phase={phase}
            isPlayerTurn={isPlayerTurn}
            selectedPolarity={selectedPolarity}
            onPickPolarity={handlePolarityPick}
            onFlip={handleFlip}
            onCancel={cancelSelection}
            selectedCell={selectedCell}
            pieceAtSelection={selectedCell ? state.board[selectedCell[0]][selectedCell[1]] : null}
          />
        </div>
      </div>

      {showPause && (
        <PauseModal
          onResume={() => setShowPause(false)}
          onRestart={() => { setShowPause(false); setState(G.newGame()); setPhase('player-idle'); }}
          onQuit={() => { setShowPause(false); onExitToMenu(); }}
        />
      )}

      {state.winner && phase === 'game-over' && (
        <EndGameModal
          result={state.winner}
          turns={state.actionsTaken}
          playerLeft={state.onBoard.player}
          aiLeft={state.onBoard.ai}
          onNew={() => { setState(G.newGame()); setPhase('player-idle'); }}
          onMenu={onExitToMenu}
          onShare={() => {}}
        />
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Board with animation overlay
// ─────────────────────────────────────────────────────────────
function BoardWithAnimation({
  state, onCellClick, previewCells, selectedCell, epicenter,
  activeForce, movingPieces, destroying, hiddenPieces,
}) {
  const boardRef = useRefA(null);
  const [boardSize, setBoardSize] = useStateA(0);

  useEffectA(() => {
    function measure() {
      if (boardRef.current) {
        setBoardSize(boardRef.current.getBoundingClientRect().width);
      }
    }
    measure();
    const ro = new ResizeObserver(measure);
    if (boardRef.current) ro.observe(boardRef.current);
    return () => ro.disconnect();
  }, []);

  const N = 5;
  const gap = 4, pad = 6;
  const cellSize = (boardSize - pad * 2 - gap * (N - 1)) / N;

  function gridToPx(r, c) {
    return {
      x: pad + c * (cellSize + gap),
      y: pad + r * (cellSize + gap),
    };
  }

  return (
    <div style={{ position: 'relative', width: '100%' }} ref={boardRef}>
      <div className="board" style={{ width: '100%' }}>
        {Array.from({ length: N }).flatMap((_, r) =>
          Array.from({ length: N }).map((_, c) => {
            const p = state.board[r][c];
            const preview = previewCells?.[`${r},${c}`];
            const isSelected = selectedCell && selectedCell[0] === r && selectedCell[1] === c;
            const isEpi = epicenter && epicenter[0] === r && epicenter[1] === c;
            const hidden = hiddenPieces.has(`${r},${c}`);

            const cls = ['cell'];
            if (!p) cls.push('empty');
            if (preview?.targetable) cls.push('targetable');

            let pieceState = '';
            if (isSelected) pieceState = 'selected';
            if (isEpi) pieceState = 'epicenter';

            return (
              <div
                key={`${r}-${c}`}
                className={cls.join(' ')}
                onClick={() => onCellClick && onCellClick(r, c)}
              >
                {p && !hidden && (
                  <Piece owner={p.owner} polarity={p.polarity} state={pieceState} size="86%" />
                )}
                {preview?.ghost && (
                  <div style={{ width: '78%', height: '78%', opacity: 0.5 }}>
                    <Piece owner={preview.ghost.owner} polarity={preview.ghost.polarity} size="100%" />
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>

      {/* Overlay layer for force lines and moving pieces */}
      {cellSize > 0 && (
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
        }}>
          {activeForce && (
            <ForceLine
              from={activeForce.from}
              to={activeForce.to}
              kind={activeForce.kind}
              cellSize={cellSize}
              gap={gap}
              pad={pad}
            />
          )}
          {movingPieces.map(m => {
            const fromPx = gridToPx(m.from[0], m.from[1]);
            const toPx = gridToPx(m.to[0], m.to[1]);
            return (
              <div
                key={m.id}
                style={{
                  position: 'absolute',
                  width: cellSize, height: cellSize,
                  left: fromPx.x, top: fromPx.y,
                  transform: `translate(${toPx.x - fromPx.x}px, ${toPx.y - fromPx.y}px)`,
                  transition: `transform 0.3s ${(m.chainIndex || 0) * 40}ms cubic-bezier(0.3, 1.3, 0.5, 1)`,
                }}
              >
                <Piece owner={m.piece.owner} polarity={m.piece.polarity} size="86%" />
              </div>
            );
          })}
          {destroying.map(d => {
            const fromPx = gridToPx(d.from[0], d.from[1]);
            const [dr, dc] = d.dir;
            const dx = dc * cellSize * 1.4;
            const dy = dr * cellSize * 1.4;
            return (
              <div
                key={d.id}
                style={{
                  position: 'absolute',
                  width: cellSize, height: cellSize,
                  left: fromPx.x, top: fromPx.y,
                  transform: `translate(${dx}px, ${dy}px) scale(0.2)`,
                  opacity: 0,
                  transition: 'transform 0.5s ease-out, opacity 0.5s ease-out, filter 0.5s ease-out',
                  filter: 'blur(8px)',
                  zIndex: 10,
                }}
              >
                <Piece owner={d.piece.owner} polarity={d.piece.polarity} state="destroying" size="86%" />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Action bar
// ─────────────────────────────────────────────────────────────
function ActionBar({
  phase, isPlayerTurn, selectedPolarity, onPickPolarity,
  onFlip, onCancel, selectedCell, pieceAtSelection,
}) {
  if (!isPlayerTurn && phase !== 'choosing-polarity-place' && phase !== 'choosing-polarity-flip') {
    return (
      <div className="col" style={{ alignItems: 'center', gap: 4, opacity: 0.6 }}>
        <span className="eyebrow">
          {phase === 'ai-thinking' ? 'Vez da IA' : phase === 'animating' ? 'Reação magnética' : 'Aguardando'}
        </span>
        <div className="row gap-8" style={{ marginTop: 4 }}>
          <div style={{ width: 60, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.06)' }}>
            <div style={{
              width: '30%', height: '100%', borderRadius: 2,
              background: 'linear-gradient(90deg, var(--minus), var(--plus))',
              animation: 'load-slide 1.4s ease-in-out infinite',
            }} />
          </div>
        </div>
        <style>{`
          @keyframes load-slide {
            0% { transform: translateX(0); width: 20%; }
            50% { transform: translateX(150%); width: 30%; }
            100% { transform: translateX(330%); width: 20%; }
          }
        `}</style>
      </div>
    );
  }

  if (phase === 'choosing-polarity-place') {
    return (
      <div className="col gap-12">
        <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span className="eyebrow">Escolha a polaridade</span>
          <button onClick={onCancel} style={{
            background: 'transparent', border: 'none', color: 'var(--ink-3)',
            fontSize: 11, cursor: 'pointer', padding: 4,
            fontFamily: 'var(--font-mono)', letterSpacing: '0.1em',
          }}>CANCELAR</button>
        </div>
        <div className="row gap-12">
          <button className={`btn-polarity plus ${selectedPolarity === 'plus' ? 'selected' : ''}`}
            onClick={() => onPickPolarity('plus')}>
            <span style={{ fontSize: 30, lineHeight: 1 }}>⊕</span>
            <span style={{ fontSize: 14, fontWeight: 600, opacity: 0.85 }}>Positivo</span>
          </button>
          <button className={`btn-polarity minus ${selectedPolarity === 'minus' ? 'selected' : ''}`}
            onClick={() => onPickPolarity('minus')}>
            <span style={{ fontSize: 30, lineHeight: 1 }}>⊖</span>
            <span style={{ fontSize: 14, fontWeight: 600, opacity: 0.85 }}>Negativo</span>
          </button>
        </div>
      </div>
    );
  }

  if (phase === 'choosing-polarity-flip' && pieceAtSelection) {
    const from = pieceAtSelection.polarity;
    const to = from === 'plus' ? 'minus' : 'plus';
    return (
      <div className="col gap-12">
        <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span className="eyebrow">Peça selecionada</span>
          <button onClick={onCancel} style={{
            background: 'transparent', border: 'none', color: 'var(--ink-3)',
            fontSize: 11, cursor: 'pointer', padding: 4,
            fontFamily: 'var(--font-mono)', letterSpacing: '0.1em',
          }}>CANCELAR</button>
        </div>
        <button onClick={onFlip} style={{
          width: '100%', height: 60, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'linear-gradient(135deg, oklch(0.85 0.18 70 / 0.15), oklch(0.7 0.20 295 / 0.15))',
          boxShadow: 'inset 0 0 0 1.5px rgba(255,255,255,0.15), 0 0 24px rgba(255,255,255,0.05)',
          color: 'var(--ink)',
          fontFamily: 'var(--font-ui)', fontSize: 15, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 14,
        }}>
          <span style={{ fontSize: 22, fontFamily: 'var(--font-display)',
            color: from === 'plus' ? 'oklch(0.85 0.18 70)' : 'oklch(0.7 0.20 295)' }}>
            {from === 'plus' ? '⊕' : '⊖'}
          </span>
          <svg width="20" height="14" viewBox="0 0 20 14" fill="none">
            <path d="M2 7 L18 7 M14 3 L18 7 L14 11" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
          <span style={{ fontSize: 22, fontFamily: 'var(--font-display)',
            color: to === 'plus' ? 'oklch(0.85 0.18 70)' : 'oklch(0.7 0.20 295)' }}>
            {to === 'plus' ? '⊕' : '⊖'}
          </span>
          <span style={{ marginLeft: 6 }}>Girar polaridade</span>
        </button>
      </div>
    );
  }

  // idle player turn — instructions
  return (
    <div className="col" style={{ alignItems: 'center', gap: 6 }}>
      <span className="eyebrow">Sua vez</span>
      <span style={{ fontSize: 13, color: 'var(--ink-2)', textAlign: 'center', lineHeight: 1.4 }}>
        Toque em uma casa vazia para colocar, ou em uma peça sua para girá-la.
      </span>
      <div className="row gap-12" style={{ marginTop: 8 }}>
        <button style={{
          background: 'transparent', border: '1px dashed rgba(255,255,255,0.12)',
          borderRadius: 999, padding: '6px 14px', cursor: 'pointer',
          color: 'var(--ink-3)', fontSize: 11, fontFamily: 'var(--font-mono)',
          letterSpacing: '0.1em',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor">
            <path d="M4 1 L8.5 5 L4 9 Z" />
          </svg>
          DICA
        </button>
        <button style={{
          background: 'transparent', border: '1px dashed rgba(255,255,255,0.12)',
          borderRadius: 999, padding: '6px 14px', cursor: 'pointer',
          color: 'var(--ink-3)', fontSize: 11, fontFamily: 'var(--font-mono)',
          letterSpacing: '0.1em',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M2 5 L5 2 L5 8 Z M5 5 L8 2 L8 8 Z" fill="currentColor" />
          </svg>
          DESFAZER
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Top-level App
// ─────────────────────────────────────────────────────────────
function App() {
  const [screen, setScreen] = useStateA('menu'); // splash | menu | difficulty | game | tutorial | settings
  const [difficulty, setDifficulty] = useStateA('adept');
  const [tutorialStep, setTutorialStep] = useStateA(0);
  const [settings, setSettings] = useStateA({
    sound: true, music: true, haptics: true,
    reducedMotion: false, colorblind: false, hints: true,
    lang: 'PT-BR',
  });

  function updateSetting(key, value) {
    setSettings(s => ({ ...s, [key]: value }));
  }

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden' }}>
      {screen === 'splash' && <SplashScreen onDone={() => setScreen('menu')} />}
      {screen === 'menu' && (
        <MenuScreen
          onPlay={() => setScreen('difficulty')}
          onHowTo={() => { setTutorialStep(0); setScreen('tutorial'); }}
          onSettings={() => setScreen('settings')}
          onAbout={() => setScreen('settings')}
        />
      )}
      {screen === 'difficulty' && (
        <DifficultyScreen
          onPick={(d) => { setDifficulty(d); setScreen('game'); }}
          onBack={() => setScreen('menu')}
        />
      )}
      {screen === 'game' && (
        <GameScreen
          difficulty={difficulty}
          onExitToMenu={() => setScreen('menu')}
          onGameEnd={() => {}}
        />
      )}
      {screen === 'tutorial' && (
        <TutorialScreen
          step={tutorialStep}
          onNext={() => {
            if (tutorialStep < 4) setTutorialStep(s => s + 1);
            else setScreen('difficulty');
          }}
          onSkip={() => setScreen('menu')}
          onBack={() => {
            if (tutorialStep > 0) setTutorialStep(s => s - 1);
            else setScreen('menu');
          }}
        />
      )}
      {screen === 'settings' && (
        <SettingsScreen
          settings={settings}
          onChange={updateSetting}
          onBack={() => setScreen('menu')}
        />
      )}
    </div>
  );
}

Object.assign(window, { App, GameScreen, BoardWithAnimation, ActionBar });
