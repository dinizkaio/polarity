// screens.jsx — Polaridade screens (Splash, Menu, Difficulty, EndGame, etc.)
const { useState: useStateS, useEffect: useEffectS } = React;

// ─────────────────────────────────────────────────────────────
// Splash
// ─────────────────────────────────────────────────────────────
function SplashScreen({ onDone }) {
  useEffectS(() => {
    const t = setTimeout(() => onDone && onDone(), 2400);
    return () => clearTimeout(t);
  }, [onDone]);
  return (
    <div className="screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg"><div className="stars twinkle" /></div>
      <div className="nebula-orb" style={{ width: 280, height: 280, top: '20%', left: '-10%',
        background: 'radial-gradient(circle, oklch(0.55 0.20 290), transparent)' }} />
      <div className="nebula-orb" style={{ width: 220, height: 220, bottom: '10%', right: '-15%',
        background: 'radial-gradient(circle, oklch(0.55 0.16 340), transparent)' }} />
      <div className="col" style={{
        position: 'relative', zIndex: 2, height: '100%',
        justifyContent: 'center', alignItems: 'center', gap: 32, padding: 32,
      }}>
        <SplashLogo />
        <div className="col" style={{ alignItems: 'center', gap: 6 }}>
          <h1 className="display" style={{
            fontSize: 44, margin: 0, letterSpacing: '-0.02em',
            background: 'linear-gradient(180deg, #FFFFFF, #FFEBC2)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            backgroundClip: 'text', color: 'transparent',
          }}>
            Polaridade
          </h1>
          <p style={{
            fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.25em',
            margin: 0, color: 'var(--ink-3)', textTransform: 'uppercase',
          }}>
            Gravidade em duelo
          </p>
        </div>
      </div>
      <div style={{
        position: 'absolute', bottom: 60, left: '50%', transform: 'translateX(-50%)',
        display: 'flex', gap: 6,
      }}>
        {[0,1,2].map(i => (
          <div key={i} style={{
            width: 6, height: 6, borderRadius: '50%',
            background: 'var(--ink-3)',
            animation: `splash-dot 1.4s ease-in-out ${i * 0.2}s infinite`,
          }} />
        ))}
      </div>
      <style>{`
        @keyframes splash-dot {
          0%, 100% { opacity: 0.2; transform: scale(0.8); }
          50% { opacity: 1; transform: scale(1.1); }
        }
      `}</style>
    </div>
  );
}

function SplashLogo({ size = 120 }) {
  // Two pieces orbiting — animated logo
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <div style={{
        position: 'absolute', inset: 0,
        animation: 'logo-orbit 8s linear infinite',
      }}>
        <div style={{ position: 'absolute', top: '50%', left: -8, transform: 'translateY(-50%)' }}>
          <Piece owner="player" polarity="plus" size={48} />
        </div>
        <div style={{ position: 'absolute', top: '50%', right: -8, transform: 'translateY(-50%)' }}>
          <Piece owner="ai" polarity="minus" size={48} />
        </div>
      </div>
      <div style={{
        position: 'absolute', inset: '40%', borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,255,255,0.6), transparent)',
        filter: 'blur(8px)', animation: 'logo-pulse 2s ease-in-out infinite',
      }} />
      <style>{`
        @keyframes logo-orbit {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @keyframes logo-pulse {
          0%, 100% { opacity: 0.5; transform: scale(0.9); }
          50% { opacity: 1; transform: scale(1.2); }
        }
      `}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main Menu
