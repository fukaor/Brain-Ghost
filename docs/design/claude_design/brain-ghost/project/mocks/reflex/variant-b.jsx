// variant-b.jsx — ゴースト7番勝負 / 正面衝突 v2
// 単一レーン. YOU=左→右, GHOST=右→左. 中央ゲートで激突. 中央点に近い側が勝利.
// レーン形状は5種ローテ: straight / sCurve / wave / zigzag / arc

const CFG_B = [
  { move: 2200, pre: 1500, lane: 'straight' },
  { move: 2000, pre: 1200, lane: 'sCurve'   },
  { move: 1500, pre: 1000, lane: 'wave'     },
  { move: 1200, pre:  900, lane: 'zigzag'   },
  { move: 1000, pre:  800, lane: 'arc'      },
  { move:  900, pre:  700, lane: 'straight' },
  { move:  900, pre: 1000, lane: 'wave'     },
];
// GHOST が中央ゲートを通過する相対時刻 (move 半分 + ghost 反応)
// → 中央到達タイミングのオフセット (ms). 正なら遅く到達, 負なら早い.
const GHOST_B = [150, 152, 148, 155, 160, 145, 140];

// ── Tokens ───────────────────────────────────
const T = {
  bgVoid:    '#000000',
  bgDeep:    '#060912',
  bgPanel:   '#0B1220',
  ink100:    '#F4F7FF',
  ink80:     '#C7D2E8',
  ink60:     '#8896B0',
  ink40:     '#4A5570',
  ink20:     '#232B3F',
  cyan300:   '#B8E0FF',
  cyan400:   '#6FB4FF',
  cyan500:   '#3D8BE8',
  cyanGlow:  'rgba(111,180,255,0.55)',
  gold300:   '#FFE9A8',
  gold400:   '#F5C76A',
  goldGlow:  'rgba(245,199,106,0.6)',
  red400:    '#E55A5A',
  red500:    '#C73B3B',
  redGlow:   'rgba(231,90,90,0.5)',
  serif:     '"Noto Serif JP", "Hiragino Mincho ProN", serif',
  sans:      '"Noto Sans JP", system-ui, sans-serif',
  tnum:      '"tnum" 1, "lnum" 1',
};

// ── Lane path: t∈[0,1] (left→right). 戻り値 {x,y}, x∈[0,width], y は中央yからのオフセット
//   YOU は path(t), GHOST は path(1-t). 中央 t=0.5 = 同地点 (中央ゲート).
function lanePath(kind, t, width, midY, amp) {
  const x = 24 + (width - 48) * t;
  const u = t - 0.5; // -0.5 ... 0.5
  let dy = 0;
  switch (kind) {
    case 'straight': dy = 0; break;
    case 'sCurve':   dy = Math.sin(u * Math.PI) * amp * 0.9; break;
    case 'wave':     dy = Math.sin(t * Math.PI * 2) * amp; break;
    case 'zigzag': {
      // 4 segments
      const seg = t * 4;
      const s = Math.floor(seg);
      const f = seg - s;
      const peaks = [0, 1, -1, 1, 0];
      dy = (peaks[s] + (peaks[s+1] - peaks[s]) * f) * amp * 0.85;
      break;
    }
    case 'arc':      dy = -Math.sin(t * Math.PI) * amp * 1.1; break;
    default: dy = 0;
  }
  return { x, y: midY + dy };
}

