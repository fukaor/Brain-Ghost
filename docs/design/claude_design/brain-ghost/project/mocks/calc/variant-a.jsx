// variant-a.jsx — ゴースト計算 / Midnight Cat 版 (PORTRAIT 412×892)
// キービジュアル準拠:
//   ・漆黒の背景
//   ・明朝で「合計は？」
//   ・赤い残時間ゲージの上を catboy_electric がスライド
//   ・数字2つ並列表示 (4 _ 7 _ など)
//   ・3×4 数値パッド (active = シアンの光)
// Phases: ready → countdown → play(question×10) → done
//   問題は連続10問. 1問ごとに残時間バーが減り, 答えるたびに次へ.

const T = {
  bgVoid:    '#000000',
  bgDeep:    '#060912',
  bgPanel:   '#0B1220',
  bgElev:    '#111827',
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

// 10 問. 各問題 (a, b, sum). 4+7=11 がキービジュアル例.
const PROBLEMS = [
  { a: 4,  b: 7,  sum: 11 },
  { a: 8,  b: 5,  sum: 13 },
  { a: 3,  b: 9,  sum: 12 },
  { a: 6,  b: 6,  sum: 12 },
  { a: 7,  b: 8,  sum: 15 },
  { a: 9,  b: 4,  sum: 13 },
  { a: 5,  b: 9,  sum: 14 },
  { a: 8,  b: 8,  sum: 16 },
  { a: 6,  b: 7,  sum: 13 },
  { a: 4,  b: 9,  sum: 13 },
];
const TOTAL = PROBLEMS.length;
const TIER = 'T3';                  // ティア表示 (左上)
const Q_LIMIT_MS = 5000;            // 1 問の制限時間 (5 秒)

function CalcVariantA({ width = 412, height = 892, phase: forcedPhase }) {
  const [, force] = React.useReducer(x => x + 1, 0);
  const isFrozen = !!forcedPhase;

  const state = React.useRef({
    phase: forcedPhase || 'ready',
    qIdx: 0,                        // 現在の問題 index (0..9)
    answered: 0,                    // 答えた数 (=右上の x/10 の x)
    correct: 0,
    qStartMs: 0,
    inputStr: '',
    activeKey: null,                // 直近押下キー (シアン光)
    lastTap: null,                  // 結果プレビュー用
    history: [],                    // [{ correct, delta, answer, given }]
    pulse: 0,
  }).current;

  const timersRef = React.useRef([]);
  const rafRef = React.useRef(null);
  const pushT = (fn, ms) => { const id = setTimeout(fn, ms); timersRef.current.push(id); return id; };
  const clearTimers = () => { timersRef.current.forEach(clearTimeout); timersRef.current = []; };

  React.useEffect(() => {
    const loop = () => {
      state.pulse = (performance.now() % 600) / 600;
      // 時間切れチェック
      if (state.phase === 'play' && !isFrozen) {
        const elapsed = performance.now() - state.qStartMs;
        if (elapsed >= Q_LIMIT_MS) {
          submit(true);
        }
      }
      force();
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(rafRef.current);
    // eslint-disable-next-line
  }, []);

  // 静止フレーム用
  React.useEffect(() => {
    if (!forcedPhase) return;
    state.phase = forcedPhase;
    if (forcedPhase === 'play') {
      state.qIdx = 9; state.answered = 9;
      state.qStartMs = performance.now() - 2700;
      state.inputStr = '7';
      state.activeKey = '7';
    }
    if (forcedPhase === 'result') {
      state.qIdx = 9; state.answered = 10; state.correct = 8;
      state.lastTap = { correct: true, delta: 2700, answer: 13, given: 13 };
    }
    if (forcedPhase === 'done') {
      state.answered = 10; state.correct = 8;
    }
    if (forcedPhase === 'countdown') {
      state.countdown = 2;
    }
    force();
    // eslint-disable-next-line
  }, [forcedPhase]);

  const startCountdown = () => {
    state.phase = 'countdown';
    state.countdown = 3;
    force();
    const tick = (n) => {
      if (n === 0) { startQuestion(0); return; }
      state.countdown = n; force();
      pushT(() => tick(n - 1), 700);
    };
    pushT(() => tick(3), 100);
  };

  const startQuestion = (i) => {
    clearTimers();
    state.phase = 'play';
    state.qIdx = i;
    state.qStartMs = performance.now();
    state.inputStr = '';
    state.activeKey = null;
    force();
  };

  const onKey = (k) => {
    if (isFrozen || state.phase !== 'play') return;
    state.activeKey = k;
    pushT(() => { if (state.activeKey === k) { state.activeKey = null; force(); } }, 140);
    if (k === 'OK') {
      if (state.inputStr.length > 0) submit(false);
      return;
    }
    if (k === 'DEL') {
      state.inputStr = state.inputStr.slice(0, -1);
      force();
      return;
    }
    if (state.inputStr.length < 2) state.inputStr = state.inputStr + k;
    force();
  };

  const submit = (timeout) => {
    const p = PROBLEMS[state.qIdx];
    const given = parseInt(state.inputStr, 10);
    const correct = !timeout && given === p.sum;
    const delta = Math.round(performance.now() - state.qStartMs);
    if (correct) state.correct++;
    state.history[state.qIdx] = { correct, delta, answer: p.sum, given: timeout ? null : given };
    state.lastTap = state.history[state.qIdx];
    state.answered = state.qIdx + 1;
    state.inputStr = '';
    state.activeKey = null;

    // 短い結果フラッシュ → 次の問題. 最終問題なら done.
    state.phase = 'result';
    force();
    pushT(() => {
      if (state.qIdx >= TOTAL - 1) {
        state.phase = 'done';
      } else {
        startQuestion(state.qIdx + 1);
      }
      force();
    }, 600);
  };

  const onShellTap = (e) => {
    if (isFrozen) return;
    if (state.phase === 'ready') {
      state.qIdx = 0; state.answered = 0; state.correct = 0;
      state.history = [];
      startCountdown();
      return;
    }
    if (state.phase === 'done') {
      state.phase = 'ready'; force(); return;
    }
  };

  // ── values for the play board ──
  const cur = PROBLEMS[state.qIdx] || PROBLEMS[0];
  const elapsed = state.phase === 'play'
    ? Math.min(Q_LIMIT_MS, performance.now() - state.qStartMs)
    : (state.phase === 'result' ? Q_LIMIT_MS * 0.4 : 0);
  const remainSec = Math.max(0, (Q_LIMIT_MS - elapsed) / 1000);
  const tProgress = elapsed / Q_LIMIT_MS;             // 0..1 (時間が進むと 1)
  // ゲージは 残量を左から表示（赤い部分） ∴ width = 1 - tProgress ?
  // キービジュアルでは赤いバーは画面左から catboy 位置までで、catboy が右に進むほど赤が伸びる…
  //   実装: catboy は左→右へスライド. その左側 = 赤いゲージ.
  const catX = tProgress;                              // 0..1

  return (
    <div onClick={onShellTap} style={{
      width, height, position: 'relative', overflow: 'hidden',
      background: T.bgVoid, fontFamily: T.sans, color: T.ink100,
      userSelect: 'none', cursor: isFrozen ? 'default' : 'pointer',
    }}>
      {/* subtle aura + stars */}
      <Aura/>
      <StarLayer/>

      {/* ─── HUD (top bar) ─── */}
      {(state.phase === 'play' || state.phase === 'result') && (
        <TopHud tier={TIER} answered={state.answered} total={TOTAL}/>
      )}

      {/* ─── PLAY ─── */}
      {(state.phase === 'play' || state.phase === 'result') && (
        <PlayBoard
          width={width}
          a={cur.a} b={cur.b}
          inputStr={state.phase === 'result' ? String(state.lastTap?.given ?? '') : state.inputStr}
          activeKey={state.activeKey}
          onKey={onKey}
          catX={catX}
          remainSec={remainSec}
          isResult={state.phase === 'result'}
          lastTap={state.lastTap}
          pulse={state.pulse}
        />
      )}

      {/* ─── READY ─── */}
      {state.phase === 'ready' && <Ready/>}

      {/* ─── COUNTDOWN ─── */}
      {state.phase === 'countdown' && (
        <div key={`cd-${state.countdown}`} style={{
          position: 'absolute', inset: 0, display: 'flex',
          alignItems: 'center', justifyContent: 'center', zIndex: 8,
          fontFamily: T.serif, fontSize: 220, lineHeight: 1, letterSpacing: '-0.02em',
          color: T.cyan300,
          textShadow: `0 0 32px ${T.cyanGlow}, 0 0 80px rgba(111,180,255,0.4)`,
          animation: 'cb-slam 500ms cubic-bezier(.2,.8,.2,1) both',
        }}>
          {state.countdown}
        </div>
      )}

      {/* ─── DONE ─── */}
      {state.phase === 'done' && <Done correct={state.correct} total={TOTAL} history={state.history}/>}

      <style>{`
        @keyframes cb-fade { from{opacity:0} to{opacity:1} }
        @keyframes cb-slam { 0%{transform:scale(0.6);opacity:0} 60%{transform:scale(1.12);opacity:1} 100%{transform:scale(1);opacity:1} }
        @keyframes cb-bob  { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-3px)} }
        @keyframes cb-glow { 0%,100%{filter:drop-shadow(0 0 10px ${T.cyanGlow})} 50%{filter:drop-shadow(0 0 22px ${T.cyanGlow})} }
        @keyframes cb-ringPing { 0%{transform:scale(0.4);opacity:0.7} 100%{transform:scale(1.4);opacity:0} }
        @keyframes cb-cursor { 0%,49%{opacity:1} 50%,100%{opacity:0.15} }
      `}</style>
    </div>
  );
}

// ───────────── HUD ─────────────
function TopHud({ tier, answered, total }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0, height: 44,
      padding: '0 22px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', zIndex: 9,
      fontFamily: T.sans, color: T.ink60,
      fontSize: 13, letterSpacing: '0.06em',
    }}>
      <span style={{ fontFeatureSettings: T.tnum }}>{tier}</span>
      <span style={{ fontFeatureSettings: T.tnum }}>
        <span style={{ color: T.ink100 }}>{answered}</span>
        <span style={{ color: T.ink40, margin: '0 1px' }}>/</span>
        <span>{total}</span>
      </span>
    </div>
  );
}

