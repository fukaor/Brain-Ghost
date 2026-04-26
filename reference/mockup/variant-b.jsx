// variant-b.jsx — ゴースト7番勝負 / Cinematic
// 2-lane layout (top = YOU, bottom = GHOST). Both targets race simultaneously
// toward the same GHOST LINE. Ghost auto-taps at its recorded delta — you see
// the ghost's tap-flash BEFORE or AFTER yours, which makes "losing to a ghost"
// visceral. Bottom strip also shows R1–R7 history tiles.

const CFG_B = [
  { move: 2200, pre: 1500, dir: 'left'  },
  { move: 2000, pre: 1200, dir: 'right' },
  { move: 1500, pre: 1000, dir: 'left'  },
  { move: 1200, pre:  900, dir: 'right' },
  { move: 1000, pre:  800, dir: 'left'  },
  { move:  900, pre:  700, dir: 'right' },
  { move:  900, pre: 1000, dir: 'left'  },
];
const GHOST_B = [150, 152, 148, 155, 160, 145, 140];

function ReflexVariantB({ width = 892, height = 412 }) {
  const [, force] = React.useReducer(x => x + 1, 0);
  const state = React.useRef({
    phase: 'ready',     // 'ready' | 'countdown' | 'announce' | 'moving' | 'result' | 'done'
    round: 0,
    wins: 0,
    gwins: 0,
    countdown: 3,
    anStartMs: 0,
    moveStartMs: 0,
    linePassMs: 0,       // ideal moment player target crosses line
    ghostPassMs: 0,      // linePassMs + ghost reaction delta (when ghost fires)
    ghostFired: false,
    targetX: -30,
    ghostX: -30,
    ghostStopX: null,     // ghost's orb X at moment of auto-tap
    lastTap: null,
    history: [],         // filled as rounds resolve
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

      if (state.phase === 'announce' || state.phase === 'moving') {
        const cfg = CFG_B[state.round];
        const trackStart = 24, trackEnd = width - 24;
        const fromLeft = cfg.dir === 'left';
        const startX = fromLeft ? trackStart - 30 : trackEnd + 30;
        const endX   = fromLeft ? trackEnd + 30   : trackStart - 30;

        if (state.phase === 'announce') {
          state.targetX = startX;
          state.ghostX  = startX;
        } else {
          const t = Math.min(1, (now - state.moveStartMs) / cfg.move);
          const x = startX + (endX - startX) * t;
          state.targetX = x;
          state.ghostX  = x;           // ghost rides the same target
          // ghost auto-fires
          if (!state.ghostFired && now >= state.ghostPassMs) {
            state.ghostFired = true;
            // record ghost's stop X (where its orb was when it fired)
            const tg = Math.min(1, (state.ghostPassMs - state.moveStartMs) / cfg.move);
            state.ghostStopX = startX + (endX - startX) * tg;
          }
          if (t >= 1 && !state.lastTap) {
            resolveMiss();
          }
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
    state.ghostStopX = null;
    state.phase = 'announce';
    state.anStartMs = performance.now();
    const cfg = CFG_B[r];
    pushT(() => {
      state.phase = 'moving';
      state.moveStartMs = performance.now();
      state.linePassMs = state.moveStartMs + cfg.move / 2;
      state.ghostPassMs = state.linePassMs + GHOST_B[r];
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
      const signed = now - state.linePassMs;
      if (signed < -80) { isFly = true; deltaMs = 999; }
      else { deltaMs = Math.round(Math.abs(signed)); }
    } else {
      return;
    }

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
    state.lastTap = { delta: deltaMs, ghost, grade, win };
    state.history[state.round] = state.lastTap;
    state.phase = 'result';
    force();
  };

  const resolveMiss = () => {
    clearTimers();
    const ghost = GHOST_B[state.round];
    state.lastTap = { delta: 1000, ghost, grade: 'MISS', win: false };
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

  // ----- layout -----
  const cfg = CFG_B[state.round];
  const HUD_H = 44;
  const LANE_Y_YOU   = HUD_H + 22;    // top of YOU lane
  const LANE_H       = 96;            // each lane height
  const LANE_Y_GHOST = LANE_Y_YOU + LANE_H + 28; // bottom lane start
  const MID_YOU      = LANE_Y_YOU + LANE_H / 2;
  const MID_GHOST    = LANE_Y_GHOST + LANE_H / 2;
  const HIST_Y       = LANE_Y_GHOST + LANE_H + 14;
  const lineX = width / 2;

  const bg = state.phase === 'result' && state.lastTap?.grade === 'PERFECT'
    ? 'radial-gradient(ellipse at 50% 55%, #FDE68A 0%, #FACC15 35%, #8B5A00 100%)'
    : state.phase === 'result' && state.lastTap?.win
    ? 'radial-gradient(ellipse at 50% 55%, #6C9FFF 0%, #0058BA 50%, #001B47 100%)'
    : state.phase === 'result'
    ? 'linear-gradient(180deg, #1E293B 0%, #0F172A 100%)'
    : 'linear-gradient(180deg, #0058BA 0%, #003B87 100%)';

  // Ghost fire flash age (for glow decay)
  const ghostFireAge = state.ghostFired
    ? performance.now() - state.ghostPassMs
    : -1;
  // Player fire flash age
  const playerFireAge = state.lastTap && state.phase === 'result'
    ? performance.now() - (state.linePassMs + (state.lastTap.win ? state.lastTap.delta : -state.lastTap.delta))
    : -1;

  return (
    <div onClick={onClick} style={{
      width, height, position: 'relative', overflow: 'hidden',
      background: bg, transition: 'background 300ms ease-out',
      fontFamily: '"Noto Sans JP", system-ui, sans-serif', fontWeight: 700,
      color: '#F0F2FF', userSelect: 'none', cursor: 'pointer',
    }}>
      {/* ambient grid */}
      <div style={{
        position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none',
        backgroundImage: 'repeating-linear-gradient(90deg, rgba(255,255,255,0.03) 0 1px, transparent 1px 60px)',
      }} />

      {/* ─── HUD ─── */}
      {state.phase !== 'done' && state.phase !== 'ready' && (
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: HUD_H,
          padding: '0 20px', display: 'flex', alignItems: 'center',
          justifyContent: 'space-between', zIndex: 8,
          background: 'rgba(0,0,0,0.3)', backdropFilter: 'blur(8px)',
          borderBottom: '1px solid rgba(255,255,255,0.1)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 12, letterSpacing: '0.08em' }}>
            <span className="msi" style={{ fontSize: 16 }}>swords</span>
            第 <span style={{ fontSize: 18 }}>{state.round + 1}</span> 戦 / 7
          </div>
          <div style={{ display: 'flex', gap: 3 }}>
            {Array.from({ length: 7 }).map((_, i) => {
              const h = state.history[i];
              const c = !h ? (i === state.round ? 'rgba(255,255,255,0.7)' : 'rgba(255,255,255,0.2)')
                : h.win ? '#B7F5C8' : '#94A3B8';
              return <div key={i} style={{ width: 22, height: 4, borderRadius: 2, background: c }} />;
            })}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, fontFeatureSettings: '"tnum"' }}>
            <span style={{ fontSize: 9, letterSpacing: '0.2em', opacity: 0.6 }}>YOU</span>
            <span style={{ fontSize: 20, color: '#B7F5C8' }}>{state.wins}</span>
            <span style={{ opacity: 0.4 }}>-</span>
            <span style={{ fontSize: 20, color: '#CBD5E1' }}>{state.gwins}</span>
            <span style={{ fontSize: 9, letterSpacing: '0.2em', opacity: 0.6 }}>GHOST</span>
          </div>
        </div>
      )}

      {/* ─── PLAY AREA (both lanes + GHOST LINE) ─── */}
      {(state.phase === 'announce' || state.phase === 'moving' || state.phase === 'result') && (
        <>
          {/* GHOST LINE — spans both lanes */}
          <div style={{
            position: 'absolute', top: LANE_Y_YOU - 8, left: lineX - 1.5, width: 3,
            height: (LANE_Y_GHOST + LANE_H + 8) - (LANE_Y_YOU - 8),
            background: 'rgba(255,255,255,0.95)',
            boxShadow: `0 0 ${10 + state.pulse * 10}px rgba(255,255,255,${0.55 + state.pulse * 0.35})`,
            zIndex: 3, pointerEvents: 'none',
          }} />
          <div style={{
            position: 'absolute', top: LANE_Y_YOU - 24, left: lineX - 50, width: 100,
            fontSize: 9, letterSpacing: '0.3em', textAlign: 'center',
            color: 'rgba(255,255,255,0.85)', zIndex: 4, pointerEvents: 'none',
          }}>GHOST LINE</div>

          {/* ── YOU lane ── */}
          <LaneFrame
            top={LANE_Y_YOU} height={LANE_H} width={width}
            label="自分" side="you"
            active={state.phase === 'moving'}
          />
          {/* rail */}
          <div style={{
            position: 'absolute', top: MID_YOU - 1, left: 24, right: 24, height: 2,
            background: 'linear-gradient(90deg, transparent, rgba(183,245,200,0.3) 10%, rgba(183,245,200,0.3) 90%, transparent)',
            zIndex: 1,
          }} />
          {/* player target */}
          <TargetOrb x={state.targetX} y={MID_YOU} dir={cfg.dir} color="#22C55E" glow="#B7F5C8" />
          {/* player tap flash at linePassMs+delta */}
          {state.phase === 'result' && state.lastTap && !['FLYING','MISS'].includes(state.lastTap.grade) && (
            <TapFlash x={lineX} y={MID_YOU} color="#B7F5C8" big />
          )}

          {/* ── GHOST lane ── */}
          <LaneFrame
            top={LANE_Y_GHOST} height={LANE_H} width={width}
            label="ゴースト" side="ghost"
            active={state.phase === 'moving'}
          />
          <div style={{
            position: 'absolute', top: MID_GHOST - 1, left: 24, right: 24, height: 2,
            background: 'linear-gradient(90deg, transparent, rgba(203,213,225,0.25) 10%, rgba(203,213,225,0.25) 90%, transparent)',
            zIndex: 1,
          }} />
          {/* ghost silhouette target (only moving/announce, hidden in result) */}
          {state.phase !== 'result' && (
            <GhostOrb x={state.ghostX} y={MID_GHOST} dir={cfg.dir} fired={state.ghostFired} />
          )}
          {/* ghost stop marker — persists through result */}
          {state.ghostStopX != null && (
            <GhostStopMarker x={state.ghostStopX} yTop={LANE_Y_GHOST} laneH={LANE_H} lineX={lineX} />
          )}
          {/* ghost tap flash once it fires */}
          {state.ghostFired && ghostFireAge < 800 && (
            <TapFlash x={lineX} y={MID_GHOST} color="#CBD5E1" age={ghostFireAge} />
          )}
          {/* ghost readout — time delta from now */}
          {state.phase === 'moving' && (
            <div style={{
              position: 'absolute', top: LANE_Y_GHOST + 6, right: 20,
              fontSize: 10, letterSpacing: '0.2em', color: 'rgba(203,213,225,0.7)',
              fontFeatureSettings: '"tnum"', zIndex: 4,
            }}>
              {state.ghostFired
                ? <><span style={{ color: '#CBD5E1' }}>{GHOST_B[state.round]}</span> ms で 反応</>
                : <>反応 <span style={{ color: '#CBD5E1' }}>{GHOST_B[state.round]}</span> ms</>}
            </div>
          )}
        </>
      )}

      {/* ─── ANNOUNCE headline — overlays center between lanes ─── */}
      {state.phase === 'announce' && (
        <div key={`ah-${state.round}`} style={{
          position: 'absolute',
          top: (LANE_Y_YOU + LANE_H + LANE_Y_GHOST) / 2 - 28,
          left: 0, right: 0, height: 56,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16,
          zIndex: 6, pointerEvents: 'none',
          animation: 'rb-slam 280ms cubic-bezier(.2,.8,.2,1) both',
          fontSize: 30, letterSpacing: '-0.02em',
          textShadow: '0 4px 20px rgba(0,0,0,0.6)',
        }}>
          {cfg.dir === 'left'
            ? <><Arrow dir="left" /><span>左から来るぞ</span></>
            : <><span>右から来るぞ</span><Arrow dir="right" /></>}
        </div>
      )}

      {/* ─── HISTORY STRIP (bottom) ─── */}
      {(state.phase === 'announce' || state.phase === 'moving' || state.phase === 'result') && (
        <div style={{
          position: 'absolute', left: 20, right: 20, top: HIST_Y, height: height - HIST_Y - 10,
          display: 'flex', gap: 6, zIndex: 4, pointerEvents: 'none', alignItems: 'stretch',
        }}>
          {Array.from({ length: 7 }).map((_, i) => {
            const h = state.history[i];
            const cur = i === state.round && state.phase !== 'result';
            const bgT = h
              ? (h.win ? 'rgba(34,197,94,0.25)' : 'rgba(148,163,184,0.18)')
              : cur ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.04)';
            const border = cur ? '1px solid rgba(255,255,255,0.6)'
              : h ? `1px solid ${h.win ? 'rgba(183,245,200,0.5)' : 'rgba(203,213,225,0.25)'}`
              : '1px solid rgba(255,255,255,0.1)';
            return (
              <div key={i} style={{
                flex: 1, borderRadius: 8, background: bgT, border,
                padding: '6px 8px', display: 'flex', flexDirection: 'column',
                justifyContent: 'space-between', minHeight: 0,
                boxShadow: cur ? '0 0 12px rgba(255,255,255,0.2)' : 'none',
              }}>
                <div style={{
                  fontSize: 9, letterSpacing: '0.2em',
                  color: cur ? '#FACC15' : 'rgba(255,255,255,0.5)',
                }}>R{i + 1}</div>
                {h ? (
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, fontFeatureSettings: '"tnum"' }}>
                    <span style={{
                      fontSize: 18, color: h.win ? '#B7F5C8' : '#F0F2FF',
                    }}>{['FLYING','MISS'].includes(h.grade) ? 'ー' : h.delta}</span>
                    <span style={{ fontSize: 9, opacity: 0.5 }}>ms</span>
                    <span style={{
                      marginLeft: 'auto', fontSize: 11,
                      color: h.win ? '#B7F5C8' : '#CBD5E1',
                    }}>{h.win ? '○' : '×'}</span>
                  </div>
                ) : (
                  <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.3)', letterSpacing: '0.1em' }}>
                    {cur ? '進行中' : '—'}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* ─── RESULT CARD — floats over center ─── */}
      {state.phase === 'result' && state.lastTap && (
        <div style={{
          position: 'absolute',
          top: (LANE_Y_YOU + LANE_H + LANE_Y_GHOST) / 2 - 42,
          left: 0, right: 0,
          display: 'flex', justifyContent: 'center', zIndex: 7, pointerEvents: 'none',
          animation: 'rb-slam 300ms cubic-bezier(.2,.8,.2,1) both',
        }}>
          <div style={{
            padding: '10px 26px', minWidth: 320,
            background: 'rgba(0,0,0,0.62)', backdropFilter: 'blur(12px)',
            border: '1px solid rgba(255,255,255,0.25)', borderRadius: 12,
            textAlign: 'center',
            boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
          }}>
            <div style={{
              fontSize: 24, lineHeight: 1,
              color: state.lastTap.grade === 'PERFECT' ? '#FACC15'
                   : state.lastTap.grade === 'GREAT' ? '#F0F2FF'
                   : state.lastTap.grade === 'GOOD' ? '#B7F5C8'
                   : '#94A3B8',
              textShadow: state.lastTap.grade === 'PERFECT' ? '0 0 20px rgba(250,204,21,0.8)' : '0 2px 10px rgba(0,0,0,0.4)',
            }}>
              {state.lastTap.grade === 'PERFECT' && '★ '}{state.lastTap.grade}
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', gap: 22, marginTop: 6, alignItems: 'baseline' }}>
              <div>
                <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', letterSpacing: '0.2em' }}>自分</div>
                <div style={{ fontSize: 22, color: state.lastTap.win ? '#B7F5C8' : '#F0F2FF', fontFeatureSettings: '"tnum"' }}>
                  {['FLYING','MISS'].includes(state.lastTap.grade) ? 'ー' : state.lastTap.delta}
                  <span style={{ fontSize: 11, opacity: 0.6, marginLeft: 3 }}>ms</span>
                </div>
              </div>
              <div style={{ width: 1, alignSelf: 'stretch', background: 'rgba(255,255,255,0.2)' }} />
              <div>
                <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', letterSpacing: '0.2em' }}>ゴースト</div>
                <div style={{ fontSize: 22, color: !state.lastTap.win ? '#CBD5E1' : '#94A3B8', fontFeatureSettings: '"tnum"' }}>
                  {state.lastTap.ghost}
                  <span style={{ fontSize: 11, opacity: 0.6, marginLeft: 3 }}>ms</span>
                </div>
              </div>
            </div>
            <div style={{
              fontSize: 11, letterSpacing: '0.15em', marginTop: 4,
              color: state.lastTap.win ? '#B7F5C8' : '#CBD5E1',
            }}>
              {state.lastTap.win ? '○ プレイヤー勝利' : '× ゴースト勝利'}
              <span style={{ marginLeft: 10, opacity: 0.55, letterSpacing: '0.25em' }}>TAP で 次</span>
            </div>
          </div>
        </div>
      )}

      {/* ─── READY screen ─── */}
      {state.phase === 'ready' && (
        <>
          {/* Left: ghost character — anchored flush-left */}
          <div style={{
            position: 'absolute', left: 32, bottom: 28, zIndex: 5,
          }}>
            <img src="ghost_seirei.png" alt=""
              style={{
                display: 'block', width: 200, height: 'auto',
                filter: 'drop-shadow(0 10px 24px rgba(0,0,0,0.35))',
                animation: 'rb-bob 3.2s ease-in-out infinite',
              }}
            />
            {/* speech bubble — floats above character, points down-left */}
            <div style={{
              position: 'absolute', top: -30, left: 120,
              background: '#fff', color: '#232C51', fontSize: 12,
              padding: '7px 13px', borderRadius: 14, letterSpacing: '0.04em',
              boxShadow: '0 6px 16px rgba(0,0,0,0.3)',
              whiteSpace: 'nowrap', zIndex: 6, fontWeight: 600,
              animation: 'rb-fade 600ms ease-out both',
            }}>
              今日は本気でいくよ
              <div style={{
                position: 'absolute', left: 18, bottom: -7, width: 0, height: 0,
                borderLeft: '6px solid transparent', borderRight: '6px solid transparent',
                borderTop: '8px solid #fff',
              }} />
            </div>
          </div>

          {/* Center: title + CTA — absolutely centered in the frame */}
          <div style={{
            position: 'absolute', inset: 0, display: 'flex',
            flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            zIndex: 4, pointerEvents: 'none',
          }}>
            <div style={{ fontSize: 11, letterSpacing: '0.5em', opacity: 0.7 }}>GHOST 7-BAN</div>
            <div style={{ fontSize: 56, marginTop: 2, letterSpacing: '-0.02em', lineHeight: 1 }}>7 番勝負</div>
            <div style={{ fontSize: 12.5, opacity: 0.78, marginTop: 14, lineHeight: 1.7, letterSpacing: '0.04em', textAlign: 'center' }}>
              上レーン＝自分、下レーン＝ゴースト。<br/>
              同じターゲットで GHOST LINE を同時に走り、<br/>
              ゴーストより先にラインで TAP せよ
            </div>
            <div style={{
              marginTop: 20, padding: '11px 36px', borderRadius: 999,
              background: '#FACC15', color: '#1E293B', fontSize: 16, letterSpacing: '0.15em',
              boxShadow: '0 6px 18px rgba(0,0,0,0.3), inset 0 2px 0 rgba(255,255,255,0.5)',
            }}>
              TAP で スタート
            </div>
          </div>
        </>
      )}

      {/* ─── COUNTDOWN ─── */}
      {state.phase === 'countdown' && (
        <div key={`cd-${state.countdown}`} style={{
          position: 'absolute', inset: 0, display: 'flex',
          alignItems: 'center', justifyContent: 'center', zIndex: 5,
          fontSize: 180, lineHeight: 1, letterSpacing: '-0.05em',
          color: '#FACC15', textShadow: '0 8px 30px rgba(0,0,0,0.5)',
          animation: 'rb-slam 500ms cubic-bezier(.2,.8,.2,1) both',
        }}>
          {state.countdown}
        </div>
      )}

      {/* ─── DONE screen ─── */}
      {state.phase === 'done' && (
        <div style={{
          position: 'absolute', inset: 0, display: 'flex',
          alignItems: 'center', justifyContent: 'center', flexDirection: 'column', zIndex: 5,
          animation: 'rb-fade 400ms ease-out both',
        }}>
          <div style={{ fontSize: 12, letterSpacing: '0.5em', opacity: 0.7 }}>決着</div>
          <div style={{
            fontSize: 110, marginTop: 4, letterSpacing: '-0.04em',
            display: 'flex', gap: 30, alignItems: 'baseline',
            fontFeatureSettings: '"tnum"',
            textShadow: '0 6px 28px rgba(0,0,0,0.4)',
          }}>
            <span style={{ color: state.wins > state.gwins ? '#B7F5C8' : '#F0F2FF' }}>{state.wins}</span>
            <span style={{ fontSize: 34, opacity: 0.5 }}>vs</span>
            <span style={{ color: state.gwins > state.wins ? '#CBD5E1' : '#94A3B8' }}>{state.gwins}</span>
          </div>
          <div style={{ fontSize: 20, marginTop: 14 }}>
            {state.wins > state.gwins ? 'プレイヤー勝越' : state.wins === state.gwins ? '互角' : 'ゴースト勝越'}
          </div>
          <div style={{ fontSize: 12, opacity: 0.5, letterSpacing: '0.3em', marginTop: 24 }}>
            TAP で もう一度
          </div>
        </div>
      )}

      <style>{`
        @keyframes rb-fade { from{opacity:0} to{opacity:1} }
        @keyframes rb-slam { 0%{transform:scale(0.6);opacity:0} 60%{transform:scale(1.12);opacity:1} 100%{transform:scale(1);opacity:1} }
        @keyframes rb-fire { 0%{transform:scale(0.3);opacity:0} 30%{transform:scale(1.2);opacity:1} 100%{transform:scale(2.2);opacity:0} }
        @keyframes rb-bob  { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-6px)} }
      `}</style>
    </div>
  );
}

// ─── Lane frame with left-side label ───
function LaneFrame({ top, height, width, label, side, active }) {
  const isGhost = side === 'ghost';
  const tint = isGhost ? 'rgba(203,213,225,0.05)' : 'rgba(183,245,200,0.06)';
  const border = active
    ? (isGhost ? 'rgba(203,213,225,0.35)' : 'rgba(183,245,200,0.5)')
    : 'rgba(255,255,255,0.1)';
  return (
    <>
      <div style={{
        position: 'absolute', top, left: 12, right: 12, height,
        borderRadius: 10, border: `1px solid ${border}`, background: tint,
        zIndex: 0, pointerEvents: 'none',
        transition: 'border-color 200ms',
      }} />
      <div style={{
        position: 'absolute', top: top + 6, left: 22,
        fontSize: 10, letterSpacing: '0.3em', zIndex: 4,
        color: isGhost ? 'rgba(203,213,225,0.75)' : 'rgba(183,245,200,0.85)',
        pointerEvents: 'none',
      }}>{label}</div>
    </>
  );
}

// ─── Player target orb ───
function TargetOrb({ x, y, dir, color, glow }) {
  return (
    <div style={{
      position: 'absolute', top: y - 18, left: x - 18, width: 36, height: 36,
      zIndex: 3, pointerEvents: 'none',
    }}>
      <div style={{
        position: 'absolute', top: 14, left: dir === 'left' ? -70 : 36, width: 70, height: 8,
        background: dir === 'left'
          ? `linear-gradient(90deg, transparent, ${glow})`
          : `linear-gradient(90deg, ${glow}, transparent)`,
        borderRadius: 4, filter: 'blur(2px)', opacity: 0.85,
      }} />
      <div style={{
        position: 'absolute', inset: 2, borderRadius: '50%',
        background: `radial-gradient(circle, #fff 0%, ${glow} 40%, ${color} 100%)`,
        boxShadow: `0 0 24px ${glow}, 0 0 12px rgba(255,255,255,0.9)`,
      }} />
    </div>
  );
}

// ─── Ghost target (silhouette) ───
function GhostOrb({ x, y, dir, fired }) {
  return (
    <div style={{
      position: 'absolute', top: y - 16, left: x - 16, width: 32, height: 32,
      zIndex: 3, pointerEvents: 'none', opacity: fired ? 0.35 : 0.9,
      transition: 'opacity 200ms',
    }}>
      <div style={{
        position: 'absolute', top: 13, left: dir === 'left' ? -60 : 32, width: 60, height: 6,
        background: dir === 'left'
          ? 'linear-gradient(90deg, transparent, rgba(203,213,225,0.5))'
          : 'linear-gradient(90deg, rgba(203,213,225,0.5), transparent)',
        borderRadius: 3, filter: 'blur(2px)',
      }} />
      <div style={{
        position: 'absolute', inset: 2, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(241,245,249,0.9) 0%, rgba(148,163,184,0.55) 60%, rgba(100,116,139,0.3) 100%)',
        border: '1px dashed rgba(241,245,249,0.55)',
        boxShadow: '0 0 14px rgba(203,213,225,0.35)',
      }} />
    </div>
  );
}

// ─── Tap flash at GHOST LINE ───
function TapFlash({ x, y, color, big, age = 0 }) {
  const fade = Math.max(0, 1 - age / 800);
  const size = big ? 60 : 44;
  return (
    <div style={{
      position: 'absolute', top: y - size / 2, left: x - size / 2,
      width: size, height: size, zIndex: 5, pointerEvents: 'none',
      opacity: fade,
    }}>
      <div style={{
        position: 'absolute', inset: 0, borderRadius: '50%',
        border: `2px solid ${color}`,
        animation: 'rb-fire 700ms ease-out forwards',
        boxShadow: `0 0 24px ${color}`,
      }} />
    </div>
  );
}

// ─── Ghost stop marker — shows where the ghost's orb was when it auto-fired ───
function GhostStopMarker({ x, yTop, laneH, lineX }) {
  const dxPx = Math.round(x - lineX); // + = past line (ghost was late)
  return (
    <>
      {/* vertical dashed line through the ghost lane */}
      <div style={{
        position: 'absolute', top: yTop, left: x - 1, width: 2, height: laneH,
        background: 'repeating-linear-gradient(180deg, #CBD5E1 0 4px, transparent 4px 7px)',
        zIndex: 4, pointerEvents: 'none',
        boxShadow: '0 0 6px rgba(203,213,225,0.4)',
      }} />
      {/* top cap / pin */}
      <div style={{
        position: 'absolute', top: yTop - 2, left: x - 6, width: 12, height: 4,
        background: '#CBD5E1', borderRadius: 2, zIndex: 5, pointerEvents: 'none',
      }} />
      {/* bottom label */}
      <div style={{
        position: 'absolute', top: yTop + laneH - 16, left: x + 6,
        fontSize: 9, letterSpacing: '0.15em', color: '#CBD5E1',
        background: 'rgba(15,23,42,0.75)', padding: '2px 6px', borderRadius: 3,
        zIndex: 5, pointerEvents: 'none', fontFeatureSettings: '"tnum"',
        whiteSpace: 'nowrap',
      }}>
        GHOST 停止 · {dxPx >= 0 ? '+' : ''}{dxPx}px
      </div>
    </>
  );
}

function Arrow({ dir }) {
  return (
    <span style={{
      display: 'inline-block', fontSize: 40, lineHeight: 1,
      color: '#FACC15', textShadow: '0 3px 10px rgba(0,0,0,0.4)',
    }}>
      {dir === 'left' ? '←' : '→'}
    </span>
  );
}

window.ReflexVariantB = ReflexVariantB;
