// components.jsx — Brain Ghost mobile UI kit atoms & clusters
// Loaded after android-frame.jsx. Exports to window for cross-script scope.

const BG_FG1 = '#232C51';
const BG_FG2 = '#505A81';
const BG_FG3 = '#A2ABD7';
const BG_BLUE = '#0058BA';
const BG_DIM = '#004DA4';
const BG_GOLD = '#FACC15';
const BG_GREEN = '#22C55E';
const BG_BG = '#F7F5FF';
const BG_CARD = '#FFFFFF';
const BG_SURFACE_LOW = '#EFEFFF';
const BG_CONTAINER = '#E4E7FF';

// Material Symbols icon span
function Icon({ name, size = 24, color = BG_FG2, fill = 0, weight = 500 }) {
  return (
    <span style={{
      fontFamily: 'Material Symbols Rounded',
      fontVariationSettings: `"FILL" ${fill}, "wght" ${weight}, "GRAD" 0, "opsz" 24`,
      fontSize: size,
      color,
      lineHeight: 1,
      userSelect: 'none',
      display: 'inline-block',
      verticalAlign: 'middle',
    }}>{name}</span>
  );
}

// HUD pill — rounded white chip with icon + value + unit
function HudPill({ icon, value, unit, iconColor = BG_GOLD, flex }) {
  return (
    <div style={{
      flex,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      padding: '14px 18px',
      background: 'rgba(255,255,255,0.85)',
      borderRadius: 9999,
      boxShadow: '0 2px 8px rgba(0,0,0,0.08), inset 0 1px 0 rgba(255,255,255,0.9)',
    }}>
      {icon && <Icon name={icon} size={20} color={iconColor} fill={1} />}
      <span style={{ fontSize: 24, color: BG_FG1, lineHeight: 1 }}>{value}</span>
      {unit && <span style={{ fontSize: 14, color: BG_FG3 }}>{unit}</span>}
    </div>
  );
}

// Battle pill — split win/loss bar
function BattlePill({ wins, losses }) {
  const total = wins + losses || 1;
  return (
    <div style={{
      flex: 1,
      padding: '10px 14px',
      background: 'rgba(255,255,255,0.85)',
      borderRadius: 22,
      boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
      display: 'flex', flexDirection: 'column', gap: 6,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
        <Icon name="swords" size={18} color={BG_FG2} />
        <span style={{ fontSize: 14, color: BG_FG2 }}>ゴーストバトル</span>
      </div>
      <div style={{ display: 'flex', height: 22, borderRadius: 11, overflow: 'hidden' }}>
        <div style={{
          flex: wins / total,
          background: BG_GREEN, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, lineHeight: 1,
        }}>{wins}勝</div>
        <div style={{
          flex: losses / total,
          background: '#94A3B8', color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, lineHeight: 1,
        }}>{losses}敗</div>
      </div>
    </div>
  );
}

// Speech bubble with upward tail
function SpeechBubble({ children, tailOffset = 180 }) {
  return (
    <div style={{ position: 'relative', padding: '0 4px' }}>
      <div style={{
        background: '#fff',
        borderRadius: 20,
        padding: '18px 20px',
        boxShadow: '0 3px 10px rgba(0,0,0,0.15)',
        fontSize: 20,
        color: BG_FG1,
        textAlign: 'center',
        lineHeight: 1.4,
      }}>{children}</div>
      {/* Tail pointing up (toward ghost, which is centered above) */}
      <svg width="24" height="14" viewBox="0 0 24 14" style={{
        position: 'absolute', top: -12, left: tailOffset,
      }}>
        <path d="M12 0 L0 14 L24 14 Z" fill="#fff" />
      </svg>
    </div>
  );
}

// Ability grid cell — icon + label, tappable, with hitodama for played games
function AbilityCell({ label, icon, level, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      border: 0, background: active ? BG_CONTAINER : 'transparent',
      borderRadius: 14, padding: '12px 4px',
      cursor: 'pointer',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      minHeight: 92,
      transition: 'background 120ms',
    }}>
      <div style={{ position: 'relative', width: 56, height: 56 }}>
        <img src={`assets/hitodama_lv${level}.png`} alt=""
          style={{ width: 56, height: 56, position: 'absolute', inset: 0 }} />
        <Icon name={icon} size={28} color={BG_FG1}
          style={{ position: 'absolute', left: 14, top: 14 }} />
      </div>
      <div style={{ fontSize: 14, color: BG_FG1 }}>{label}</div>
    </button>
  );
}