function ReflexVariantB({ width = 892, height = 412 }) {
  const [, force] = React.useReducer(x => x + 1, 0);
  const state = React.useRef({
    phase: 'ready',
    round: 0,
    wins: 0,
    gwins: 0,
    countdown: 3,
    moveStartMs: 0,
    gateCenterMs: 0, // YOUがt=0.5に到達する時刻 (=move/2)
    ghostGateMs: 0,  // GHOSTがt=0.5に到達する時刻
    ghostFired: false,
    ghostTapT: null, // GHOSTがタップした (=t=0.5に到達した) ときのt
    youTapT: null,
    lastTap: null,
    history: [],
    pulse: 0,
  }).current;

  const rafRef = React.useRef(null);
  const timersRef = React.useRef([]);
  const pushT = (fn, ms) => { const id = setTimeout(fn, ms); timersRef.current.push(id); return id; };
  const clearTimers = () => { timersRef.current.forEach(clearTimeout); timersRef.current = []; };

  React.useEffect(() => {
    const loop = () => {
      const now = performance.now();
      state.pulse = (now % 500) / 500;

      if (state.phase === 'moving') {
        const cfg = CFG_B[state.round];
        const t = Math.min(1, (now - state.moveStartMs) / cfg.move);
        // GHOST は YOU と同時発進・同速度. 記録上の超過/不足ポイントで停止.
        //   ghost_offset(ms) > 0 (遅い) → t=0.5+offset/move の位置で停める. ただしそれ以前は同期して進む.
        //   実装: ghost_offset > 0 なら ghostGateMs > gateCenterMs. ghost は gateCenterMs までは t と同じ,
        //          gateCenterMs 以降も t と同じ進行で ghostGateMs に達したらそこでストップ. その位置を ghostStopT.
        //   ghost_offset < 0 (早い) → ghostGateMs < gateCenterMs なので「gate 手前で停まる」ように見える.
        if (!state.ghostFired && now >= state.ghostGateMs) {
          state.ghostFired = true;
          state.ghostTapT = (state.ghostGateMs - state.moveStartMs) / cfg.move;
        }
        if (t >= 1 && !state.lastTap) {
          resolveMiss();
        }
      }
      force();
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(rafRef.current);
    // eslint-disable-next-line
  }, []);

  const startRound = (r) => {
    clearTimers();
    state.round = r;
    state.lastTap = null;
    state.ghostFired = false;
    state.ghostTapT = null;
    state.youTapT = null;
    state.phase = 'announce';
    const cfg = CFG_B[r];
    pushT(() => {
      state.phase = 'moving';
      state.moveStartMs = performance.now();
      state.gateCenterMs = state.moveStartMs + cfg.move / 2;
      state.ghostGateMs = state.gateCenterMs + GHOST_B[r];
      force();
    }, cfg.pre);
    force();
  };

  const resolveTap = () => {
    const now = performance.now();
    let deltaMs, isFly = false;

    if (state.phase === 'announce') {
      isFly = true; deltaMs = 999;
    } else if (state.phase === 'moving') {
      const signed = now - state.gateCenterMs;
      if (signed < -120) { isFly = true; deltaMs = 999; }
      else { deltaMs = Math.round(Math.abs(signed)); }
      const cfg = CFG_B[state.round];
      state.youTapT = (now - state.moveStartMs) / cfg.move;
    } else { return; }

    clearTimers();
    const ghost = GHOST_B[state.round];
    const grade = isFly ? 'FLYING'
      : deltaMs >= 1000 ? 'MISS'
      : deltaMs <= 50 ? 'PERFECT'
      : deltaMs <= 150 ? 'GREAT'
      : deltaMs <= 300 ? 'GOOD'
      : 'LATE';
    const win = !isFly && deltaMs < ghost;
    if (win) state.wins++; else state.gwins++;
    state.lastTap = { delta: deltaMs, ghost, grade, win, lane: CFG_B[state.round].lane };
    state.history[state.round] = state.lastTap;
    state.phase = 'result';
    force();
  };

  const resolveMiss = () => {
    clearTimers();
    const ghost = GHOST_B[state.round];
    state.lastTap = { delta: 1000, ghost, grade: 'MISS', win: false, lane: CFG_B[state.round].lane };
    state.history[state.round] = state.lastTap;
    state.gwins++;
    state.phase = 'result';
    force();
  };

  const startCountdown = () => {
    state.phase = 'countdown';
    state.countdown = 3;
    force();
    const tick = (n) => {
      if (n === 0) { startRound(0); return; }
      state.countdown = n;
      force();
      pushT(() => tick(n - 1), 700);
    };
    pushT(() => tick(3), 100);
  };

  const onClick = () => {
    if (state.phase === 'ready') {
      state.wins = 0; state.gwins = 0; state.history = [];
      startCountdown(); return;
    }
    if (state.phase === 'countdown') return;
    if (state.phase === 'announce' || state.phase === 'moving') { resolveTap(); return; }
    if (state.phase === 'result') {
      if (state.round >= 6) { state.phase = 'done'; force(); return; }
      startRound(state.round + 1);
      return;
    }
    if (state.phase === 'done') { state.phase = 'ready'; force(); return; }
  };

  // ── layout ───────────────────────────────────
  const cfg = CFG_B[state.round];
  const HUD_H = 36;
  const MID_Y = HUD_H + 22 + 130;        // レーンの中心y
  const AMP = 70;                         // 上下振れ幅
  const HIST_Y = MID_Y + 110;
  const lineX = width / 2;

  // 進行 t (announce 中は 0 に固定)
  const now = performance.now();
  const tNow = state.phase === 'moving'
    ? Math.min(1, (now - state.moveStartMs) / cfg.move)
    : 0;
  const youPos = lanePath(cfg.lane, tNow, width, MID_Y, AMP);
  // GHOST は逆向き. かつ反応時刻 GHOST_B[r] によって YOU より遅れて中央到達するよう, 進行を offset
  // GHOST は move + ghost_offset の時間で逆走する. ただしビジュアルは t=0.5 で同タイミング+ghost_offset で中央到達.
  // 単純化: ghost も同じ move 時間で逆走. ghost が中央到達するのは moveStart + move/2 + ghost_offset
  // GHOST は YOU と同時・同速. fired 前は t と同じ進行を逆走し, fired 後は ghostTapT で停止.
  const tGhostEffective = state.ghostFired ? state.ghostTapT : tNow;
  const ghostPos = lanePath(cfg.lane, 1 - tGhostEffective, width, MID_Y, AMP);

  const bg = T.bgVoid;

  return (
    <div onClick={onClick} style={{
      width, height, position: 'relative', overflow: 'hidden',
      background: bg,
      fontFamily: T.sans, color: T.ink100,
      userSelect: 'none', cursor: 'pointer',
    }}>
      <StarLayer />

      {/* ── HUD ── */}
      {state.phase !== 'done' && state.phase !== 'ready' && (
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: HUD_H,
          padding: '0 18px', display: 'flex', alignItems: 'center',
          justifyContent: 'space-between', zIndex: 8,
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12,
            fontFamily: T.serif, fontSize: 16, color: T.ink80,
          }}>
            第<span style={{ color: T.cyan300, fontSize: 18, margin: '0 2px' }}>{state.round + 1}</span>戦／7
            <Dots history={state.history} round={state.round} cur={state.phase !== 'result'} />
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8, fontSize: 11,
            fontFeatureSettings: T.tnum, letterSpacing: '0.15em',
          }}>
            <span style={{ fontSize: 9, color: T.ink60, letterSpacing: '0.25em' }}>YOU</span>
            <span style={{ fontSize: 18, color: T.cyan300, textShadow: `0 0 8px ${T.cyanGlow}` }}>{state.wins}</span>
            <span style={{ color: T.ink40 }}>—</span>
            <span style={{ fontSize: 18, color: T.ink80 }}>{state.gwins}</span>
            <span style={{ fontSize: 9, color: T.ink60, letterSpacing: '0.25em' }}>GHOST</span>
          </div>
        </div>
      )}

      {/* ── PLAY ── */}
      {(state.phase === 'announce' || state.phase === 'moving') && (
        <>
          <LaneSvg
            kind={cfg.lane} width={width} midY={MID_Y} amp={AMP}
            lineX={lineX} pulse={state.pulse}
            laneLabel={LANE_LABELS[cfg.lane]}
          />
          {/* Center gate (vertical) */}
          <CenterGate x={lineX} midY={MID_Y} amp={AMP} pulse={state.pulse} />

          {/* YOU orb */}
          {state.phase === 'moving' && (
            <Orb x={youPos.x} y={youPos.y} kind="you" />
          )}
          {/* GHOST orb */}
          {state.phase === 'moving' && (
            <Orb x={ghostPos.x} y={ghostPos.y} kind="ghost" fired={state.ghostFired} />
          )}

          {/* announce START banner */}
          {state.phase === 'announce' && (
            <div key={`an-${state.round}`} style={{
              position: 'absolute', top: MID_Y - 28, left: 0, right: 0,
              textAlign: 'center', zIndex: 6, pointerEvents: 'none',
              fontFamily: T.serif, fontSize: 56, letterSpacing: '0.08em',
              color: T.cyan300, textShadow: `0 0 24px ${T.cyanGlow}, 0 0 60px rgba(111,180,255,0.4)`,
              animation: 'rb-slam 320ms cubic-bezier(.2,.8,.2,1) both',
            }}>
              START
            </div>
          )}

          {/* Lane name + ghost reaction */}
          <div style={{
            position: 'absolute', top: HUD_H + 6, left: 0, right: 0,
            display: 'flex', justifyContent: 'space-between', padding: '0 24px',
            fontSize: 10, letterSpacing: '0.3em', color: T.ink60, zIndex: 4,
          }}>
            <span style={{ color: T.cyan400, textShadow: `0 0 6px ${T.cyanGlow}` }}>
              LANE · {LANE_LABELS[cfg.lane]}
            </span>
            {state.phase === 'moving' && (
              <span style={{ fontFeatureSettings: T.tnum }}>
                GHOST 反応 <span style={{ color: T.ink80 }}>{GHOST_B[state.round]}</span> ms
              </span>
            )}
          </div>
        </>
      )}

      {/* ── HISTORY ── */}
      {(state.phase === 'announce' || state.phase === 'moving') && (
        <div style={{
          position: 'absolute', left: 18, right: 18, top: HIST_Y, height: height - HIST_Y - 8,
          display: 'flex', gap: 4, zIndex: 4, pointerEvents: 'none',
        }}>
          {Array.from({ length: 7 }).map((_, i) => (
            <HistoryTile key={i} idx={i} h={state.history[i]} cur={i === state.round} />
          ))}
        </div>
      )}

      {/* ── RESULT ── */}
      {state.phase === 'result' && state.lastTap && (
        <ResultCinema
          width={width} height={height} hudH={HUD_H}
          lastTap={state.lastTap}
          midY={MID_Y} amp={AMP} lane={cfg.lane}
          youTapT={state.youTapT}
          ghostTapT={state.ghostTapT}
        />
      )}

      {/* ── READY ── */}
      {state.phase === 'ready' && <Ready />}

      {/* ── COUNTDOWN ── */}
      {state.phase === 'countdown' && (
        <div key={`cd-${state.countdown}`} style={{
          position: 'absolute', inset: 0, display: 'flex',
          alignItems: 'center', justifyContent: 'center', zIndex: 5,
          fontFamily: T.serif, fontSize: 220, lineHeight: 1, letterSpacing: '-0.02em',
          color: T.cyan300,
          textShadow: `0 0 32px ${T.cyanGlow}, 0 0 80px rgba(111,180,255,0.4)`,
          animation: 'rb-slam 500ms cubic-bezier(.2,.8,.2,1) both',
        }}>
          {state.countdown}
        </div>
      )}

      {/* ── DONE ── */}
      {state.phase === 'done' && <Done wins={state.wins} gwins={state.gwins} />}

      <style>{`
        @keyframes rb-fade { from{opacity:0} to{opacity:1} }
        @keyframes rb-slam { 0%{transform:scale(0.6);opacity:0} 60%{transform:scale(1.12);opacity:1} 100%{transform:scale(1);opacity:1} }
        @keyframes rb-bob  { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-6px)} }
        @keyframes rb-glow { 0%,100%{filter:drop-shadow(0 0 12px ${T.cyanGlow})} 50%{filter:drop-shadow(0 0 22px ${T.cyanGlow})} }
        @keyframes rb-laser { 0%{transform:scaleX(0);opacity:0} 25%{opacity:1} 100%{transform:scaleX(1);opacity:1} }
        @keyframes rb-laser-v { 0%{transform:scaleY(0);opacity:0} 25%{opacity:1} 100%{transform:scaleY(1);opacity:1} }
        @keyframes rb-ring { 0%{transform:scale(0.1);opacity:0} 25%{opacity:var(--rb-ring-op,0.9)} 100%{transform:scale(1);opacity:0} }
        @keyframes rb-spark { 0%{transform:scale(0);opacity:0} 40%{transform:scale(1.4);opacity:1} 100%{transform:scale(1);opacity:0.8} }
        @keyframes rb-headline { 0%{transform:scale(1.4);letter-spacing:0.4em;opacity:0} 50%{opacity:1} 100%{transform:scale(1);letter-spacing:0.08em;opacity:1} }
        @keyframes rb-core { 0%{transform:scale(0.2);opacity:0} 12%{transform:scale(1.6);opacity:1} 30%{transform:scale(1);opacity:1} 100%{transform:scale(0.7);opacity:0.3} }
        @keyframes rb-gatepulse { 0%,100%{opacity:0.55} 50%{opacity:0.95} }
      `}</style>
    </div>
  );
}

