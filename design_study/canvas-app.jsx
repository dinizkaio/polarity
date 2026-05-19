// canvas-app.jsx — Design canvas presentation with all Polaridade screens
const { useState: useStateC, useEffect: useEffectC } = React;
const G2 = window.PolarityGame;

// ─────────────────────────────────────────────────────────────
// Build a static game state from a layout
// ─────────────────────────────────────────────────────────────
function buildState(layout, opts = {}) {
  const s = G2.newGame();
  const N = 5;
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      const cell = layout[r]?.[c];
      if (cell) {
        s.board[r][c] = { id: Math.random(), owner: cell.o, polarity: cell.p };
        s.onBoard[cell.o] += 1;
        s.stock[cell.o] = Math.max(0, s.stock[cell.o] - 1);
      }
    }
  }
  return Object.assign(s, opts);
}

// ─────────────────────────────────────────────────────────────
// Static screen wrappers (no interactivity, just visual)
// ─────────────────────────────────────────────────────────────
function StaticGameScreen({
  state, phase = 'idle', selectedPolarity, selectedCell, pendingPlacement,
  epicenter, forceLine, hideLabel, showThinking, aiActive,
}) {
  const previewCells = {};
  if (pendingPlacement) {
    const [r, c] = pendingPlacement;
    previewCells[`${r},${c}`] = { targetable: true };
    if (selectedPolarity) {
      previewCells[`${r},${c}`].ghost = { owner: 'player', polarity: selectedPolarity };
    }
  }

  return (
    <div style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg subtle"><div className="stars dim" /></div>
      <div className="col" style={{ position: 'relative', zIndex: 2, height: '100%', padding: '50px 16px 16px' }}>
        <GameHeader turn={state.turn || 4} maxTurns={10} onMenu={()=>{}} />

        <div style={{ margin: '8px 0 8px' }}>
          <PlayerTray
            side="ai" name="Maestro Mestre"
            stock={state.stock.ai} onBoard={state.onBoard.ai}
            active={aiActive} thinking={showThinking}
          />
        </div>

        <div style={{ flex: 1, display: 'grid', placeItems: 'center', position: 'relative' }}>
          <div style={{ width: '100%', maxWidth: 360, position: 'relative' }}>
            <StaticBoard
              state={state}
              previewCells={previewCells}
              selectedCell={selectedCell}
              epicenter={epicenter}
              forceLine={forceLine}
            />
          </div>
        </div>

        <div style={{ margin: '8px 0' }}>
          <PlayerTray
            side="player" name="Você"
            stock={state.stock.player} onBoard={state.onBoard.player}
            active={!aiActive && !showThinking}
          />
        </div>

        <div style={{ minHeight: 110, paddingTop: 12 }}>
          <StaticActionBar phase={phase} selectedPolarity={selectedPolarity}
            pieceAtSelection={selectedCell ? state.board[selectedCell[0]][selectedCell[1]] : null} />
        </div>
      </div>
    </div>
  );
}