// ───────────── PLAY BOARD ─────────────
function PlayBoard({ width, a, b, inputStr, activeKey, onKey, catX, remainSec, isResult, lastTap, pulse }) {
  // layout (412×892 想定)
  const PROMPT_TOP   = 90;
  const TIMER_TOP    = 248;
  const DIGITS_TOP   = 320;
  const PAD_TOP      = 480;

  // 入力2桁分割 (キービジュアルは 4 _ 7 _ のような並列). ここでは a,b を表示.
  // しかし答えは 1 桁か2桁. キービジュアルでは「4」「7」が大きく独立した位置に並んでいる.
  //    → これは入力欄ではなく問題の 2 つの数字 (4 + 7 = ?). 暗算で合計を入力する.
  //    入力した値は実質 inputStr で別表示.
  // この実装では: 上に「合計は？」、中央に大きく a と b、下にユーザ入力箱(細い表示)、その下に numpad.
  // ただしキービジュアルに忠実にするため "2 つの数字 4 7" を中央に大きく出す。

  const inA = inputStr.length >= 1 ? inputStr[0] : '';
  const inB = inputStr.length >= 2 ? inputStr[1] : '';

  return (
    <>
      {/* 「合計は？」 明朝 */}
      <div style={{
        position: 'absolute', top: PROMPT_TOP, left: 0, right: 0,
        textAlign: 'center', fontFamily: T.serif, fontWeight: 500,
        fontSize: 84, lineHeight: 1, letterSpacing: '0.04em',
        color: T.ink100,
        textShadow: '0 0 24px rgba(111,180,255,0.18)',
        zIndex: 4,
      }}>
        合計は？
      </div>

      {/* タイマー / catboy ライン */}
      <TimerLane top={TIMER_TOP} catX={catX} remainSec={remainSec} pulse={pulse} isResult={isResult} lastTap={lastTap}/>

      {/* a + b (大きい数字 2 つ. キービジュアル準拠) */}
      <DigitsRow top={DIGITS_TOP} a={a} b={b} input={inputStr} isResult={isResult} lastTap={lastTap}/>

      {/* 数値パッド */}
      <Numpad top={PAD_TOP} active={activeKey} onKey={onKey} disabled={isResult}/>

      {/* 結果オーバーレイ — 短いフラッシュ */}
      {isResult && lastTap && (
        <ResultFlash lastTap={lastTap}/>
      )}
    </>
  );
}