// ─────────────────────────────────────────────────────────────
function MenuScreen({ onPlay, onHowTo, onSettings, onAbout }) {
  return (
    <div className="screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg"><div className="stars twinkle" /></div>
      {/* floating decorative pieces */}
      <FloatingPiece owner="player" polarity="plus" top="14%" left="12%" delay={0} />
      <FloatingPiece owner="ai" polarity="minus" top="22%" right="14%" delay={1.5} />
      <FloatingPiece owner="player" polarity="minus" top="62%" left="8%" delay={0.8} />
      <FloatingPiece owner="ai" polarity="plus" top="70%" right="10%" delay={2.2} />

      <div className="col" style={{
        position: 'relative', zIndex: 2, height: '100%',
        justifyContent: 'space-between', padding: '80px 28px 40px',
      }}>
        <div className="col" style={{ alignItems: 'center', gap: 14, marginTop: 24 }}>
          <SplashLogo size={92} />
          <div className="col" style={{ alignItems: 'center', gap: 4 }}>
            <h1 className="display" style={{
              fontSize: 36, margin: 0, fontWeight: 500,
              background: 'linear-gradient(180deg, #FFFFFF, #FFEBC2)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
              backgroundClip: 'text', color: 'transparent',
            }}>Polaridade</h1>
            <span className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.3em' }}>
              ATRAÇÃO · REPULSÃO · VITÓRIA
            </span>
          </div>
        </div>

        <div className="col gap-12" style={{ width: '100%' }}>
          <button className="btn btn-primary" onClick={onPlay} style={{ width: '100%', height: 60, fontSize: 18 }}>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
              <path d="M4 2 L13 8 L4 14 Z" />
            </svg>
            Jogar
          </button>
          <div className="row gap-8">
            <button className="btn btn-ghost f1" onClick={onHowTo}>Como jogar</button>
            <button className="btn btn-ghost f1" onClick={onSettings}>Ajustes</button>
          </div>
          <button onClick={onAbout} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            color: 'var(--ink-3)', fontSize: 12, padding: 12, marginTop: 4,
            fontFamily: 'var(--font-mono)', letterSpacing: '0.1em',
          }}>
            SOBRE · v0.1
          </button>
        </div>
      </div>
    </div>
  );
}

