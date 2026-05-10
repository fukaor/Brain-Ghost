// screens.jsx — Brain Ghost mobile screens
// depends on components.jsx (loaded before)

function HomeScreen({ onStart, onPick }) {
  const abilities = [
    { key: 'reason', label: '論理思考', icon: 'extension', level: 3, active: false },
    { key: 'memory', label: '記憶力',   icon: 'menu_book',  level: 4, active: false },
    { key: 'calc',   label: '計算力',   icon: 'calculate',  level: 2, active: false },
    { key: 'react',  label: '反射力',   icon: 'bolt',       level: 5, active: true  },
    { key: 'vocab',  label: '語彙力',   icon: 'translate',  level: 3, active: false },
    { key: 'percep', label: '知覚力',   icon: 'visibility', level: 2, active: false },
  ];
  return (
    <PageBg>
      {/* top padding for app bar absence */}
      <div style={{ padding: '16px 16px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* HUD row: brain age + battle pill */}
        <div style={{ display: 'flex', gap: 10 }}>
          <HudPill icon="psychology" iconColor="#F59E0B" value="28" unit="歳" />
          <BattlePill wins={12} losses={3} />
        </div>
        {/* Ghost + speech */}
        <div style={{ position: 'relative', paddingTop: 4 }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
            <img src="assets/ghost_seirei.png" alt="Ghost" style={{
              width: 160, height: 'auto', filter: 'drop-shadow(0 6px 12px rgba(0,0,0,0.15))',
              animation: 'ghostFloat 3s ease-in-out infinite',
            }} />
          </div>
          <SpeechBubble tailOffset={175}>
            今日も脳を鍛えましょう！<br/>
            反射力がグングン伸びていますよ
          </SpeechBubble>
        </div>
        {/* Ability grid */}
        <AbilityCard abilities={abilities} onPick={onPick} />
        {/* CTA */}
        <PrimaryCTA icon="play_arrow" onClick={onStart}>はじめる</PrimaryCTA>
        <div style={{ height: 8 }} />
      </div>
      <style>{`
        @keyframes ghostFloat {
          0%,100% { transform: translateY(0); }
          50% { transform: translateY(-8px); }
        }
      `}</style>
    </PageBg>
  );
}

// Game select screen — pick one of the six abilities to train
function GameSelectScreen({ onPick, onBack }) {
  const games = [
    { key: 'reason', label: '論理思考', desc: '数列パズル',     icon: 'extension',  color: '#8B5CF6' },
    { key: 'memory', label: '記憶力',   desc: 'カード記憶',     icon: 'menu_book',  color: '#EC4899' },
    { key: 'calc',   label: '計算力',   desc: 'スピード暗算',   icon: 'calculate',  color: '#F59E0B' },
    { key: 'react',  label: '反射力',   desc: 'タップチャレンジ', icon: 'bolt',      color: '#EF4444' },
    { key: 'vocab',  label: '語彙力',   desc: '漢字クイズ',     icon: 'translate',  color: '#10B981' },
    { key: 'percep', label: '知覚力',   desc: '違い探し',       icon: 'visibility', color: '#0EA5E9' },
  ];
  return (
    <PageBg>
      <div style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <button onClick={onBack} style={{
            border: 0, background: 'rgba(255,255,255,0.85)', width: 40, height: 40,
            borderRadius: 20, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
          }}>
            <Icon name="arrow_back" size={22} color={BG_FG1} />
          </button>
          <div style={{ fontSize: 22, color: BG_FG1 }}>脳トレを選ぶ</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {games.map(g => (
            <button key={g.key} onClick={() => onPick(g.key)} style={{
              border: 0, background: '#fff', borderRadius: 20, padding: '18px 14px',
              boxShadow: '0 3px 10px rgba(0,0,0,0.08)', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-start',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 22,
                background: g.color + '22',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                marginBottom: 4,
              }}>
                <Icon name={g.icon} size={26} color={g.color} fill={1} />
              </div>
              <div style={{ fontSize: 18, color: BG_FG1, lineHeight: 1 }}>{g.label}</div>
              <div style={{ fontSize: 13, color: BG_FG3 }}>{g.desc}</div>
            </button>
          ))}
        </div>
      </div>
    </PageBg>
  );
}

// Game play screen — react-tap mini game
function ReactGameScreen({ onEnd, onBack }) {
  const [state, setState] = React.useState('waiting'); // waiting | go | tapped
  const [ms, setMs] = React.useState(0);
  const startRef = React.useRef(0);
  const timerRef = React.useRef(null);

  React.useEffect(() => {
    if (state === 'waiting') {
      const delay = 1200 + Math.random() * 1800;
      timerRef.current = setTimeout(() => {
        setState('go');
        startRef.current = performance.now();
      }, delay);
    }
    return () => clearTimeout(timerRef.current);
  }, [state]);

  const onTap = () => {
    if (state === 'waiting') {
      setState('early');
    } else if (state === 'go') {
      setMs(Math.round(performance.now() - startRef.current));
      setState('tapped');
    }
  };

  const reset = () => { setState('waiting'); setMs(0); };

  return (
    <PageBg>
      <div style={{ padding: 16, height: '100%', display: 'flex', flexDirection: 'column' }}>
        {/* header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <button onClick={onBack} style={{
            border: 0, background: 'rgba(255,255,255,0.85)', width: 40, height: 40,
            borderRadius: 20, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
          }}>
            <Icon name="arrow_back" size={22} color={BG_FG1} />
          </button>
          <div style={{ fontSize: 20, color: BG_FG1 }}>反射力チャレンジ</div>
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="bolt" size={20} color="#EF4444" fill={1} />
            <span style={{ fontSize: 16, color: BG_FG2 }}>Round 3/5</span>
          </div>
        </div>
        {/* play surface */}
        <button onClick={onTap} style={{
          flex: 1, border: 0, borderRadius: 28, cursor: 'pointer',
          background: state === 'go' ? '#22C55E'
            : state === 'tapped' ? '#3B82F6'
            : state === 'early' ? '#EF4444'
            : 'rgba(255,255,255,0.7)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          gap: 14, color: state === 'waiting' ? BG_FG1 : '#fff',
          boxShadow: '0 6px 16px rgba(0,0,0,0.12)',
          transition: 'background 120ms',
        }}>
          {state === 'waiting' && (<>
            <Icon name="pan_tool" size={64} color={BG_FG2} />
            <div style={{ fontSize: 22 }}>緑になったらタップ</div>
          </>)}
          {state === 'go' && (<>
            <Icon name="touch_app" size={80} color="#fff" fill={1} />
            <div style={{ fontSize: 32, fontWeight: 700 }}>いま！</div>
          </>)}
          {state === 'tapped' && (<>
            <Icon name="check_circle" size={64} color="#fff" fill={1} />
            <div style={{ fontSize: 36, fontWeight: 700 }}>{ms} ms</div>
            <div style={{ fontSize: 16, opacity: 0.9 }}>ナイスリアクション！</div>
          </>)}
          {state === 'early' && (<>
            <Icon name="warning" size={64} color="#fff" fill={1} />
            <div style={{ fontSize: 24, fontWeight: 700 }}>早すぎ！</div>
          </>)}
        </button>
        {(state === 'tapped' || state === 'early') && (
          <div style={{ marginTop: 12, display: 'flex', gap: 10 }}>
            <button onClick={reset} style={{
              flex: 1, border: 0, borderRadius: 18, padding: '14px',
              background: '#fff', color: BG_FG1, fontSize: 18, fontFamily: 'inherit',
              cursor: 'pointer', fontWeight: 700,
            }}>もう一度</button>
            <button onClick={onEnd} style={{
              flex: 1, border: 0, borderRadius: 18, padding: '14px',
              background: BG_BLUE, color: '#fff', fontSize: 18, fontFamily: 'inherit',
              cursor: 'pointer', fontWeight: 700,
            }}>結果を見る</button>
          </div>
        )}
      </div>
    </PageBg>
  );
}

// Result screen — brain age reveal + hitodama badge
function ResultScreen({ onHome }) {
  return (
    <PageBg>
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20, paddingTop: 30 }}>
        <div style={{ fontSize: 18, color: BG_FG2 }}>今日の脳年齢</div>
        <div style={{
          width: 220, height: 220, borderRadius: '50%',
          background: 'radial-gradient(circle at 30% 30%, #fff, #DBEAFE 70%, #93C5FD)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 10px 30px rgba(59,130,246,0.35)',
        }}>
          <div style={{ fontSize: 80, fontWeight: 700, color: BG_FG1, lineHeight: 1 }}>26</div>
          <div style={{ fontSize: 18, color: BG_FG2 }}>歳</div>
        </div>
        <div style={{
          padding: '10px 18px', background: 'rgba(255,255,255,0.9)', borderRadius: 20,
          display: 'flex', alignItems: 'center', gap: 8,
          boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
        }}>
          <Icon name="trending_down" size={20} color={BG_GREEN} fill={1} />
          <span style={{ fontSize: 16, color: BG_FG1 }}>前回から 2歳 若返り！</span>
        </div>
        <div style={{ width: '100%', background: 'rgba(255,255,255,0.8)', borderRadius: 24, padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ fontSize: 16, color: BG_FG2 }}>獲得したヒトダマ</div>
          <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
            {[1,2,3,4,5].map(l => (
              <img key={l} src={`assets/hitodama_lv${l}.png`} style={{ width: 44, height: 44, opacity: l <= 3 ? 1 : 0.3 }} />
            ))}
          </div>
        </div>
        <div style={{ width: '100%' }}>
          <PrimaryCTA icon="home" onClick={onHome}>ホームに戻る</PrimaryCTA>
        </div>
      </div>
    </PageBg>
  );
}

Object.assign(window, { HomeScreen, GameSelectScreen, ReactGameScreen, ResultScreen });