// ───────────── TIMER LANE — 赤いゲージ + catboy ─────────────
function TimerLane({ top, catX, remainSec, pulse, isResult, lastTap }) {
  const LANE_LEFT = 56;
  const LANE_RIGHT = 56;
  const trackW = 412 - LANE_LEFT - LANE_RIGHT;
  const fillW = trackW * Math.min(1, Math.max(0, catX));   // 赤いバー (左→cat)
  const restW = trackW - fillW;                            // 灰色 残り
  const catLeft = LANE_LEFT + fillW;

  // 結果中の色
  const isLose = isResult && lastTap && !lastTap.correct;
  const isWin  = isResult && lastTap && lastTap.correct;
  const fillCol = isWin
    ? `linear-gradient(90deg, ${T.cyan500}, ${T.cyan300})`
    : `linear-gradient(90deg, ${T.red500}, ${T.red400})`;

  return (
    <div style={{ position: 'absolute', top, left: 0, right: 0, height: 80, zIndex: 4 }}>
      {/* track (background — グレー) */}
      <div style={{
        position: 'absolute', top: 38, left: LANE_LEFT, width: trackW, height: 3,
        background: 'rgba(255,255,255,0.10)', borderRadius: 2,
      }}/>
      {/* fill (赤いバー) */}
      <div style={{
        position: 'absolute', top: 38, left: LANE_LEFT, width: fillW, height: 3,
        background: fillCol, borderRadius: 2,
        boxShadow: isWin ? `0 0 10px ${T.cyanGlow}, 0 0 20px ${T.cyanGlow}`
                          : `0 0 10px ${T.redGlow}, 0 0 18px rgba(231,90,90,0.4)`,
      }}/>
      {/* track end caps */}
      <div style={{
        position: 'absolute', top: 36, left: LANE_LEFT - 2, width: 2, height: 7,
        background: T.ink40, borderRadius: 1,
      }}/>
      <div style={{
        position: 'absolute', top: 36, left: 412 - LANE_RIGHT, width: 2, height: 7,
        background: T.ink40, borderRadius: 1,
      }}/>

      {/* catboy electric — 上に乗っている */}
      <div style={{
        position: 'absolute', top: 0, left: catLeft - 32, width: 64, height: 64,
        zIndex: 5, transition: isResult ? 'left 200ms' : 'none',
      }}>
        <img src="catboy_electric.png" alt=""
          style={{
            display: 'block', width: '100%', height: '100%', objectFit: 'contain',
            filter: `drop-shadow(0 0 12px ${T.cyanGlow}) drop-shadow(0 0 22px rgba(111,180,255,0.4))`,
            animation: 'cb-bob 1.6s ease-in-out infinite',
          }}
        />
      </div>

      {/* 残り N.N 秒 — 右下 */}
      <div style={{
        position: 'absolute', top: 50, right: LANE_RIGHT,
        fontSize: 11, color: T.red400, letterSpacing: '0.05em',
        fontFamily: T.sans, fontWeight: 500, fontFeatureSettings: T.tnum,
        textShadow: `0 0 6px ${T.redGlow}`,
      }}>
        残り <span style={{ fontSize: 17, fontWeight: 700, color: T.red400 }}>
          {remainSec.toFixed(1)}
        </span> 秒
      </div>
    </div>
  );
}