const LANE_LABELS = {
  straight: '直線',
  sCurve:   'S字',
  wave:     '波',
  zigzag:   'ジグザグ',
  arc:      '弧',
};

// ── Lane SVG (rendered path) ─────────────────
function LaneSvg({ kind, width, midY, amp, lineX, pulse }) {
  // Build path d from sampled lanePath
  const N = 80;
  let d = '';
  for (let i = 0; i <= N; i++) {
    const t = i / N;
    const p = lanePath(kind, t, width, midY, amp);
    d += (i === 0 ? 'M' : 'L') + p.x.toFixed(1) + ',' + p.y.toFixed(1) + ' ';
  }
  return (
    <svg width={width} height={midY + amp + 60} style={{
      position: 'absolute', top: 0, left: 0, zIndex: 1, pointerEvents: 'none',
    }}>
      {/* outer wide soft path */}
      <path d={d} stroke={T.cyan500} strokeOpacity="0.15" strokeWidth="22" fill="none" strokeLinecap="round" />
      <path d={d} stroke={T.cyan400} strokeOpacity="0.25" strokeWidth="10" fill="none" strokeLinecap="round" />
      {/* inner core */}
      <path d={d} stroke={T.cyan300} strokeOpacity="0.6" strokeWidth="2" fill="none" strokeLinecap="round" strokeDasharray="2 6" />
      <path d={d} stroke={T.ink100} strokeOpacity="0.85" strokeWidth="1" fill="none" strokeLinecap="round" />
    </svg>
  );
}