// Ability card block
function AbilityCard({ abilities, onPick }) {
  return (
    <div style={{
      background: 'rgba(255,255,255,0.75)',
      borderRadius: 28,
      padding: '20px 18px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
        <Icon name="analytics" size={28} color={BG_BLUE} fill={1} />
        <div style={{ fontSize: 20, color: BG_FG1 }}>あなたの脳の得意分野</div>
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 8,
      }}>
        {abilities.map(a => (
          <AbilityCell key={a.key} {...a} onClick={() => onPick && onPick(a.key)} />
        ))}
      </div>
    </div>
  );
}

// Primary CTA — 3D blue button
function PrimaryCTA({ icon, children, onClick, disabled }) {
  const [pressed, setPressed] = React.useState(false);
  const active = pressed && !disabled;
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        width: '100%',
        border: 0,
        background: disabled ? '#E2E8F0' : (active ? BG_DIM : BG_BLUE),
        color: disabled ? '#94A3B8' : '#F0F2FF',
        fontFamily: 'inherit', fontWeight: 700,
        fontSize: 26,
        padding: '20px 24px',
        borderRadius: 28,
        boxShadow: disabled ? 'none' : (active
          ? '0 1px 0 ' + BG_DIM + ', 0 2px 6px rgba(0,0,0,0.15)'
          : '0 5px 0 ' + BG_DIM + ', 0 8px 16px rgba(0,0,0,0.18)'),
        transform: active ? 'translateY(4px)' : 'translateY(0)',
        transition: 'transform 80ms, background 80ms, box-shadow 80ms',
        cursor: disabled ? 'not-allowed' : 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 14,
      }}
    >
      {icon && <Icon name={icon} size={36} color="#F0F2FF" />}
      {children}
    </button>
  );
}

// Bottom nav — 5 tabs, active pill
function BottomNav({ active, onChange }) {
  const tabs = [
    { key: 'train', icon: 'psychology', label: '脳トレ' },
    { key: 'analytics', icon: 'analytics', label: '分析' },
    { key: 'home', icon: 'home', label: 'ホーム' },
    { key: 'award', icon: 'emoji_events', label: 'アワード' },
    { key: 'settings', icon: 'settings', label: '設定' },
  ];
  return (
    <div style={{
      background: 'rgba(255,255,255,0.95)',
      borderTopLeftRadius: 32, borderTopRightRadius: 32,
      padding: '8px 8px 16px',
      boxShadow: '0 -2px 12px rgba(0,0,0,0.06)',
      display: 'flex', gap: 4,
    }}>
      {tabs.map(t => {
        const isActive = t.key === active;
        return (
          <button key={t.key} onClick={() => onChange && onChange(t.key)} style={{
            flex: 1, border: 0, background: isActive ? BG_BLUE : 'transparent',
            borderRadius: 20, padding: '8px 4px',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            cursor: 'pointer',
          }}>
            <Icon name={t.icon} size={26} color={isActive ? '#fff' : 'rgba(80,90,129,0.7)'} fill={isActive ? 1 : 0} />
            <div style={{ fontSize: 12, color: isActive ? '#fff' : 'rgba(80,90,129,0.7)' }}>{t.label}</div>
          </button>
        );
      })}
    </div>
  );
}

// Page background — gradient sky (matches real home.tscn)
function PageBg({ children }) {
  return (
    <div style={{
      position: 'relative',
      minHeight: '100%',
      background: 'radial-gradient(ellipse at 50% 50%, #E0F2FE 0%, #BAE6FD 55%, #7DD3FC 100%)',
      overflow: 'hidden',
    }}>{children}</div>
  );
}

Object.assign(window, {
  Icon, HudPill, BattlePill, SpeechBubble, AbilityCard, AbilityCell,
  PrimaryCTA, BottomNav, PageBg,
  BG_FG1, BG_FG2, BG_FG3, BG_BLUE, BG_DIM, BG_GOLD, BG_GREEN, BG_BG, BG_CARD, BG_SURFACE_LOW, BG_CONTAINER,
});