// ───────────── DIGITS ROW — a と b の大きい数字 ─────────────
function DigitsRow({ top, a, b, input, isResult, lastTap }) {
  const showAns = isResult && lastTap;
  return (
    <div style={{
      position: 'absolute', top, left: 0, right: 0, height: 130,
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
      gap: 64, zIndex: 4,
    }}>
      <DigitColumn val={a} input={null} placeholder={false}/>
      <DigitColumn val={b} input={null} placeholder={false}/>
    </div>
  );
}
function DigitColumn({ val }) {
  return (
    <div style={{
      width: 96, display: 'flex', flexDirection: 'column', alignItems: 'center',
    }}>
      <div style={{
        fontSize: 96, lineHeight: 1, color: T.ink100,
        fontFamily: T.sans, fontWeight: 300, fontFeatureSettings: T.tnum,
        textShadow: `0 0 16px rgba(111,180,255,0.25)`,
      }}>{val}</div>
      <div style={{
        marginTop: 10, width: 84, height: 1.5,
        background: T.ink60, opacity: 0.85,
      }}/>
    </div>
  );
}

// ───────────── NUMPAD ─────────────
function Numpad({ top, active, onKey, disabled }) {
  // 4 行 × 3 列
  // [7][8][9]
  // [4][5][6]
  // [1][2][3]
  // [⌫][0][OK]
  const rows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['DEL', '0', 'OK'],
  ];
  return (
    <div style={{
      position: 'absolute', top, left: 24, right: 24, zIndex: 5,
      display: 'flex', flexDirection: 'column', gap: 10,
    }}>
      {rows.map((r, ri) => (
        <div key={ri} style={{ display: 'flex', gap: 10 }}>
          {r.map(k => (
            <Key key={k} k={k} active={active === k} onKey={onKey} disabled={disabled}/>
          ))}
        </div>
      ))}
    </div>
  );
}
function Key({ k, active, onKey, disabled }) {
  const isOk  = k === 'OK';
  const isDel = k === 'DEL';
  const isNum = !isOk && !isDel;

  // active = シアンの光 (キービジュアルの 7 と同じ)
  const bg = active
    ? T.bgElev
    : isOk ? 'rgba(120,140,170,0.18)'
    : T.bgElev;
  const border = active
    ? `1.5px solid ${T.cyan400}`
    : isOk ? `1px solid rgba(120,140,170,0.5)`
    : `1px solid rgba(111,180,255,0.18)`;
  const color = active ? T.cyan300 : (isOk ? T.ink60 : T.ink100);
  const shadow = active
    ? `0 0 16px ${T.cyanGlow}, 0 0 32px rgba(111,180,255,0.35), inset 0 0 0 1px ${T.cyan400}`
    : `0 2px 0 rgba(0,0,0,0.6), 0 0 0 1px rgba(111,180,255,0.10) inset`;

  return (
    <button
      onClick={(e) => { e.stopPropagation(); if (!disabled) onKey(k); }}
      style={{
        flex: 1, height: 64,
        background: bg, border, color,
        borderRadius: 14,
        fontFamily: isNum ? T.sans : T.sans,
        fontWeight: 400, fontSize: isNum ? 28 : 18,
        fontFeatureSettings: T.tnum, letterSpacing: '0.02em',
        boxShadow: shadow,
        cursor: disabled ? 'default' : 'pointer',
        transition: 'all 80ms ease-out',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        textShadow: active ? `0 0 8px ${T.cyanGlow}` : 'none',
      }}
    >
      {isDel ? <BackspaceIcon color={color}/> : k}
    </button>
  );
}
function BackspaceIcon({ color }) {
  return (
    <svg width="24" height="18" viewBox="0 0 24 18" fill="none">
      <path d="M8 1H21A2 2 0 0 1 23 3V15A2 2 0 0 1 21 17H8L1 9 L8 1Z"
            stroke={color} strokeWidth="1.4" strokeLinejoin="round" fill="none"/>
      <path d="M11 6 L17 12 M17 6 L11 12" stroke={color} strokeWidth="1.4" strokeLinecap="round"/>
    </svg>
  );
}