// ── Center gate — 中央点を縦に通る光のゲート ──
function CenterGate({ x, midY, amp, pulse }) {
  // ゲートの上下幅: レーン上下幅 + 余白
  const top = midY - amp - 30;
  const bot = midY + amp + 30;
  return (
    <>
      {/* central beam */}
      <div style={{
        position: 'absolute', top, left: x - 1, width: 2, height: bot - top,
        background: `linear-gradient(180deg, transparent, ${T.gold300} 12%, ${T.gold300} 88%, transparent)`,
        boxShadow: `0 0 ${10 + pulse * 12}px ${T.goldGlow}, 0 0 ${22 + pulse * 14}px rgba(245,199,106,0.4)`,
        zIndex: 3, pointerEvents: 'none',
      }}/>
      {/* halo at center */}
      <div style={{
        position: 'absolute', top: midY - 22, left: x - 26, width: 52, height: 44,
        borderRadius: '50%',
        background: `radial-gradient(ellipse, ${T.goldGlow} 0%, transparent 70%)`,
        zIndex: 2, pointerEvents: 'none',
        opacity: 0.5 + pulse * 0.3,
      }}/>
      {/* GATE label */}
      <div style={{
        position: 'absolute', top: top - 16, left: x - 30, width: 60,
        textAlign: 'center', fontSize: 9, letterSpacing: '0.4em',
        color: T.gold300, textShadow: `0 0 6px ${T.goldGlow}`, zIndex: 4,
        fontFamily: T.serif,
      }}>GATE</div>
    </>
  );
}

// ── Orb (YOU=cyan/white left-mover, GHOST=gray right→left) ──
function Orb({ x, y, kind, fired }) {
  const isGhost = kind === 'ghost';
  const core = isGhost ? T.ink80 : T.ink100;
  const aura = isGhost ? 'rgba(199,213,235,0.6)' : T.cyan300;
  const trail = isGhost ? 'rgba(199,213,235,0.5)' : T.cyanGlow;
  const size = isGhost ? 28 : 32;
  // YOUは左→右なのでtrailは左側. GHOSTは右→左なのでtrailは右側
  const trailLeft = isGhost ? size : -64;
  const trailGrad = isGhost
    ? `linear-gradient(90deg, ${trail}, transparent)`
    : `linear-gradient(90deg, transparent, ${trail})`;
  return (
    <div style={{
      position: 'absolute', top: y - size / 2, left: x - size / 2, width: size, height: size,
      zIndex: 5, pointerEvents: 'none',
      opacity: isGhost && fired ? 0.3 : 1,
      transition: 'opacity 200ms',
    }}>
      <div style={{
        position: 'absolute', top: size / 2 - 4, left: trailLeft, width: 64, height: 8,
        background: trailGrad,
        borderRadius: 4, filter: 'blur(2px)', opacity: 0.85,
      }} />
      <div style={{
        position: 'absolute', inset: 2, borderRadius: '50%',
        background: `radial-gradient(circle, ${core} 0%, ${aura} 50%, transparent 100%)`,
        boxShadow: `0 0 16px ${trail}, 0 0 6px ${T.ink100}`,
      }} />
    </div>
  );
}

// ── HUD dots ──────────────────────────────────
function Dots({ history, round, cur }) {
  return (
    <span style={{ display: 'inline-flex', gap: 5, marginLeft: 6 }}>
      {Array.from({ length: 7 }).map((_, i) => {
        const h = history[i];
        const isCur = i === round && cur;
        if (h?.win) return <span key={i} style={{ width: 10, height: 10, borderRadius: '50%', background: T.cyan400, boxShadow: `0 0 6px ${T.cyanGlow}` }}/>;
        if (h && !h.win) return <span key={i} style={{ width: 10, height: 10, color: T.red400, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontFamily: T.serif, fontSize: 13, lineHeight: 1, textShadow: `0 0 6px ${T.redGlow}` }}>×</span>;
        return <span key={i} style={{ width: 10, height: 10, borderRadius: '50%', border: `1.5px solid ${isCur ? T.ink100 : T.ink40}`, boxShadow: isCur ? '0 0 0 3px rgba(255,255,255,0.08)' : 'none' }}/>;
      })}
    </span>
  );
}

// ── Star layer ───────────────────────────────
function StarLayer() {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none',
      backgroundImage:
        `radial-gradient(1px 1px at 14% 22%, rgba(255,255,255,0.4) 50%, transparent 100%),
         radial-gradient(1px 1px at 78% 86%, rgba(255,255,255,0.3) 50%, transparent 100%),
         radial-gradient(1.5px 1.5px at 36% 60%, rgba(184,224,255,0.5) 50%, transparent 100%),
         radial-gradient(1px 1px at 88% 14%, rgba(255,255,255,0.5) 50%, transparent 100%),
         radial-gradient(1px 1px at 8% 78%, rgba(255,255,255,0.3) 50%, transparent 100%),
         radial-gradient(1.5px 1.5px at 58% 30%, rgba(111,180,255,0.4) 50%, transparent 100%),
         radial-gradient(1px 1px at 24% 50%, rgba(255,255,255,0.35) 50%, transparent 100%),
         radial-gradient(1px 1px at 92% 52%, rgba(184,224,255,0.4) 50%, transparent 100%)`,
      backgroundSize: '300px 300px, 350px 350px, 280px 280px, 320px 320px, 370px 370px, 290px 290px, 240px 240px, 310px 310px',
      opacity: 0.7,
    }} />
  );
}

