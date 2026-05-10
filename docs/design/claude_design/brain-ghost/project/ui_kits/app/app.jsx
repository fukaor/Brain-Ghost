// app.jsx — main controller; mounts device frame + router
const { useState } = React;

function App() {
  const [screen, setScreen] = useState('home'); // home | select | play | result
  const [tab, setTab] = useState('home');

  let content;
  if (screen === 'home')   content = <HomeScreen onStart={() => setScreen('select')} onPick={() => setScreen('select')} />;
  if (screen === 'select') content = <GameSelectScreen onBack={() => setScreen('home')} onPick={() => setScreen('play')} />;
  if (screen === 'play')   content = <ReactGameScreen onBack={() => setScreen('select')} onEnd={() => setScreen('result')} />;
  if (screen === 'result') content = <ResultScreen onHome={() => { setScreen('home'); setTab('home'); }} />;

  return (
    <div style={{
      minHeight: '100vh',
      padding: 24,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: '#F1F5F9',
      fontFamily: '"Zen Maru Gothic", "Hiragino Maru Gothic ProN", "Rounded M+ 1c", system-ui, sans-serif',
    }}>
      <AndroidDevice width={412} height={870}>
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: '#F7F5FF' }}>
          <div style={{ flex: 1, overflow: 'auto' }}>{content}</div>
          <BottomNav active={tab} onChange={(t) => { setTab(t); if (t === 'home') setScreen('home'); if (t === 'train') setScreen('select'); }} />
        </div>
      </AndroidDevice>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