// ───────────── RESULT flash ─────────────
function ResultFlash({ lastTap }) {
  const ok = lastTap.correct;
  return (
    <div style={{
      position: 'absolute', top: 280, left: 0, right: 0,
      textAlign: 'center', zIndex: 9, pointerEvents: 'none',
      animation: 'cb-fade 220ms ease-out both',
    }}>
      <div style={{
        fontFamily: T.serif, fontSize: 120, lineHeight: 1, fontWeight: 600,
        color: ok ? T.cyan300 : T.red400,
        textShadow: ok
          ? `0 0 28px ${T.cyanGlow}, 0 0 60px rgba(111,180,255,0.4)`
          : `0 0 22px ${T.redGlow}`,
        animation: 'cb-slam 320ms cubic-bezier(.2,.8,.2,1) both',
      }}>
        {ok ? '○' : '×'}
      </div>
      <div style={{
        marginTop: -8, fontFamily: T.serif, fontSize: 18,
        color: T.ink80, letterSpacing: '0.16em',
      }}>
        答え&nbsp;
        <span style={{ color: T.ink100, fontFeatureSettings: T.tnum, fontSize: 22 }}>
          {lastTap.answer}
        </span>
        {!ok && lastTap.given != null && (
          <span style={{ color: T.red400, marginLeft: 10, fontFeatureSettings: T.tnum }}>
            （{lastTap.given}）
          </span>
        )}
      </div>
    </div>
  );
}