// ── History tile ─────────────────────────────
function HistoryTile({ idx, h, cur }) {
  const isWin = h?.win;
  const bg = h
    ? (isWin ? 'rgba(111,180,255,0.16)' : 'rgba(199,59,59,0.12)')
    : cur ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.025)';
  const border = cur && !h
    ? `1px solid ${T.ink60}`
    : h ? `1px solid ${isWin ? 'rgba(111,180,255,0.4)' : 'rgba(199,59,59,0.3)'}`
    : `1px solid ${T.ink20}`;
  return (
    <div style={{
      flex: 1, borderRadius: 6, background: bg, border,
      padding: '5px 8px', display: 'flex', flexDirection: 'column',
      justifyContent: 'space-between', minHeight: 0,
      boxShadow: cur && !h ? '0 0 8px rgba(255,255,255,0.08)' : 'none',
    }}>
      <div style={{
        fontSize: 9, letterSpacing: '0.2em', fontFamily: T.serif,
        color: cur && !h ? T.cyan300 : T.ink60,
      }}>R{idx + 1}</div>
      {h ? (
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 3, fontFeatureSettings: T.tnum }}>
          <span style={{
            fontSize: 16, color: isWin ? T.cyan300 : T.ink80,
            textShadow: isWin ? `0 0 6px ${T.cyanGlow}` : 'none',
          }}>{['FLYING','MISS'].includes(h.grade) ? 'ー' : h.delta}</span>
          <span style={{ fontSize: 9, opacity: 0.5 }}>ms</span>
          <span style={{
            marginLeft: 'auto', fontFamily: T.serif, fontSize: 12,
            color: isWin ? T.cyan300 : T.red400,
          }}>{isWin ? '○' : '×'}</span>
        </div>
      ) : (
        <div style={{ fontSize: 9, color: T.ink40, letterSpacing: '0.1em' }}>
          {cur ? '進行中' : '—'}
        </div>
      )}
    </div>
  );
}

// ── RING 定義 ──
const RING_DEFS = [
  { r: 24,  w: 1.5, op: 0.95, delay: 0,   hot: true  },
  { r: 38,  w: 1.2, op: 0.85, delay: 40,  hot: true  },
  { r: 56,  w: 1,   op: 0.70, delay: 90,  hot: false },
  { r: 78,  w: 1,   op: 0.55, delay: 150, hot: false },
  { r: 102, w: 1,   op: 0.40, delay: 220, hot: false },
  { r: 130, w: 1,   op: 0.28, delay: 300, hot: false },
  { r: 162, w: 1,   op: 0.18, delay: 390, hot: false },
];

