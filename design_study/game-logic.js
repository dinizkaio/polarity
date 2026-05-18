// game-logic.js — Polaridade game rules
// Pure functions; no React, no DOM.

const BOARD_SIZE = 5;
const STOCK_SIZE = 6;
const MAX_TURNS = 20;

// Directions in resolution order: N, NE, E, SE, S, SW, W, NW
const DIRS = [
  [-1,  0], // N
  [-1,  1], // NE
  [ 0,  1], // E
  [ 1,  1], // SE
  [ 1,  0], // S
  [ 1, -1], // SW
  [ 0, -1], // W
  [-1, -1], // NW
];

const DIR_NAMES = ['N','NE','E','SE','S','SW','W','NW'];

let pieceIdCounter = 1;
function newPiece(owner, polarity) {
  return { id: pieceIdCounter++, owner, polarity };
}

function emptyBoard() {
  return Array.from({ length: BOARD_SIZE }, () =>
    Array.from({ length: BOARD_SIZE }, () => null)
  );
}

function clone(state) {
  return {
    board: state.board.map(row => row.map(c => c ? { ...c } : null)),
    stock: { ...state.stock },
    onBoard: { ...state.onBoard },
    turn: state.turn,
    actionsTaken: state.actionsTaken,
    currentPlayer: state.currentPlayer,
    winner: state.winner,
  };
}

function newGame() {
  return {
    board: emptyBoard(),
    stock: { player: STOCK_SIZE, ai: STOCK_SIZE },
    onBoard: { player: 0, ai: 0 },
    turn: 1,
    actionsTaken: 0,
    currentPlayer: 'player',
    winner: null,
  };
}

function inBounds(r, c) {
  return r >= 0 && r < BOARD_SIZE && c >= 0 && c < BOARD_SIZE;
}