// ───────────── READY ─────────────
function Ready() {
  return (
    <>
      <div style={{
        position: 'absolute', top: 70, left: 22,
        fontSize: 11, color: T.cyan400, letterSpacing: '0.5em',
        textShadow: `0 0 8px ${T.cyanGlow}`, fontWeight: 700,
      }}>
        BRAIN-GHOST · CALC
      </div>

      <div style={{
        position: 'absolute', top: 130, left: 24, right: 24,
        textAlign: 'left', zIndex: 4,
      }}>
        <div style={{
          fontFamily: T.serif, fontSize: 56, lineHeight: 1.1,
          color: T.ink100, letterSpacing: '0.02em',
        }}>
          暗算で、<br/>
          昨日の自分を<br/>
          超えろ。
        </div>
        <div style={{
          fontFamily: T.serif, fontSize: 14, marginTop: 24,
          color: T.ink80, lineHeight: 1.8,
        }}>
          二桁までの足し算を 10 問。<br/>
          1 問 5 秒、合計 50 秒で勝負。
        </div>
      </div>

      {/* mascot */}
      <div style={{
        position: 'absolute', bottom: 200, left: 0, right: 0,
        display: 'flex', justifyContent: 'center', zIndex: 4,
      }}>
        <img src="catboy_confident.png" alt=""
          style={{
            width: 220, height: 'auto', display: 'block',
            filter: `drop-shadow(0 0 22px ${T.cyanGlow}) drop-shadow(0 18px 36px rgba(0,0,0,0.6))`,
            animation: 'cb-bob 3.2s ease-in-out infinite',
          }}
        />
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', bottom: 80, left: 0, right: 0,
        display: 'flex', justifyContent: 'center', zIndex: 5,
      }}>
        <div style={{
          padding: '14px 44px', borderRadius: 999,
          border: `1.5px solid ${T.cyan400}`,
          color: T.cyan300, fontSize: 13, letterSpacing: '0.32em', fontWeight: 700,
          boxShadow: `0 0 18px ${T.cyanGlow}, inset 0 0 0 1px rgba(111,180,255,0.2)`,
          fontFamily: T.sans,
          animation: 'cb-glow 2s ease-in-out infinite',
        }}>
          TAP で 開始
        </div>
      </div>
    </>
  );
}