// ── RESULT CINEMA ──
//   正面衝突なので: 中央(GATE)で激突 = ヒット点は中央. 両側に光線.
function ResultCinema({ width, height, hudH, lastTap, midY, amp, lane, youTapT, ghostTapT }) {
  const { delta, ghost, grade, win } = lastTap;
  const isPerfect = grade === 'PERFECT';
  const isMiss = ['FLYING', 'MISS'].includes(grade);
  const headColor = isPerfect ? T.gold400 : win ? T.cyan300 : T.ink80;
  const headGlow = isPerfect ? T.goldGlow : win ? T.cyanGlow : T.redGlow;
  const winLabel = win ? 'WIN' : 'LOSE';
  const winColor = win ? (isPerfect ? T.gold300 : T.cyan300) : T.red400;

  // GATE = 中央 (高さはレーンの t=0.5 位置)
  const gatePos = lanePath(lane, 0.5, width, midY, amp);
  const gateX = gatePos.x;
  // YOU はタップ位置. miss なら t=1 付近.
  const tapT = isMiss ? 1 : (youTapT != null ? youTapT : 0.5);
  const youPos = lanePath(lane, tapT, width, midY, amp);
  const hitX = youPos.x;
  const hitY = youPos.y;

  // GHOST 位置 (反側)
  // GHOST が発火していなくても (=YOU がより速くタップした場合), 予定停止位置を表示
  const cfgB = CFG_B.find(c => c.lane === lane) || CFG_B[0];
  const moveMs = cfgB.move;
  const ghostT = ghostTapT != null ? ghostTapT : (0.5 + lastTap.ghost / moveMs);
  const ghostPos = lanePath(lane, 1 - ghostT, width, midY, amp);

  // YOU側 (左から来た) の光 = 金/シアン
  const youHot  = isPerfect ? T.gold300 : T.cyan300;
  const youMid  = isPerfect ? T.gold400 : T.cyan400;
  const isLose = !win;
  const youHotFinal  = isLose ? T.red400 : youHot;
  const youMidFinal  = isLose ? T.red500 : youMid;
  // GHOST側(右から来た) はシアン弱く
  const ghostHot = T.cyan300;
  const ghostMid = T.cyan400;

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 7, pointerEvents: 'none',
      animation: 'rb-fade 280ms ease-out both',
    }}>
      {/* headline */}
      <div style={{
        position: 'absolute', top: hudH + 4, left: 0, right: 0,
        textAlign: 'center', fontFamily: T.serif, zIndex: 10,
      }}>
        <div style={{
          fontSize: 52, lineHeight: 1, letterSpacing: '0.08em',
          color: headColor, fontWeight: 500,
          textShadow: `0 0 22px ${headGlow}, 0 0 60px ${headGlow}, 0 4px 24px rgba(0,0,0,0.8)`,
          animation: 'rb-headline 480ms cubic-bezier(.2,.8,.2,1) both',
        }}>
          {grade}
        </div>
        <div style={{
          fontFamily: T.serif, fontSize: 13, letterSpacing: '0.6em', marginTop: -2,
          color: winColor, opacity: 0.95, fontWeight: 400,
          textShadow: `0 0 8px ${headGlow}`,
          animation: 'rb-fade 600ms ease-out 180ms both',
        }}>
          {winLabel}
        </div>
      </div>

      {/* GATE 基準ライン — 中央点から縦に出てヒット点との超過/不足を視覚化 */}
      <div style={{
        position: 'absolute', top: 0, left: gateX - 0.5, width: 1, height,
        background: `linear-gradient(180deg, transparent 0%, ${T.gold300}66 30%, ${T.gold300}66 70%, transparent 100%)`,
        boxShadow: `0 0 6px ${T.goldGlow}`,
        zIndex: 4, opacity: 0.55,
        animation: 'rb-fade 600ms ease-out 200ms both',
      }}/>
      {/* GATE ラベル */}
      <div style={{
        position: 'absolute', top: 12, left: gateX - 30, width: 60,
        textAlign: 'center', fontSize: 9, letterSpacing: '0.4em',
        color: T.gold300, textShadow: `0 0 6px ${T.goldGlow}`, zIndex: 5,
        fontFamily: T.serif, opacity: 0.85,
        animation: 'rb-fade 600ms ease-out 220ms both',
      }}>GATE</div>
      {/* YOUタップ点 → GATE 間の水平点線 — 超過/不足量の表示 */}
      {!isMiss && Math.abs(hitX - gateX) > 6 && (
        <>
          <div style={{
            position: 'absolute',
            top: hitY - 0.5,
            left: Math.min(hitX, gateX),
            width: Math.abs(hitX - gateX),
            height: 1,
            background: `repeating-linear-gradient(90deg, ${T.ink80} 0 3px, transparent 3px 6px)`,
            zIndex: 4, opacity: 0.7,
            animation: 'rb-fade 600ms ease-out 380ms both',
          }}/>
          {/* delta ラベル */}
          <div style={{
            position: 'absolute',
            top: hitY - 22,
            left: (hitX + gateX) / 2 - 30, width: 60,
            textAlign: 'center', fontSize: 11, letterSpacing: '0.05em',
            color: hitX < gateX ? T.cyan300 : T.red400,
            fontFamily: T.serif, fontFeatureSettings: T.tnum,
            zIndex: 5, opacity: 0.95,
            animation: 'rb-fade 600ms ease-out 420ms both',
            textShadow: `0 0 6px ${hitX < gateX ? T.cyanGlow : T.redGlow}`,
          }}>
            {hitX < gateX ? '−' : '+'}{delta}ms
          </div>
        </>
      )}

      {/* YOU レーザー (ヒット点 → 左端. YOU が来た方向) */}
      <SideLaser hitX={hitX} hitY={hitY} side="left" len={hitX} hot={youHotFinal} mid={youMidFinal} />
      {/* GHOST レーザー (GHOST位置 → 右端. GHOST が来た方向) — 弱く・遅く */}
      <SideLaser hitX={ghostPos.x} hitY={ghostPos.y} side="right" len={width - ghostPos.x} hot={ghostHot} mid={ghostMid} weak delay={220} />

      {/* GHOST \u30b9\u30c8\u30c3\u30d7\u4f4d\u7f6e\u306e\u70b9\u5149 (\u4f4d\u7f6e\u8b58\u5225\u7528) */}
      <div style={{
        position: 'absolute', top: ghostPos.y - 5, left: ghostPos.x - 5, width: 10, height: 10,
        borderRadius: '50%', background: T.ink80,
        boxShadow: `0 0 8px ${T.cyanGlow}, 0 0 14px rgba(199,213,235,0.4)`,
        animation: 'rb-spark 700ms cubic-bezier(.2,.8,.2,1) 320ms both',
        zIndex: 8,
      }}/>
      {/* GHOST \u30ea\u30f3\u30b0 (\u5c0f\u3055\u3044) */}
      {[14, 22, 32].map((r, i) => (
        <div key={`gr${i}`} style={{
          position: 'absolute', top: ghostPos.y - r, left: ghostPos.x - r,
          width: r * 2, height: r * 2, borderRadius: '50%',
          border: `1px solid ${i === 0 ? T.cyan300 : T.cyan400}`,
          opacity: 0,
          ['--rb-ring-op']: 0.6 - i * 0.18,
          animation: `rb-ring 900ms cubic-bezier(.2,.8,.2,1) ${320 + i * 50}ms both`,
          zIndex: 6,
        }}/>
      ))}

      {/* 垂直クロス */}
      <VerticalFlare hitX={hitX} hitY={hitY} height={height} hot={youHotFinal} />

      {/* リング */}
      {RING_DEFS.map((d, i) => (
        <Ring key={i} cx={hitX} cy={hitY} def={d} hot={youHotFinal} mid={youMidFinal} />
      ))}

      {/* コア */}
      <div style={{
        position: 'absolute', top: hitY - 5, left: hitX - 5, width: 10, height: 10,
        borderRadius: '50%', background: '#fff',
        boxShadow: `0 0 4px #fff, 0 0 10px ${youHotFinal}`,
        animation: 'rb-core 1100ms cubic-bezier(.2,.8,.2,1) both',
        zIndex: 9,
      }}/>

      {/* ms — YOU 上部, GHOST 下部 (重なり防止) */}
      <div style={{
        position: 'absolute', top: hitY - 86, left: hitX - 60, width: 120,
        textAlign: 'center', fontFeatureSettings: T.tnum,
        animation: 'rb-fade 500ms ease-out 360ms both',
      }}>
        <div style={{ fontSize: 10, letterSpacing: '0.4em', color: T.ink60, marginBottom: 2 }}>YOU</div>
        <div style={{ fontSize: 22, color: T.ink100, lineHeight: 1 }}>
          {isMiss ? 'ー' : delta}<span style={{ fontSize: 11, opacity: 0.7, marginLeft: 2 }}>ms</span>
        </div>
      </div>
      <div style={{
        position: 'absolute', top: ghostPos.y + 60, left: ghostPos.x - 60, width: 120,
        textAlign: 'center', fontFeatureSettings: T.tnum,
        animation: 'rb-fade 500ms ease-out 480ms both',
      }}>
        <div style={{ fontSize: 10, letterSpacing: '0.4em', color: T.ink60, marginBottom: 2 }}>GHOST</div>
        <div style={{ fontSize: 22, color: T.ink80, lineHeight: 1 }}>
          {ghost}<span style={{ fontSize: 11, opacity: 0.7, marginLeft: 2 }}>ms</span>
        </div>
      </div>

      {/* GHOST → GATE 間の超過/不足点線 */}
      {Math.abs(ghostPos.x - gateX) > 6 && (
        <>
          <div style={{
            position: 'absolute',
            top: ghostPos.y - 0.5,
            left: Math.min(ghostPos.x, gateX),
            width: Math.abs(ghostPos.x - gateX),
            height: 1,
            background: `repeating-linear-gradient(90deg, ${T.ink60} 0 3px, transparent 3px 6px)`,
            zIndex: 4, opacity: 0.5,
            animation: 'rb-fade 600ms ease-out 480ms both',
          }}/>
          <div style={{
            position: 'absolute',
            top: ghostPos.y + 6,
            left: (ghostPos.x + gateX) / 2 - 30, width: 60,
            textAlign: 'center', fontSize: 10, letterSpacing: '0.05em',
            color: T.ink60, fontFamily: T.serif, fontFeatureSettings: T.tnum,
            zIndex: 5, opacity: 0.85,
            animation: 'rb-fade 600ms ease-out 520ms both',
          }}>
            {ghostPos.x < gateX ? '−' : '+'}{ghost}ms
          </div>
        </>
      )}

      {/* YOU silhouette 左下 */}
      <div style={{
        position: 'absolute', bottom: 16, left: 32, textAlign: 'center', zIndex: 8,
        animation: 'rb-fade 600ms ease-out 200ms both',
      }}>
        <YouSilhouette glow={isLose ? T.redGlow : (isPerfect ? T.goldGlow : T.cyanGlow)} />
        <div style={{ fontSize: 11, letterSpacing: '0.4em', color: T.ink80, marginTop: 2 }}>YOU</div>
      </div>

      {/* GHOST 右下 */}
      <div style={{
        position: 'absolute', bottom: 16, right: 32, textAlign: 'center', zIndex: 8,
        animation: 'rb-fade 600ms ease-out 320ms both',
      }}>
        <img src="catboy_electric.png" alt=""
          style={{
            display: 'block', width: 76, height: 76, objectFit: 'contain',
            filter: `drop-shadow(0 0 14px ${T.cyanGlow}) drop-shadow(0 0 28px rgba(111,180,255,0.4))`,
            opacity: 0.95,
          }}
        />
        <div style={{
          fontSize: 11, letterSpacing: '0.4em', color: T.cyan300, marginTop: -2,
          textShadow: `0 0 6px ${T.cyanGlow}`,
        }}>GHOST</div>
      </div>

      <div style={{
        position: 'absolute', bottom: 6, left: 0, right: 0,
        textAlign: 'center', fontSize: 10, letterSpacing: '0.4em',
        color: T.ink60, animation: 'rb-fade 600ms ease-out 700ms both',
      }}>
        TAP で 次の戦
      </div>
    </div>
  );
}