function FloatingPiece({ owner, polarity, top, left, right, delay = 0 }) {
  return (
    <div style={{
      position: 'absolute', top, left, right, zIndex: 1,
      animation: `float 6s ease-in-out ${delay}s infinite`,
      opacity: 0.7,
    }}>
      <Piece owner={owner} polarity={polarity} size={36} />
      <style>{`
        @keyframes float {
          0%, 100% { transform: translateY(0) rotate(0deg); }
          50% { transform: translateY(-12px) rotate(10deg); }
        }
      `}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Difficulty selection
// ─────────────────────────────────────────────────────────────
function DifficultyScreen({ onPick, onBack }) {
  const levels = [
    { id: 'apprentice', name: 'Aprendiz', subtitle: '1 jogada à frente',
      desc: 'A IA reage ao óbvio. Bom pra entender as forças.',
      glyph: '◔', hue: 200 },
    { id: 'adept', name: 'Adepto', subtitle: '2 jogadas à frente',
      desc: 'Começa a planejar cadeias. Exige cuidado.',
      glyph: '◑', hue: 280 },
    { id: 'master', name: 'Mestre', subtitle: '3+ jogadas à frente',
      desc: 'Lê o tabuleiro inteiro. Não erra duas vezes.',
      glyph: '●', hue: 340 },
  ];
  return (
    <div className="screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg subtle"><div className="stars dim" /></div>
      <div className="col" style={{
        position: 'relative', zIndex: 2, height: '100%', padding: '64px 24px 32px',
      }}>
        <div className="row" style={{ marginBottom: 24 }}>
          <button className="btn-icon" onClick={onBack} aria-label="Voltar">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M10 3 L4 8 L10 13" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        </div>
        <div className="col" style={{ marginBottom: 28 }}>
          <span className="eyebrow">Passo 1 de 1</span>
          <h2 className="display" style={{ fontSize: 28, margin: '8px 0 4px', fontWeight: 500 }}>
            Escolha a dificuldade
          </h2>
          <p style={{ color: 'var(--ink-2)', fontSize: 14, margin: 0, lineHeight: 1.5 }}>
            Você sempre joga primeiro. A IA pode trocar de lado se ela achar melhor.
          </p>
        </div>

        <div className="col gap-12" style={{ flex: 1 }}>
          {levels.map(lvl => (
            <button key={lvl.id} onClick={() => onPick(lvl.id)}
              className="difficulty-card"
              style={{
                textAlign: 'left', border: 'none', cursor: 'pointer',
                padding: 20, borderRadius: 20,
                background: `linear-gradient(135deg, oklch(0.22 0.12 ${lvl.hue} / 0.5), oklch(0.12 0.08 ${lvl.hue} / 0.3))`,
                boxShadow: `inset 0 0 0 1px oklch(0.5 0.18 ${lvl.hue} / 0.3)`,
                display: 'flex', alignItems: 'center', gap: 16,
                color: 'var(--ink)',
              }}>
              <div style={{
                width: 56, height: 56, borderRadius: 16, flexShrink: 0,
                display: 'grid', placeItems: 'center',
                background: `radial-gradient(circle at 30% 30%, oklch(0.7 0.15 ${lvl.hue}), oklch(0.4 0.18 ${lvl.hue}))`,
                boxShadow: `inset 0 0 0 1px rgba(255,255,255,0.2), 0 0 24px oklch(0.5 0.18 ${lvl.hue} / 0.4)`,
                fontSize: 28, fontWeight: 700,
                fontFamily: 'var(--font-display)',
              }}>{lvl.glyph}</div>
              <div className="col f1" style={{ gap: 4 }}>
                <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <span className="display" style={{ fontSize: 19, fontWeight: 600 }}>{lvl.name}</span>
                  <span className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.1em' }}>
                    {lvl.subtitle.toUpperCase()}
                  </span>
                </div>
                <span style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.4 }}>{lvl.desc}</span>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// End game modal
// ─────────────────────────────────────────────────────────────
function EndGameModal({ result, turns, playerLeft, aiLeft, onNew, onMenu, onShare }) {
  const isWin = result === 'player';
  const isDraw = result === 'draw';
  const titleColor = isWin ? 'oklch(0.92 0.10 80)' : isDraw ? 'var(--ink)' : 'oklch(0.75 0.18 30)';
  const titleText = isWin ? 'Vitória' : isDraw ? 'Empate' : 'Derrota';
  const tagline = isWin ? 'O cosmos pendeu pro seu lado.'
    : isDraw ? 'Forças em equilíbrio perfeito.'
    : 'A gravidade não esquece.';

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <div className="col" style={{ alignItems: 'center', gap: 4, marginBottom: 20 }}>
          <span className="eyebrow">Fim de partida</span>
          <h2 className="display" style={{
            fontSize: 44, margin: '4px 0 2px', fontWeight: 600, color: titleColor,
            textShadow: isWin ? '0 0 40px oklch(0.85 0.15 70 / 0.6)' : 'none',
          }}>{titleText}</h2>
          <p style={{ margin: 0, fontSize: 13, color: 'var(--ink-2)', textAlign: 'center' }}>
            {tagline}
          </p>
        </div>
        <div className="row gap-12" style={{ marginBottom: 24 }}>
          <StatBox label="VOCÊ" value={playerLeft} owner="player" />
          <StatBox label="TURNOS" value={turns} />
          <StatBox label="IA" value={aiLeft} owner="ai" />
        </div>
        <div className="col gap-8">
          <button className="btn btn-primary" onClick={onNew} style={{ width: '100%', height: 52 }}>
            Nova partida
          </button>
          <button className="btn btn-ghost" onClick={onMenu} style={{ width: '100%' }}>
            Menu
          </button>
          <button onClick={onShare} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            color: 'var(--ink-3)', fontSize: 12, padding: 10,
            fontFamily: 'var(--font-mono)', letterSpacing: '0.1em',
          }}>
            COMPARTILHAR RESULTADO
          </button>
        </div>
      </div>
    </div>
  );
}

function StatBox({ label, value, owner }) {
  const color = owner === 'player' ? 'var(--player)' : owner === 'ai' ? 'var(--ai)' : 'var(--ink)';
  return (
    <div className="col f1" style={{
      padding: 14, borderRadius: 14,
      background: 'rgba(255,255,255,0.04)',
      boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.06)',
      alignItems: 'center', gap: 4,
    }}>
      <span className="mono" style={{ fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.12em' }}>
        {label}
      </span>
      <span className="display" style={{ fontSize: 26, fontWeight: 600, color }}>{value}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Pause modal
// ─────────────────────────────────────────────────────────────
function PauseModal({ onResume, onRestart, onQuit }) {
  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: 300 }}>
        <div className="col" style={{ alignItems: 'center', gap: 4, marginBottom: 20 }}>
          <span className="eyebrow">Em pausa</span>
          <h2 className="display" style={{ fontSize: 28, margin: '4px 0 0', fontWeight: 600 }}>
            Pausado
          </h2>
        </div>
        <div className="col gap-8">
          <button className="btn btn-primary" onClick={onResume} style={{ width: '100%' }}>
            Continuar
          </button>
          <button className="btn btn-ghost" onClick={onRestart} style={{ width: '100%' }}>
            Reiniciar partida
          </button>
          <button className="btn btn-ghost" onClick={onQuit} style={{
            width: '100%', color: 'oklch(0.75 0.16 30)',
          }}>
            Abandonar
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tutorial step
// ─────────────────────────────────────────────────────────────
function TutorialScreen({ step = 0, onNext, onSkip, onBack }) {
  const steps = [
    {
      eyebrow: '01 · Colocação',
      title: 'Coloque uma peça',
      body: 'Em seu turno, escolha uma polaridade — ⊕ ou ⊖ — e coloque a peça em qualquer casa vazia.',
      demo: 'place',
    },
    {
      eyebrow: '02 · Atração',
      title: 'Polos opostos se atraem',
      body: 'Cada peça vizinha de polaridade oposta é puxada uma casa em direção ao epicentro.',
      demo: 'attract',
    },
    {
      eyebrow: '03 · Repulsão',
      title: 'Polos iguais se repelem',
      body: 'Vizinhas iguais são empurradas. Se houver outra peça atrás, a cadeia continua.',
      demo: 'repel',
    },
    {
      eyebrow: '04 · Vazio',
      title: 'Quem cai, some',
      body: 'Peças empurradas pra fora do tabuleiro são destruídas. Sem retorno.',
      demo: 'destroy',
    },
    {
      eyebrow: '05 · Vitória',
      title: 'Limpe o tabuleiro',
      body: 'Vence quem tiver mais peças após 20 ações — ou eliminar o oponente antes.',
      demo: 'win',
    },
  ];
  const s = steps[step];
  const total = steps.length;

  return (
    <div className="screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg subtle"><div className="stars dim" /></div>
      <div className="col" style={{
        position: 'relative', zIndex: 2, height: '100%', padding: '64px 24px 32px',
      }}>
        <div className="row" style={{ justifyContent: 'space-between', marginBottom: 16 }}>
          <button className="btn-icon" onClick={onBack} aria-label="Voltar">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M10 3 L4 8 L10 13" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
          <button onClick={onSkip} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            color: 'var(--ink-3)', fontSize: 12, fontFamily: 'var(--font-mono)',
            letterSpacing: '0.1em',
          }}>
            PULAR
          </button>
        </div>
        <div className="row gap-4" style={{ marginBottom: 24 }}>
          {steps.map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i <= step ? 'var(--player)' : 'rgba(255,255,255,0.1)',
              transition: 'background 0.3s ease',
            }} />
          ))}
        </div>

        <TutorialDemo kind={s.demo} />

        <div className="col" style={{ flex: 1, justifyContent: 'flex-end', gap: 12 }}>
          <div className="col" style={{ gap: 6 }}>
            <span className="eyebrow">{s.eyebrow}</span>
            <h2 className="display" style={{ fontSize: 26, margin: 0, fontWeight: 500 }}>
              {s.title}
            </h2>
            <p style={{ color: 'var(--ink-2)', fontSize: 15, lineHeight: 1.5, margin: '4px 0 0' }}>
              {s.body}
            </p>
          </div>
          <button className="btn btn-primary" onClick={onNext} style={{ width: '100%', marginTop: 8 }}>
            {step + 1 < total ? 'Próximo' : 'Jogar minha primeira partida'}
          </button>
        </div>
      </div>
    </div>
  );
}