// Given a state and an action ({type:'place', r, c, polarity} | {type:'flip', r, c}),
// returns { newState, animation: [step, ...] }
// Animation steps:
//   { type: 'epicenter', at: [r,c] }
//   { type: 'place', at: [r,c], piece }
//   { type: 'flip', at: [r,c], piece }
//   { type: 'force', from: [er,ec], to: [r,c], kind: 'attract'|'repel' }
//   { type: 'move', from, to, piece }
//   { type: 'shake', at }
//   { type: 'destroy', at, piece }
//   { type: 'end', winner }
function applyAction(state, action) {
  const s = clone(state);
  const owner = s.currentPlayer;
  const anim = [];
  let er, ec, piece;

  if (action.type === 'place') {
    const { r, c, polarity } = action;
    if (s.board[r][c]) return null;
    if (s.stock[owner] <= 0) return null;
    piece = newPiece(owner, polarity);
    s.board[r][c] = piece;
    s.stock[owner] -= 1;
    s.onBoard[owner] += 1;
    er = r; ec = c;
    anim.push({ type: 'place', at: [r, c], piece: { ...piece } });
  } else if (action.type === 'flip') {
    const { r, c } = action;
    const p = s.board[r][c];
    if (!p || p.owner !== owner) return null;
    p.polarity = p.polarity === 'plus' ? 'minus' : 'plus';
    piece = p;
    er = r; ec = c;
    anim.push({ type: 'flip', at: [r, c], piece: { ...piece } });
  } else return null;

  anim.push({ type: 'epicenter', at: [er, ec] });

  // Resolve wave in fixed order
  for (let i = 0; i < DIRS.length; i++) {
    const [dr, dc] = DIRS[i];
    const nr = er + dr, nc = ec + dc;
    if (!inBounds(nr, nc)) continue;
    const neighbor = s.board[nr][nc];
    if (!neighbor) continue;

    const same = neighbor.polarity === piece.polarity;

    if (!same) {
      // Attraction: move toward epicenter (i.e. by -dir)
      const tr = nr - dr, tc = nc - dc;
      anim.push({ type: 'force', from: [er, ec], to: [nr, nc], kind: 'attract' });
      // destination = (tr,tc). It's the epicenter cell itself if neighbor adj to epicenter.
      if (!inBounds(tr, tc) || s.board[tr][tc]) {
        // Blocked (epicenter occupies the destination)
        anim.push({ type: 'shake', at: [nr, nc] });
      } else {
        s.board[tr][tc] = neighbor;
        s.board[nr][nc] = null;
        anim.push({ type: 'move', from: [nr, nc], to: [tr, tc], piece: { ...neighbor } });
      }
    } else {
      // Repulsion: chain push away from epicenter (by +dir)
      anim.push({ type: 'force', from: [er, ec], to: [nr, nc], kind: 'repel' });
      // Collect chain
      const chain = [];
      let cr = nr, cc = nc;
      while (inBounds(cr, cc) && s.board[cr][cc]) {
        chain.push([cr, cc]);
        cr += dr; cc += dc;
      }
      // chain holds occupied cells along the line; cr,cc is either OOB or empty cell
      // Move from the end of chain backwards
      // First: piece at end of chain goes to (cr,cc) — either off-board (destroy) or empty cell
      const destinations = [];
      for (let k = chain.length - 1; k >= 0; k--) {
        const [pr, pc] = chain[k];
        const dr2 = pr + dr, dc2 = pc + dc;
        destinations.unshift([dr2, dc2]);
      }
      // Now apply with staggered animation
      for (let k = chain.length - 1; k >= 0; k--) {
        const [pr, pc] = chain[k];
        const [tr2, tc2] = destinations[k];
        const movingPiece = s.board[pr][pc];
        s.board[pr][pc] = null;
        if (!inBounds(tr2, tc2)) {
          s.onBoard[movingPiece.owner] -= 1;
          anim.push({ type: 'destroy', from: [pr, pc], dir: [dr, dc], piece: { ...movingPiece } });
        } else {
          s.board[tr2][tc2] = movingPiece;
          anim.push({ type: 'move', from: [pr, pc], to: [tr2, tc2], piece: { ...movingPiece }, chainIndex: chain.length - 1 - k });
        }
      }
    }
  }

  s.actionsTaken += 1;
  // Check win conditions
  const otherOwner = owner === 'player' ? 'ai' : 'player';

  let winner = null;
  if (s.onBoard[otherOwner] === 0 && s.stock[otherOwner] === 0) {
    winner = owner;
  } else if (s.onBoard[owner] === 0 && s.stock[owner] === 0) {
    winner = otherOwner;
  } else if (s.actionsTaken >= MAX_TURNS) {
    if (s.onBoard.player > s.onBoard.ai) winner = 'player';
    else if (s.onBoard.ai > s.onBoard.player) winner = 'ai';
    else winner = 'ai'; // pie rule: ties go to second player (AI in this default)
  }

  s.winner = winner;
  if (winner) anim.push({ type: 'end', winner });

  s.currentPlayer = otherOwner;
  if (action.type === 'place' || action.type === 'flip') {
    // advance turn counter every 2 actions
    if (s.actionsTaken % 2 === 0) s.turn += 1;
  }

  return { newState: s, animation: anim };
}

// Simple AI: random valid move. Good enough for prototype demo.
// In production, you'd have a minimax with the 3 difficulty depths.
function aiPickAction(state, difficulty = 'apprentice') {
  // Look 1 move ahead: prefer moves that destroy opponent pieces, then placements
  const owner = 'ai';
  const candidates = [];

  // All placements
  for (let r = 0; r < BOARD_SIZE; r++) {
    for (let c = 0; c < BOARD_SIZE; c++) {
      if (state.board[r][c]) continue;
      if (state.stock.ai <= 0) break;
      for (const polarity of ['plus', 'minus']) {
        candidates.push({ type: 'place', r, c, polarity });
      }
    }
  }
  // All flips
  for (let r = 0; r < BOARD_SIZE; r++) {
    for (let c = 0; c < BOARD_SIZE; c++) {
      const p = state.board[r][c];
      if (p && p.owner === 'ai') {
        candidates.push({ type: 'flip', r, c });
      }
    }
  }

  if (candidates.length === 0) return null;

  // Score each candidate by net pieces gained
  let best = candidates[0];
  let bestScore = -Infinity;
  for (const action of candidates) {
    const result = applyAction(state, action);
    if (!result) continue;
    const s2 = result.newState;
    const score = (s2.onBoard.ai - state.onBoard.ai) - (s2.onBoard.player - state.onBoard.player) * 1.5
      + Math.random() * 0.3; // small randomness
    if (score > bestScore) { bestScore = score; best = action; }
  }
  return best;
}

window.PolarityGame = {
  BOARD_SIZE, STOCK_SIZE, MAX_TURNS, DIRS, DIR_NAMES,
  newGame, applyAction, aiPickAction, newPiece, emptyBoard, inBounds,
};