function StaticBoard({ state, previewCells, selectedCell, epicenter, forceLine }) {
  const N = 5;
  const gap = 4, pad = 6;
  return (
    <div style={{ position: 'relative', width: '100%' }}>
      <div className="board" style={{ width: '100%' }}>
        {Array.from({ length: N }).flatMap((_, r) =>
          Array.from({ length: N }).map((_, c) => {
            const p = state.board[r][c];
            const preview = previewCells?.[`${r},${c}`];
            const isSelected = selectedCell && selectedCell[0] === r && selectedCell[1] === c;
            const isEpi = epicenter && epicenter[0] === r && epicenter[1] === c;

            const cls = ['cell'];
            if (!p) cls.push('empty');
            if (preview?.targetable) cls.push('targetable');

            let pieceState = '';
            if (isSelected) pieceState = 'selected';
            if (isEpi) pieceState = 'epicenter';

            return (
              <div key={`${r}-${c}`} className={cls.join(' ')}>
                {p && (
                  <Piece owner={p.owner} polarity={p.polarity} state={pieceState} size="86%" />
                )}
                {preview?.ghost && (
                  <div style={{ width: '78%', height: '78%', opacity: 0.5 }}>
                    <Piece owner={preview.ghost.owner} polarity={preview.ghost.polarity} size="100%" />
                  </div>
                )}
                {preview?.arrow !== undefined && (
                  <div className="cell-arrow">
                    <ArrowIcon angle={preview.arrow} kind={preview.arrowKind} size={16} />
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>
      {forceLine && (
        <ForceLineStatic from={forceLine.from} to={forceLine.to} kind={forceLine.kind} />
      )}
    </div>
  );
}

function ForceLineStatic({ from, to, kind }) {
  const [boardRef, setBoardRef] = useStateC(null);
  const [size, setSize] = useStateC(0);
  useEffectC(() => {
    function measure() {
      if (boardRef) setSize(boardRef.parentElement.getBoundingClientRect().width);
    }
    measure();
    window.addEventListener('resize', measure);
    return () => window.removeEventListener('resize', measure);
  }, [boardRef]);

  if (!size) return <div ref={setBoardRef} style={{ position: 'absolute', inset: 0 }} />;
  const N = 5, gap = 4, pad = 6;
  const cellSize = (size - pad * 2 - gap * (N - 1)) / N;
  const pxFrom = {
    x: pad + from[1] * (cellSize + gap) + cellSize / 2,
    y: pad + from[0] * (cellSize + gap) + cellSize / 2,
  };
  const pxTo = {
    x: pad + to[1] * (cellSize + gap) + cellSize / 2,
    y: pad + to[0] * (cellSize + gap) + cellSize / 2,
  };
  const dx = pxTo.x - pxFrom.x, dy = pxTo.y - pxFrom.y;
  const len = Math.sqrt(dx*dx + dy*dy);
  const angle = Math.atan2(dy, dx) * 180 / Math.PI;
  const isAttract = kind === 'attract';
  return (
    <div ref={setBoardRef} style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      <div style={{
        position: 'absolute',
        left: pxFrom.x, top: pxFrom.y - 1.5,
        width: len, height: 3,
        transform: `rotate(${angle}deg)`,
        transformOrigin: 'left center',
        borderRadius: 2,
        background: isAttract
          ? 'linear-gradient(90deg, transparent, #FFEBC2 60%, #FFFFFF)'
          : 'linear-gradient(90deg, transparent, oklch(0.75 0.22 30) 60%, oklch(0.85 0.20 40))',
        boxShadow: isAttract ? '0 0 12px #FFEBC2' : '0 0 12px oklch(0.75 0.22 30)',
        opacity: 0.95,
      }} />
    </div>
  );
}

function StaticActionBar({ phase, selectedPolarity, pieceAtSelection }) {
  if (phase === 'ai-thinking') {
    return (
      <div className="col" style={{ alignItems: 'center', gap: 4, opacity: 0.7 }}>
        <span className="eyebrow">Vez da IA</span>
        <span style={{ fontSize: 13, color: 'var(--ink-2)' }}>Pensando…</span>
      </div>
    );
  }
  if (phase === 'animating') {
    return (
      <div className="col" style={{ alignItems: 'center', gap: 4, opacity: 0.7 }}>
        <span className="eyebrow">Reação magnética</span>
      </div>
    );
  }
  if (phase === 'choosing-polarity-place') {
    return (
      <div className="col gap-12">
        <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span className="eyebrow">Escolha a polaridade</span>
          <span style={{ fontSize: 11, color: 'var(--ink-3)', fontFamily: 'var(--font-mono)', letterSpacing: '0.1em' }}>CANCELAR</span>
        </div>
        <div className="row gap-12">
          <div className={`btn-polarity plus ${selectedPolarity === 'plus' ? 'selected' : ''}`}>
            <span style={{ fontSize: 30, lineHeight: 1 }}>⊕</span>
            <span style={{ fontSize: 14, fontWeight: 600, opacity: 0.85 }}>Positivo</span>
          </div>
          <div className={`btn-polarity minus ${selectedPolarity === 'minus' ? 'selected' : ''}`}>
            <span style={{ fontSize: 30, lineHeight: 1 }}>⊖</span>
            <span style={{ fontSize: 14, fontWeight: 600, opacity: 0.85 }}>Negativo</span>
          </div>
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
          <span style={{ fontSize: 11, color: 'var(--ink-3)', fontFamily: 'var(--font-mono)', letterSpacing: '0.1em' }}>CANCELAR</span>
        </div>
        <div style={{
          width: '100%', height: 60, borderRadius: 18,
          background: 'linear-gradient(135deg, oklch(0.85 0.18 70 / 0.15), oklch(0.7 0.20 295 / 0.15))',
          boxShadow: 'inset 0 0 0 1.5px rgba(255,255,255,0.15)',
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
          <span style={{ marginLeft: 4 }}>Girar polaridade</span>
        </div>
      </div>
    );
  }
  return (
    <div className="col" style={{ alignItems: 'center', gap: 6 }}>
      <span className="eyebrow">Sua vez</span>
      <span style={{ fontSize: 13, color: 'var(--ink-2)', textAlign: 'center', lineHeight: 1.4 }}>
        Toque em uma casa vazia para colocar, ou em uma peça sua para girá-la.
      </span>
      <div className="row gap-12" style={{ marginTop: 8 }}>
        <div style={{
          border: '1px dashed rgba(255,255,255,0.12)',
          borderRadius: 999, padding: '6px 14px',
          color: 'var(--ink-3)', fontSize: 11, fontFamily: 'var(--font-mono)',
          letterSpacing: '0.1em',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor">
            <path d="M4 1 L8.5 5 L4 9 Z" />
          </svg>
          DICA
        </div>
        <div style={{
          border: '1px dashed rgba(255,255,255,0.12)',
          borderRadius: 999, padding: '6px 14px',
          color: 'var(--ink-3)', fontSize: 11, fontFamily: 'var(--font-mono)',
          letterSpacing: '0.1em',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M2 5 L5 2 L5 8 Z M5 5 L8 2 L8 8 Z" fill="currentColor" />
          </svg>
          DESFAZER
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Phone frame wrapper — minimal iOS-style chrome
// ─────────────────────────────────────────────────────────────
function PhoneFrame({ children, width = 360, height = 780 }) {
  return (
    <div style={{
      width, height, borderRadius: 44, overflow: 'hidden',
      background: '#000',
      boxShadow:
        '0 0 0 10px #1a1a24, 0 0 0 11px rgba(255,255,255,0.05), 0 30px 60px rgba(0,0,0,0.4)',
      position: 'relative',
    }}>
      {/* Dynamic island */}
      <div style={{
        position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
        width: 100, height: 28, borderRadius: 20, background: '#000', zIndex: 50,
      }} />
      <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden' }}>
        {children}
      </div>
      {/* Home indicator */}
      <div style={{
        position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
        width: 110, height: 4, borderRadius: 100, background: 'rgba(255,255,255,0.4)', zIndex: 60,
      }} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Style guide / Anatomy artboard
// ─────────────────────────────────────────────────────────────
function StyleGuide() {
  return (
    <div style={{
      width: '100%', height: '100%', overflow: 'auto',
      background: 'linear-gradient(180deg, #08081f 0%, #0a0a24 100%)',
      color: 'var(--ink)', padding: 28,
    }}>
      <div className="cosmos-bg subtle" style={{ position: 'absolute', inset: 0 }}><div className="stars dim" /></div>
      <div style={{ position: 'relative', zIndex: 2 }}>
        <span className="eyebrow">Sistema visual</span>
        <h2 className="display" style={{ fontSize: 28, margin: '6px 0 24px', fontWeight: 500 }}>
          Anatomia da peça
        </h2>

        {/* Piece anatomy */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20, marginBottom: 32 }}>
          {[
            { o: 'player', p: 'plus', label: 'Jogador · ⊕' },
            { o: 'player', p: 'minus', label: 'Jogador · ⊖' },
            { o: 'ai', p: 'plus', label: 'IA · ⊕' },
            { o: 'ai', p: 'minus', label: 'IA · ⊖' },
          ].map((it, i) => (
            <div key={i} className="col" style={{ alignItems: 'center', gap: 10 }}>
              <div style={{ width: 72, height: 72 }}>
                <Piece owner={it.o} polarity={it.p} size={72} />
              </div>
              <span className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.1em', textAlign: 'center' }}>
                {it.label}
              </span>
            </div>
          ))}
        </div>

        {/* Anatomy callouts */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 32,
        }}>
          <AnatomyCard
            label="Base"
            desc="Cor de base = dono. Branco-quente para o jogador, ciano-frio para a IA. IA tem anel duplo interno para acessibilidade."
          />
          <AnatomyCard
            label="Símbolo"
            desc="⊕ ou ⊖ no centro, sempre visível em todos os tamanhos. Cor escura sobre a peça para máximo contraste."
          />
          <AnatomyCard
            label="Halo"
            desc="Aura difusa por trás. Cor = polaridade (não dono). Dourado para ⊕, violeta para ⊖."
          />
          <AnatomyCard
            label="Estados"
            desc="Normal · Selecionada (pulso) · Epicentro (flash brilho) · Movendo (trail) · Destruindo (fade + partículas)."
          />
        </div>

        {/* Color tokens */}
        <span className="eyebrow">Paleta</span>
        <h3 className="display" style={{ fontSize: 20, margin: '6px 0 16px', fontWeight: 500 }}>
          Tokens de cor
        </h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 28 }}>
          <ColorChip name="bg-void" color="#06061a" />
          <ColorChip name="bg-deep" color="#0a0a24" />
          <ColorChip name="bg-mid" color="#15103a" />
          <ColorChip name="bg-soft" color="#1f1a4a" />
          <ColorChip name="player" color="#FFEBC2" dark />
          <ColorChip name="ai" color="#7EE8FA" dark />
          <ColorChip name="plus (halo)" color="oklch(0.82 0.16 70)" dark />
          <ColorChip name="minus (halo)" color="oklch(0.70 0.20 295)" />
        </div>

        {/* Type scale */}
        <span className="eyebrow">Tipografia</span>
        <h3 className="display" style={{ fontSize: 20, margin: '6px 0 16px', fontWeight: 500 }}>
          Escala tipográfica
        </h3>
        <div className="col gap-12" style={{ marginBottom: 24 }}>
          <TypeRow size={44} font="display" weight={500} label="Display / Title — Space Grotesk 500">Polaridade</TypeRow>
          <TypeRow size={28} font="display" weight={500} label="H1 — Space Grotesk 500">Escolha a dificuldade</TypeRow>
          <TypeRow size={20} font="display" weight={600} label="H2 — Space Grotesk 600">Adepto</TypeRow>
          <TypeRow size={15} font="ui" weight={400} label="Body — Manrope 400">Vence quem tiver mais peças após 20 ações totais.</TypeRow>
          <TypeRow size={11} font="mono" weight={500} label="Eyebrow / Label — JetBrains Mono 500 0.18em">TURNO 04/20</TypeRow>
        </div>

        {/* Spacing & radius */}
        <span className="eyebrow">Sistema</span>
        <h3 className="display" style={{ fontSize: 20, margin: '6px 0 16px', fontWeight: 500 }}>
          Espaçamento e raios
        </h3>
        <div className="row gap-12" style={{ flexWrap: 'wrap' }}>
          {[
            { l: 'Cell radius', v: '12px' },
            { l: 'Board radius', v: '22px' },
            { l: 'Modal radius', v: '28px' },
            { l: 'Button radius', v: '999 / 18 / 20' },
            { l: 'Stack gap', v: '8 · 12 · 16 · 24' },
            { l: 'Page padding', v: '20–28' },
          ].map((it, i) => (
            <div key={i} style={{
              padding: '10px 14px', borderRadius: 12,
              background: 'rgba(255,255,255,0.04)',
              boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.06)',
            }}>
              <div className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.08em' }}>{it.l}</div>
              <div style={{ fontSize: 14, color: 'var(--ink)', fontWeight: 500 }}>{it.v}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function AnatomyCard({ label, desc }) {
  return (
    <div style={{
      padding: 16, borderRadius: 16,
      background: 'rgba(255,255,255,0.03)',
      boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.06)',
    }}>
      <div className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.12em', marginBottom: 6 }}>
        {label.toUpperCase()}
      </div>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.5 }}>{desc}</div>
    </div>
  );
}

function ColorChip({ name, color, dark = false }) {
  return (
    <div className="col" style={{ gap: 6 }}>
      <div style={{
        height: 56, borderRadius: 10, background: color,
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.08)',
      }} />
      <div className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.06em' }}>
        {name}
      </div>
    </div>
  );
}

function TypeRow({ children, size, font, weight, label }) {
  const fontFamily = font === 'display' ? 'var(--font-display)'
    : font === 'mono' ? 'var(--font-mono)' : 'var(--font-ui)';
  const letterSpacing = font === 'mono' ? '0.18em' : font === 'display' ? '-0.01em' : 'normal';
  const text = font === 'mono' && typeof children === 'string' ? children.toUpperCase() : children;
  return (
    <div className="row" style={{
      alignItems: 'baseline', justifyContent: 'space-between',
      gap: 20, paddingBottom: 12,
      borderBottom: '1px solid rgba(255,255,255,0.06)',
    }}>
      <span style={{ fontFamily, fontSize: size, fontWeight: weight, color: 'var(--ink)', letterSpacing }}>{text}</span>
      <span className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.08em', whiteSpace: 'nowrap' }}>
        {label}
      </span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Wave-sequence artboard — illustrates the 8-step order
// ─────────────────────────────────────────────────────────────
function WaveSequence() {
  // A small instructional storyboard
  const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  // tip rotation: 0 = N (up). Then 45° each
  return (
    <div style={{
      width: '100%', height: '100%', overflow: 'auto',
      background: 'linear-gradient(180deg, #08081f 0%, #0a0a24 100%)',
      color: 'var(--ink)', padding: 28,
      position: 'relative',
    }}>
      <div className="cosmos-bg subtle" style={{ position: 'absolute', inset: 0 }}><div className="stars dim" /></div>
      <div style={{ position: 'relative', zIndex: 2 }}>
        <span className="eyebrow">Mecânica · Onda magnética</span>
        <h2 className="display" style={{ fontSize: 28, margin: '6px 0 4px', fontWeight: 500 }}>
          Ordem de resolução
        </h2>
        <p style={{ color: 'var(--ink-2)', fontSize: 13, lineHeight: 1.5, margin: '0 0 24px' }}>
          Quando uma peça vira epicentro, ela emite força em 8 direções no sentido horário começando no Norte.
          Cada vizinho reage em sequência, com um stagger de ~60ms.
        </p>

        {/* Diagram */}
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 4,
          maxWidth: 260, margin: '0 auto 32px', aspectRatio: 1,
        }}>
          {[
            { d: 'NW', i: 7 }, { d: 'N', i: 0 }, { d: 'NE', i: 1 },
            { d: 'W', i: 6 }, { d: '·', i: -1 }, { d: 'E', i: 2 },
            { d: 'SW', i: 5 }, { d: 'S', i: 4 }, { d: 'SE', i: 3 },
          ].map((it, k) => (
            <div key={k} style={{
              aspectRatio: 1, borderRadius: 14,
              display: 'grid', placeItems: 'center',
              background: it.i === -1
                ? 'radial-gradient(circle, #FFEBC2 0%, oklch(0.6 0.18 70) 60%)'
                : 'rgba(255,255,255,0.04)',
              boxShadow: it.i === -1
                ? 'inset 0 0 0 1px rgba(255,255,255,0.4), 0 0 30px oklch(0.7 0.18 70 / 0.5)'
                : 'inset 0 0 0 1px rgba(255,255,255,0.08)',
              position: 'relative',
              color: it.i === -1 ? '#4a2e0a' : 'var(--ink-2)',
            }}>
              {it.i === -1 ? (
                <span style={{ fontFamily: 'var(--font-display)', fontSize: 24, fontWeight: 700 }}>⊕</span>
              ) : (
                <div className="col" style={{ alignItems: 'center', gap: 4 }}>
                  <span style={{
                    fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 600,
                    color: 'var(--ink-2)',
                  }}>{it.d}</span>
                  <span className="mono" style={{
                    fontSize: 10, color: 'oklch(0.85 0.15 70)',
                    background: 'oklch(0.4 0.18 70 / 0.3)',
                    borderRadius: 6, padding: '1px 6px',
                  }}>
                    {String(it.i + 1).padStart(2, '0')}
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Force types */}
        <span className="eyebrow">Forças</span>
        <h3 className="display" style={{ fontSize: 20, margin: '6px 0 16px', fontWeight: 500 }}>
          Atração vs repulsão
        </h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginBottom: 24 }}>
          <ForceCard
            kind="attract"
            title="Atração"
            desc="Polaridades opostas. Linha branca-quente. Vizinha desliza 1 casa em direção ao epicentro."
          />
          <ForceCard
            kind="repel"
            title="Repulsão"
            desc="Polaridades iguais. Linha laranja-quente. Vizinha empurrada. Pode causar cadeia. Peças que saem do tabuleiro são destruídas."
          />
        </div>

        <span className="eyebrow">Casos especiais</span>
        <h3 className="display" style={{ fontSize: 20, margin: '6px 0 12px', fontWeight: 500 }}>
          Quando bloqueia
        </h3>
        <ul style={{
          color: 'var(--ink-2)', fontSize: 13, lineHeight: 1.7, paddingLeft: 18,
        }}>
          <li>Atração com casa destino ocupada (inclusive epicentro) — bloqueia, peça treme no lugar.</li>
          <li>Repulsão em cadeia até casa vazia ou borda do tabuleiro.</li>
          <li>Epicentro nunca se move.</li>
        </ul>
      </div>
    </div>
  );
}

function ForceCard({ kind, title, desc }) {
  const isAttract = kind === 'attract';
  return (
    <div style={{
      padding: 16, borderRadius: 16,
      background: isAttract
        ? 'linear-gradient(135deg, oklch(0.25 0.10 80 / 0.4), oklch(0.10 0.05 80 / 0.2))'
        : 'linear-gradient(135deg, oklch(0.30 0.16 30 / 0.4), oklch(0.10 0.08 30 / 0.2))',
      boxShadow: `inset 0 0 0 1px ${isAttract ? 'oklch(0.7 0.15 80 / 0.3)' : 'oklch(0.7 0.18 30 / 0.3)'}`,
    }}>
      <div className="row gap-8" style={{ marginBottom: 10, alignItems: 'center' }}>
        <div style={{
          width: 20, height: 2, borderRadius: 2,
          background: isAttract
            ? 'linear-gradient(90deg, transparent, #FFEBC2, #FFFFFF)'
            : 'linear-gradient(90deg, transparent, oklch(0.75 0.22 30), oklch(0.85 0.20 40))',
          boxShadow: isAttract ? '0 0 8px #FFEBC2' : '0 0 8px oklch(0.75 0.22 30)',
        }} />
        <span className="display" style={{ fontSize: 17, fontWeight: 600 }}>{title}</span>
      </div>
      <p style={{ color: 'var(--ink-2)', fontSize: 12, lineHeight: 1.5, margin: 0 }}>{desc}</p>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Canvas root
// ─────────────────────────────────────────────────────────────
function CanvasApp() {
  // build static scenarios

  // Scene 1: idle — mid-game
  const sIdle = buildState([
    [null, null, null, null, null],
    [null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}, null],
    [null, null, {o:'ai', p:'plus'}, null, null],
    [null, {o:'player', p:'minus'}, null, null, null],
    [null, null, null, {o:'ai', p:'minus'}, null],
  ], { turn: 4 });

  // Scene 2: choosing polarity to place (preview ghost)
  const sChoosing = buildState([
    [null, null, null, null, null],
    [null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}, null],
    [null, null, {o:'ai', p:'plus'}, null, null],
    [null, {o:'player', p:'minus'}, null, null, null],
    [null, null, null, {o:'ai', p:'minus'}, null],
  ], { turn: 4 });

  // Scene 3: AI thinking
  const sAI = buildState([
    [null, {o:'ai', p:'plus'}, null, null, null],
    [null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}, null],
    [null, null, {o:'player', p:'plus'}, null, null],
    [null, {o:'player', p:'minus'}, null, {o:'ai', p:'minus'}, null],
    [null, null, null, null, {o:'ai', p:'plus'}],
  ], { turn: 6 });

  // Scene 4: magnetic wave mid-action — repulsion in chain
  const sWave = buildState([
    [null, null, null, null, null],
    [null, {o:'player', p:'plus'}, null, null, null],
    [{o:'player', p:'plus'}, {o:'player', p:'plus'}, {o:'ai', p:'plus'}, {o:'ai', p:'plus'}, null],
    [null, {o:'ai', p:'minus'}, null, null, null],
    [null, null, null, null, null],
  ], { turn: 5 });

  // Scene 5: own piece selected (flip ready)
  const sFlip = buildState([
    [null, null, null, null, null],
    [null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}, null],
    [null, null, {o:'player', p:'minus'}, null, null],
    [null, {o:'ai', p:'plus'}, null, null, null],
    [null, null, null, {o:'ai', p:'minus'}, null],
  ], { turn: 5 });

  // Endgame state
  const sEndWin = buildState([
    [{o:'player', p:'plus'}, null, {o:'player', p:'minus'}, null, null],
    [null, {o:'player', p:'plus'}, null, null, null],
    [{o:'player', p:'minus'}, null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}],
    [null, null, null, null, null],
    [null, {o:'player', p:'plus'}, null, null, null],
  ], { turn: 10, actionsTaken: 20 });

  const sEndLose = buildState([
    [null, {o:'ai', p:'plus'}, null, {o:'ai', p:'minus'}, null],
    [{o:'ai', p:'plus'}, null, {o:'ai', p:'plus'}, null, {o:'ai', p:'minus'}],
    [null, null, {o:'player', p:'plus'}, null, null],
    [{o:'ai', p:'minus'}, null, null, {o:'ai', p:'plus'}, null],
    [null, {o:'ai', p:'plus'}, null, null, null],
  ], { turn: 10, actionsTaken: 20 });

  const phoneW = 360, phoneH = 780;
  const artW = phoneW + 24, artH = phoneH + 24;

  return (
    <DesignCanvas>
      <DCSection id="overview" title="Polaridade — Design completo"
        subtitle="Direção Cosmos · todas as telas, estados-chave e sistema visual">
        <DCArtboard id="prototype" label="Protótipo jogável · interativo"
          width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <App />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
      </DCSection>

      <DCSection id="flow" title="Fluxo de menus"
        subtitle="Splash → Menu → Dificuldade · estados estáticos para revisão">
        <DCArtboard id="splash" label="01 · Splash" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <SplashScreen onDone={() => {}} />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="menu" label="02 · Menu principal" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <MenuScreen onPlay={()=>{}} onHowTo={()=>{}} onSettings={()=>{}} onAbout={()=>{}} />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="difficulty" label="03 · Seleção de dificuldade" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <DifficultyScreen onPick={()=>{}} onBack={()=>{}} />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="settings" label="04 · Ajustes" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <SettingsScreen
                settings={{ sound: true, music: true, haptics: true,
                  reducedMotion: false, colorblind: false, hints: true, lang: 'PT-BR' }}
                onBack={()=>{}} onChange={()=>{}}
              />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
      </DCSection>

      <DCSection id="game" title="Tela de jogo · estados"
        subtitle="A tela mais importante. Cada estado documentado.">
        <DCArtboard id="game-idle" label="Sua vez · idle" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <StaticGameScreen state={sIdle} phase="idle" />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="game-choosing" label="Escolhendo polaridade · com ghost"
          width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <StaticGameScreen
                state={sChoosing}
                phase="choosing-polarity-place"
                selectedPolarity="plus"
                pendingPlacement={[2, 1]}
              />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="game-flip" label="Peça selecionada · girar polaridade"
          width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <StaticGameScreen
                state={sFlip}
                phase="choosing-polarity-flip"
                selectedCell={[2, 2]}
              />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="game-ai" label="IA pensando" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <StaticGameScreen
                state={sAI}
                phase="ai-thinking"
                showThinking
                aiActive
              />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="game-wave" label="Onda magnética em curso · repulsão"
          width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <StaticGameScreen
                state={sWave}
                phase="animating"
                epicenter={[2, 2]}
                forceLine={{ from: [2, 2], to: [2, 3], kind: 'repel' }}
              />
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
      </DCSection>

      <DCSection id="modals" title="Modais e fim de partida"
        subtitle="Pausa, fim de partida (vitória/derrota), tutorial">
        <DCArtboard id="endgame-win" label="Fim · Vitória" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <div style={{ position: 'relative', height: '100%' }}>
                <StaticGameScreen state={sEndWin} phase="animating" />
                <EndGameModal result="player" turns={20} playerLeft={6} aiLeft={1}
                  onNew={()=>{}} onMenu={()=>{}} onShare={()=>{}} />
              </div>
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="endgame-lose" label="Fim · Derrota" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <div style={{ position: 'relative', height: '100%' }}>
                <StaticGameScreen state={sEndLose} phase="animating" />
                <EndGameModal result="ai" turns={20} playerLeft={1} aiLeft={7}
                  onNew={()=>{}} onMenu={()=>{}} onShare={()=>{}} />
              </div>
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
        <DCArtboard id="pause" label="Pausa" width={artW} height={artH}>
          <ArtboardWrap>
            <PhoneFrame width={phoneW} height={phoneH}>
              <div style={{ position: 'relative', height: '100%' }}>
                <StaticGameScreen state={sIdle} phase="idle" />
                <PauseModal onResume={()=>{}} onRestart={()=>{}} onQuit={()=>{}} />
              </div>
            </PhoneFrame>
          </ArtboardWrap>
        </DCArtboard>
      </DCSection>

      <DCSection id="tutorial" title="Tutorial · primeiros 5 passos"
        subtitle="Aparece na primeira execução, pulável a qualquer momento">
        {[0, 1, 2, 3, 4].map(step => (
          <DCArtboard key={step} id={`tut-${step}`}
            label={`Passo 0${step+1}`} width={artW} height={artH}>
            <ArtboardWrap>
              <PhoneFrame width={phoneW} height={phoneH}>
                <TutorialScreen step={step} onNext={()=>{}} onSkip={()=>{}} onBack={()=>{}} />
              </PhoneFrame>
            </ArtboardWrap>
          </DCArtboard>
        ))}
      </DCSection>

      <DCSection id="system" title="Sistema visual"
        subtitle="Anatomia da peça, paleta, tipografia, mecânica da onda">
        <DCArtboard id="anatomy" label="Anatomia da peça + tokens"
          width={520} height={780}>
          <StyleGuide />
        </DCArtboard>
        <DCArtboard id="wave-doc" label="Mecânica · Onda magnética"
          width={520} height={780}>
          <WaveSequence />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

function ArtboardWrap({ children }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      display: 'grid', placeItems: 'center',
      background: 'transparent',
    }}>
      {children}
    </div>
  );
}

Object.assign(window, { CanvasApp, StaticGameScreen, PhoneFrame });
