// app.jsx — B案のみを大きく表示。

function Root() {
  return (
    <DesignCanvas minScale={0.3} maxScale={2.5} initialScale={0.78} initialX={40} initialY={20}>
      <DCSection
        title="ゴースト7番勝負 — 反射タップ（B案）"
        subtitle="Landscape 892×412 · 上＝自分レーン／下＝ゴーストレーン · タップで遊べます"
      >
        <DCArtboard label="B · Cinematic — 2レーン並走" width={892} height={412}>
          <ReflexVariantB />
        </DCArtboard>

        <DCPostIt top={-60} right={20} rotate={2} width={280}>
          上レーンが自分、下レーンがゴースト。<br/>
          同じターゲットで GHOST LINE を<br/>
          同時に走り、早くタップした方が勝ち。
        </DCPostIt>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<Root />);