// ── 片側レーザー (中央→端) ──
function SideLaser({ hitX, hitY, side, len, hot, mid, weak, delay = 0 }) {
  const toLeft = side === 'left';
  const left = toLeft ? hitX - len : hitX;
  const N = weak ? 70 : 140;
  const particles = React.useMemo(() => {
    const arr = [];
    for (let i = 0; i < N; i++) {
      const u = Math.pow(Math.random(), 2.2);
      const x = toLeft ? len - u * len : u * len;
      const proximity = toLeft ? (x / len) : 1 - (x / len);
      const spread = 2 + proximity * (weak ? 8 : 16);
      const y = (Math.random() - 0.5) * 2 * spread;
      const r = Math.random();
      const size = r < 0.7 ? 1 : r < 0.92 ? 1.5 : 2.2;
      const baseOp = (weak ? 0.2 : 0.35) + proximity * (weak ? 0.4 : 0.65);
      const op = baseOp * (0.6 + Math.random() * 0.4);
      arr.push({ x, y, size, op });
    }
    return arr;
  }, [hitX, side]);
  const coreGrad = toLeft
    ? `linear-gradient(90deg, transparent 0%, ${hot}55 50%, #fff 95%, #fff 100%)`
    : `linear-gradient(90deg, #fff 0%, ${hot}55 50%, transparent 100%)`;
  const transformOrigin = toLeft ? 'right center' : 'left center';
  return (
    <>
      <div style={{
        position: 'absolute', top: hitY - 0.5, left, width: len, height: 1,
        background: coreGrad, zIndex: 6, transformOrigin,
        animation: `rb-laser 520ms cubic-bezier(.2,.8,.2,1) ${delay}ms both`,
        opacity: weak ? 0.6 : 1,
      }}/>
      <div style={{
        position: 'absolute', top: hitY, left, width: len, height: 0,
        zIndex: 5, pointerEvents: 'none',
        animation: `rb-fade 700ms ease-out ${delay + 80}ms both`,
      }}>
        {particles.map((p, i) => (
          <div key={i} style={{
            position: 'absolute',
            left: p.x - p.size, top: p.y - p.size,
            width: p.size * 2, height: p.size * 2,
            borderRadius: '50%', background: hot, opacity: p.op,
            boxShadow: p.size > 1.5 ? `0 0 ${p.size * 2}px ${hot}` : 'none',
          }}/>
        ))}
      </div>
    </>
  );
}

function VerticalFlare({ hitX, hitY, height, hot }) {
  return (
    <>
      <div style={{
        position: 'absolute', top: 0, left: hitX - 0.5, width: 1, height: hitY,
        background: `linear-gradient(180deg, transparent 0%, ${hot}33 60%, ${hot} 100%)`,
        zIndex: 5, transformOrigin: 'bottom center',
        animation: 'rb-laser-v 600ms cubic-bezier(.2,.8,.2,1) 120ms both',
      }}/>
      <div style={{
        position: 'absolute', top: hitY, left: hitX - 0.5, width: 1, height: height - hitY,
        background: `linear-gradient(180deg, ${hot} 0%, ${hot}33 40%, transparent 100%)`,
        zIndex: 5, transformOrigin: 'top center',
        animation: 'rb-laser-v 600ms cubic-bezier(.2,.8,.2,1) 160ms both',
      }}/>
    </>
  );
}