function TutorialDemo({ kind }) {
  // Mini illustrative boards based on kind
  const layouts = {
    place: [
      [null, null, null, null, null],
      [null, null, {o:'player', p:'plus', selected:true}, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
    attract: [
      [null, null, null, null, null],
      [null, {o:'ai', p:'minus', arrow:135}, null, {o:'ai', p:'minus', arrow:225}, null],
      [null, null, {o:'player', p:'plus', epi:true}, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
    repel: [
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, {o:'player', p:'plus', arrow:270}, {o:'player', p:'plus', epi:true}, {o:'ai', p:'plus', arrow:90}, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
    destroy: [
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, {o:'player', p:'plus', epi:true}, {o:'ai', p:'plus', arrow:90, fading:true}, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
    win: [
      [{o:'player', p:'plus'}, null, {o:'player', p:'minus'}, null, null],
      [null, {o:'player', p:'plus'}, null, null, null],
      [{o:'player', p:'minus'}, null, {o:'player', p:'plus'}, null, {o:'ai', p:'minus'}],
      [null, null, null, null, null],
      [null, {o:'player', p:'plus'}, null, null, null],
    ],
  };
  const grid = layouts[kind] || layouts.place;

  return (
    <div style={{
      width: '100%', maxWidth: 280, alignSelf: 'center', aspectRatio: 1,
      padding: 6,
    }}>
      <div className="board" style={{ width: '100%', aspectRatio: 1 }}>
        {grid.flatMap((row, r) => row.map((cell, c) => (
          <div key={`${r}-${c}`} className="cell" style={{
            opacity: cell?.fading ? 0.3 : 1,
          }}>
            {cell && (
              <Piece owner={cell.o} polarity={cell.p}
                state={cell.epi ? 'epicenter' : cell.selected ? 'selected' : ''} size="86%" />
            )}
            {cell?.arrow !== undefined && (
              <div className="cell-arrow">
                <ArrowIcon angle={cell.arrow} kind={kind === 'attract' ? 'attract' : 'repel'} size={14} />
              </div>
            )}
          </div>
        )))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────────────────────
function SettingsScreen({ onBack, settings, onChange }) {
  const groups = [
    {
      header: 'Jogabilidade',
      items: [
        { key: 'reducedMotion', label: 'Animação reduzida', kind: 'toggle' },
        { key: 'colorblind', label: 'Modo daltônico', kind: 'toggle' },
        { key: 'hints', label: 'Mostrar prévia de reação', kind: 'toggle' },
      ],
    },
    {
      header: 'Som e vibração',
      items: [
        { key: 'sound', label: 'Som', kind: 'toggle' },
        { key: 'music', label: 'Música ambiente', kind: 'toggle' },
        { key: 'haptics', label: 'Vibração', kind: 'toggle' },
      ],
    },
    {
      header: 'Idioma',
      items: [
        { key: 'lang', label: 'Idioma do jogo', kind: 'select', options: ['PT-BR', 'EN', 'ES'] },
      ],
    },
    {
      header: 'Sobre',
      items: [
        { key: 'privacy', label: 'Política de privacidade', kind: 'link' },
        { key: 'terms', label: 'Termos de uso', kind: 'link' },
        { key: 'credits', label: 'Créditos', kind: 'link' },
      ],
    },
  ];

  return (
    <div className="screen" style={{ position: 'relative', height: '100%', overflow: 'hidden' }}>
      <div className="cosmos-bg subtle"><div className="stars dim" /></div>
      <div className="col" style={{
        position: 'relative', zIndex: 2, height: '100%', padding: '64px 20px 32px',
        overflow: 'auto',
      }}>
        <div className="row" style={{ marginBottom: 16 }}>
          <button className="btn-icon" onClick={onBack} aria-label="Voltar">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M10 3 L4 8 L10 13" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        </div>
        <h2 className="display" style={{ fontSize: 28, margin: '0 4px 24px', fontWeight: 500 }}>
          Ajustes
        </h2>
        {groups.map(g => (
          <div key={g.header} className="col" style={{ marginBottom: 28 }}>
            <span className="eyebrow" style={{ marginBottom: 10, paddingLeft: 4 }}>{g.header}</span>
            <div className="col" style={{
              borderRadius: 18, overflow: 'hidden',
              background: 'rgba(255,255,255,0.04)',
              boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.06)',
            }}>
              {g.items.map((it, i) => (
                <SettingsRow key={it.key} item={it} value={settings[it.key]} onChange={onChange}
                  divider={i < g.items.length - 1} />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SettingsRow({ item, value, onChange, divider }) {
  return (
    <div style={{
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
      borderBottom: divider ? '1px solid rgba(255,255,255,0.05)' : 'none',
    }}>
      <span className="f1" style={{ fontSize: 14, color: 'var(--ink)' }}>{item.label}</span>
      {item.kind === 'toggle' && (
        <button
          onClick={() => onChange(item.key, !value)}
          style={{
            width: 48, height: 28, borderRadius: 14, border: 'none',
            background: value
              ? 'linear-gradient(135deg, oklch(0.7 0.18 290), oklch(0.55 0.18 290))'
              : 'rgba(255,255,255,0.1)',
            cursor: 'pointer', padding: 2,
            display: 'flex', alignItems: 'center', justifyContent: value ? 'flex-end' : 'flex-start',
            transition: 'all 0.2s ease',
            boxShadow: value ? '0 0 16px oklch(0.7 0.18 290 / 0.4)' : 'none',
          }}
        >
          <div style={{
            width: 24, height: 24, borderRadius: '50%',
            background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.4)',
          }} />
        </button>
      )}
      {item.kind === 'select' && (
        <span className="mono" style={{ fontSize: 12, color: 'var(--ink-2)' }}>{value} ›</span>
      )}
      {item.kind === 'link' && (
        <span style={{ color: 'var(--ink-3)' }}>›</span>
      )}
    </div>
  );
}

Object.assign(window, {
  SplashScreen, MenuScreen, DifficultyScreen, EndGameModal, PauseModal,
  TutorialScreen, TutorialDemo, SettingsScreen, SplashLogo, FloatingPiece,
});