// ───────────── DONE ─────────────
function Done({ correct, total, history }) {
  const playerWon = correct >= Math.ceil(total * 0.7);
  const isPerfect = correct === total;
  const headColor = isPerfect ? T.gold400 : playerWon ? T.cyan300 : T.ink80;
  const headGlow  = isPerfect ? T.goldGlow : playerWon ? T.cyanGlow : T.redGlow;
  const sprite = isPerfect ? 'catboy_energetic.png' : playerWon ? 'catboy_confident.png' : 'catboy_electric.png';

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 5,
      animation: 'cb-fade 400ms ease-out both',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      paddingTop: 80, paddingBottom: 60,
    }}>
      <div style={{ fontSize: 11, letterSpacing: '0.5em', color: T.cyan400, textShadow: `0 0 8px ${T.cyanGlow}` }}>
        決&nbsp;着
      </div>
      <div style={{
        marginTop: 10,
        fontFamily: T.serif, fontSize: 56, fontWeight: 600,
        color: headColor, lineHeight: 1, letterSpacing: '0.04em',
        textShadow: `0 0 28px ${headGlow}, 0 0 60px ${headGlow}`,
        animation: 'cb-slam 480ms cubic-bezier(.2,.8,.2,1) both',
      }}>
        {isPerfect ? 'PERFECT' : playerWon ? 'WIN' : 'LOSE'}
      </div>

      {/* score */}
      <div style={{
        marginTop: 20, fontFamily: T.serif,
        display: 'flex', alignItems: 'baseline', gap: 14, fontFeatureSettings: T.tnum,
      }}>
        <span style={{
          fontSize: 100, lineHeight: 1, color: headColor,
          textShadow: `0 0 28px ${headGlow}`,
        }}>{correct}</span>
        <span style={{ fontSize: 28, color: T.ink40 }}>／</span>
        <span style={{ fontSize: 60, color: T.ink60 }}>{total}</span>
      </div>
      <div style={{
        fontSize: 11, letterSpacing: '0.4em', color: T.ink60, marginTop: 6,
      }}>
        正答数
      </div>

      {/* mascot */}
      <div style={{ marginTop: 24, position: 'relative' }}>
        <img src={sprite} alt=""
          style={{
            width: 200, height: 'auto', display: 'block',
            filter: `drop-shadow(0 0 22px ${headGlow}) drop-shadow(0 18px 36px rgba(0,0,0,0.6))`,
            animation: 'cb-bob 2.6s ease-in-out infinite',
          }}
        />
      </div>

      {/* dots */}
      <div style={{ marginTop: 18, display: 'flex', gap: 6 }}>
        {Array.from({ length: total }).map((_, i) => {
          const h = history[i];
          if (!h) return <span key={i} style={{ width: 10, height: 10, borderRadius: '50%', border: `1.5px solid ${T.ink40}` }}/>;
          if (h.correct) return <span key={i} style={{ width: 10, height: 10, borderRadius: '50%', background: T.cyan400, boxShadow: `0 0 6px ${T.cyanGlow}` }}/>;
          return <span key={i} style={{ width: 10, height: 10, color: T.red400, fontFamily: T.serif, fontSize: 13, lineHeight: 1, textAlign: 'center', textShadow: `0 0 6px ${T.redGlow}` }}>×</span>;
        })}
      </div>

      <div style={{
        marginTop: 'auto', fontFamily: T.serif, fontSize: 16,
        color: T.ink80, textAlign: 'center', lineHeight: 1.7,
      }}>
        {isPerfect ? '昨日の自分を、超えた。' : playerWon ? '一閃、合格。' : 'もう一歩。'}
      </div>
      <div style={{
        marginTop: 12, fontSize: 10, letterSpacing: '0.4em', color: T.ink60,
      }}>
        TAP で もう一度
      </div>
    </div>
  );
}

// ───────────── BG layers ─────────────
function Aura() {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none',
      background: 'radial-gradient(ellipse 70% 40% at 50% 32%, rgba(111,180,255,0.08) 0%, transparent 70%)',
    }}/>
  );
}
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
      opacity: 0.55,
    }}/>
  );
}

window.CalcVariantA = CalcVariantA;
