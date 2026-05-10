// app.jsx — B案のみを大きく表示。

function Root() {
  return (
    <DesignCanvas minScale={0.3} maxScale={2.5} initialScale={0.78} initialX={40} initialY={20}>
      <DCSection
        title="ゴースト7番勝負 — 反射タップ"
        subtitle="新DS Midnight Cat 適用版 · 横長 892×412 · タップで遊べます"
      >
        <DCArtboard label="2レーン並走 · 黒地ネオン" width={892} height={412}>
          <ReflexVariantB />
        </DCArtboard>

        <DCPostIt top={-60} right={20} rotate={2} width={300}>
          上＝自分／下＝ゴースト。<br/>
          中央の光る GHOST LINE を<br/>
          ゴーストより先にタップで勝利。
        </DCPostIt>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<Root />);