function Ring({ cx, cy, def, hot, mid }) {
  const color = def.hot ? hot : mid;
  return (
    <div style={{
      position: 'absolute', top: cy - def.r, left: cx - def.r,
      width: def.r * 2, height: def.r * 2, borderRadius: '50%',
      border: `${def.w}px solid ${color}`,
      opacity: 0,
      animation: `rb-ring 1100ms cubic-bezier(.2,.8,.2,1) ${def.delay}ms both`,
      ['--rb-ring-op']: def.op,
      zIndex: 5,
    }}/>
  );
}

function YouSilhouette({ glow }) {
  return (
    <svg width="50" height="74" viewBox="0 0 50 74" style={{ filter: `drop-shadow(0 0 10px ${glow})` }}>
      <circle cx="25" cy="14" r="9" fill={T.ink100} />
      <path d="M 6 74 Q 6 40 25 32 Q 44 40 44 74 Z" fill={T.ink100} />
    </svg>
  );
}

function Ready() {
  return (
    <>
      <div style={{
        position: 'absolute', right: 36, bottom: 24, zIndex: 5,
        animation: 'rb-bob 3.2s ease-in-out infinite',
      }}>
        <img src="catboy_confident.png" alt=""
          style={{
            display: 'block', width: 200, height: 'auto',
            filter: `drop-shadow(0 0 18px ${T.cyanGlow}) drop-shadow(0 8px 22px rgba(0,0,0,0.5))`,
          }}
        />
        <div style={{
          position: 'absolute', top: 6, right: 180,
          background: T.bgPanel, color: T.ink100, fontSize: 12,
          padding: '8px 14px', borderRadius: 12, letterSpacing: '0.04em',
          border: `1px solid ${T.cyan500}`,
          boxShadow: `0 0 16px ${T.cyanGlow}`,
          whiteSpace: 'nowrap', fontFamily: T.serif, fontWeight: 500,
        }}>
          おかえり、今日もやる？
          <div style={{
            position: 'absolute', right: -7, top: 14, width: 0, height: 0,
            borderTop: '6px solid transparent', borderBottom: '6px solid transparent',
            borderLeft: `8px solid ${T.cyan500}`,
          }} />
        </div>
      </div>

      <div style={{
        position: 'absolute', top: 0, bottom: 0, left: 64,
        display: 'flex', flexDirection: 'column', justifyContent: 'center',
        zIndex: 4, pointerEvents: 'none',
      }}>
        <div style={{ fontSize: 11, letterSpacing: '0.55em', color: T.cyan400, textShadow: `0 0 8px ${T.cyanGlow}` }}>
          GHOST · 7-BAN
        </div>
        <div style={{
          fontFamily: T.serif, fontSize: 64, marginTop: 4, lineHeight: 1.0,
          letterSpacing: '0.04em', color: T.ink100,
          textShadow: `0 0 18px rgba(111,180,255,0.35)`,
        }}>
          7 番勝負
        </div>
        <div style={{ fontFamily: T.serif, fontSize: 16, marginTop: 14, color: T.ink80, lineHeight: 1.7, maxWidth: 360 }}>
          昨日の自分が、<br/>
          いま光の向こうから挑んでくる。
        </div>
        <div style={{
          marginTop: 24, padding: '10px 30px', borderRadius: 999,
          background: 'transparent',
          border: `1.5px solid ${T.cyan400}`, color: T.cyan300,
          fontSize: 14, letterSpacing: '0.3em', fontWeight: 700,
          boxShadow: `0 0 14px ${T.cyanGlow}, inset 0 0 0 1px rgba(111,180,255,0.15)`,
          animation: 'rb-glow 2s ease-in-out infinite',
          alignSelf: 'flex-start',
        }}>
          TAP で 開始
        </div>
      </div>
    </>
  );
}

function Done({ wins, gwins }) {
  const playerWon = wins > gwins;
  const tied = wins === gwins;
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 5, animation: 'rb-fade 400ms ease-out both' }}>
      <div style={{ position: 'absolute', right: 60, top: '50%', transform: 'translateY(-50%)' }}>
        <img src={playerWon ? 'catboy_energetic.png' : 'catboy_electric.png'} alt=""
          style={{
            display: 'block', width: 240, height: 'auto',
            filter: `drop-shadow(0 0 24px ${playerWon ? T.goldGlow : T.cyanGlow})`,
            animation: 'rb-bob 2.6s ease-in-out infinite',
          }}
        />
      </div>
      <div style={{ position: 'absolute', top: '50%', left: 64, transform: 'translateY(-50%)' }}>
        <div style={{ fontSize: 12, letterSpacing: '0.5em', color: T.cyan400, textShadow: `0 0 8px ${T.cyanGlow}` }}>
          決 着
        </div>
        <div style={{
          fontFamily: T.serif, fontSize: 110, lineHeight: 1, marginTop: 6,
          letterSpacing: '0.02em', display: 'flex', gap: 22, alignItems: 'baseline',
          fontFeatureSettings: T.tnum,
        }}>
          <span style={{
            color: playerWon ? T.gold300 : T.ink80,
            textShadow: playerWon ? `0 0 28px ${T.goldGlow}` : 'none',
          }}>{wins}</span>
          <span style={{ fontSize: 28, color: T.ink40 }}>—</span>
          <span style={{
            color: !playerWon && !tied ? T.cyan300 : T.ink60,
            textShadow: !playerWon && !tied ? `0 0 18px ${T.cyanGlow}` : 'none',
          }}>{gwins}</span>
        </div>
        <div style={{ fontFamily: T.serif, fontSize: 22, marginTop: 12, color: T.ink100 }}>
          {playerWon ? '昨日の自分を、超えた。' : tied ? '互角。' : 'もう一歩。'}
        </div>
        <div style={{ fontSize: 11, color: T.ink60, letterSpacing: '0.4em', marginTop: 24 }}>
          TAP で もう一度
        </div>
      </div>
    </div>
  );
}

window.ReflexVariantB = ReflexVariantB;
