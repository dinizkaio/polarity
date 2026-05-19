// game-components.jsx — Polaridade visual components
const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ─────────────────────────────────────────────────────────────
// Piece — single magnetized disc
// ─────────────────────────────────────────────────────────────
function Piece({ owner, polarity, state, size = 50 }) {
  const cls = ['piece', owner, polarity];
  if (state) cls.push(state);
  return (
    <div className={cls.join(' ')} style={{ width: size, height: size }}>
      <div className="piece-body">
        <span className="piece-symbol">
          {polarity === 'plus' ? '⊕' : '⊖'}
        </span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Arrow overlay for preview
// ─────────────────────────────────────────────────────────────
function ArrowIcon({ angle, kind = 'attract', size = 14 }) {
  const color = kind === 'attract' ? '#FFEBC2' : 'oklch(0.78 0.20 30)';
  return (
    <svg
      width={size} height={size} viewBox="0 0 16 16"
      style={{
        transform: `rotate(${angle}deg)`,
        filter: `drop-shadow(0 0 4px ${color})`,
      }}
    >
      <path d="M8 1 L13 8 L9 8 L9 14 L7 14 L7 8 L3 8 Z" fill={color} />
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Force line — drawn between epicenter and a neighbor
// ─────────────────────────────────────────────────────────────
function ForceLine({ from, to, kind, cellSize, gap = 4, pad = 6 }) {
  // Convert grid coords to pixel position (center of cell)
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
  return (
    <div
      className={`force-line ${kind}`}
      style={{
        left: pxFrom.x,
        top: pxFrom.y - 1,
        width: len,
        transform: `rotate(${angle}deg)`,
      }}
    />
  );
}

// ─────────────────────────────────────────────────────────────
// Board grid
// ─────────────────────────────────────────────────────────────
function Board({
  state, animatingPieces, forceLines, previewCells, selectedCell,
  onCellClick, epicenter, destroyedPieces,
}) {
  const N = 5;
  const cells = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      const p = state.board[r][c];
      const isEmpty = !p;
      const preview = previewCells?.[`${r},${c}`];
      const isSelected = selectedCell && selectedCell[0] === r && selectedCell[1] === c;
      const isEpicenter = epicenter && epicenter[0] === r && epicenter[1] === c;

      const cls = ['cell'];
      if (isEmpty) cls.push('empty');
      if (preview?.targetable) cls.push('targetable');

      let displayPiece = p;
      let pieceState = '';
      if (isSelected) pieceState = 'selected';
      if (isEpicenter) pieceState = 'epicenter';

      cells.push(
        <div
          key={`${r}-${c}`}
          className={cls.join(' ')}
          onClick={() => onCellClick && onCellClick(r, c)}
        >
          {displayPiece && (
            <Piece owner={displayPiece.owner} polarity={displayPiece.polarity} state={pieceState} size="86%" />
          )}
          {preview?.ghost && (
            <div className="preview-ghost" style={{ width: '78%', height: '78%' }}>
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
    }
  }
  return (
    <div className="board" style={{ width: '100%' }}>
      {cells}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Player tray (stock dots + counters)
// ─────────────────────────────────────────────────────────────
function PlayerTray({ side, name, stock, onBoard, active, thinking }) {
  const owner = side; // 'player' | 'ai'
  return (
    <div className={`tray ${active ? 'active' : ''}`}>
      <div style={{
        width: 36, height: 36, borderRadius: 12,
        display: 'grid', placeItems: 'center',
        background: owner === 'player'
          ? 'radial-gradient(circle at 30% 30%, #FFFEF5, #E8C988)'
          : 'radial-gradient(circle at 30% 30%, #C9F8FF, #3DA9C7)',
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.25), 0 2px 8px rgba(0,0,0,0.3)',
      }}>
        <span style={{
          fontFamily: 'var(--font-display)', fontSize: 18, fontWeight: 600,
          color: owner === 'player' ? '#4a2e0a' : '#0a2530',
        }}>
          {owner === 'player' ? '◐' : '◑'}
        </span>
      </div>
      <div className="col" style={{ flex: 1, gap: 2 }}>
        <div className="row" style={{ justifyContent: 'space-between' }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)', letterSpacing: '0.02em' }}>
            {name}
          </span>
          <span className="mono" style={{ fontSize: 11, color: 'var(--ink-3)' }}>
            {thinking ? 'PENSANDO…' : `${onBoard} no tabuleiro`}
          </span>
        </div>
        <div className="row gap-4" style={{ marginTop: 2 }}>
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className={`stock-dot ${i < stock ? owner : 'spent'}`}
              style={{ boxShadow: i < stock ? '0 0 6px rgba(255,255,255,0.2)' : undefined }}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Polarity selector — bottom action bar
// ─────────────────────────────────────────────────────────────
function PolaritySelector({ selectedPolarity, onSelect, onCancel, prompt = 'Escolha a polaridade' }) {
  return (
    <div className="col gap-12" style={{ width: '100%' }}>
      <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
        <span className="eyebrow">{prompt}</span>
        {onCancel && (
          <button onClick={onCancel} style={{
            background: 'transparent', border: 'none', color: 'var(--ink-3)',
            fontSize: 12, cursor: 'pointer', padding: 4,
          }}>Cancelar</button>
        )}
      </div>
      <div className="row gap-12">
        <button
          className={`btn-polarity plus ${selectedPolarity === 'plus' ? 'selected' : ''}`}
          onClick={() => onSelect('plus')}
        >
          ⊕
        </button>
        <button
          className={`btn-polarity minus ${selectedPolarity === 'minus' ? 'selected' : ''}`}
          onClick={() => onSelect('minus')}
        >
          ⊖
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Game header
// ─────────────────────────────────────────────────────────────
function GameHeader({ turn, maxTurns, onMenu }) {
  const critical = turn >= maxTurns - 2;
  return (
    <div className="row" style={{
      padding: '12px 16px',
      justifyContent: 'space-between',
      alignItems: 'center',
    }}>
      <button className="btn-icon" onClick={onMenu} aria-label="Menu">
        <svg width="18" height="14" viewBox="0 0 18 14" fill="none">
          <rect width="18" height="2" rx="1" fill="currentColor" />
          <rect y="6" width="18" height="2" rx="1" fill="currentColor" />
          <rect y="12" width="18" height="2" rx="1" fill="currentColor" />
        </svg>
      </button>
      <div className="col" style={{ alignItems: 'center', gap: 1 }}>
        <span className="display" style={{ fontSize: 16, fontWeight: 600, letterSpacing: '0.06em' }}>
          POLARIDADE
        </span>
        <span className="mono" style={{
          fontSize: 11,
          color: critical ? 'oklch(0.78 0.20 30)' : 'var(--ink-3)',
          letterSpacing: '0.1em',
        }}>
          TURNO {turn}/{maxTurns}
        </span>
      </div>
      <div style={{ width: 44 }} />
    </div>
  );
}

// Export to window
Object.assign(window, {
  Piece, Board, ArrowIcon, ForceLine, PlayerTray, PolaritySelector, GameHeader,
});
