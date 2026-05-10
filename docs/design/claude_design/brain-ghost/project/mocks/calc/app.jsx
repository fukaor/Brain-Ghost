// app.jsx — calc / Midnight Cat 版

const PHASES = [
  { id: 'ready',     label: '01 開始画面' },
  { id: 'countdown', label: '02 カウント' },
  { id: 'play',      label: '03 出題＋入力' },
  { id: 'result',    label: '04 ○×' },
  { id: 'done',      label: '05 決着' },
];

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "showStaticFrames": true
}/*EDITMODE-END*/;

function Root() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);

  return (
    <>
      <DesignCanvas minScale={0.15} maxScale={2.2} initialScale={0.55} initialX={40} initialY={40}>

        <DCSection
          title="ゴースト計算 — Midnight Cat 版"
          subtitle="新DS適用 · 412×892 · 実際にタップして遊べます"
        >
          <DCArtboard label="インタラクティブ — 全フェーズ通しで遊べる" width={412} height={892}>
            <CalcVariantA />
          </DCArtboard>

          <DCPostIt top={-72} right={40} rotate={-2} width={300}>
            キービジュアル準拠：<br/>
            黒地・明朝の「合計は？」<br/>
            赤い残時間ゲージに <b>catboy_electric</b><br/>
            シアン光のアクティブキー。
          </DCPostIt>
        </DCSection>

        {tweaks.showStaticFrames && (
          <DCSection
            title="フェーズ別フレーム"
            subtitle="各場面を静止状態で確認 · 左から時系列順"
          >
            {PHASES.map(p => (
              <DCArtboard key={p.id} label={p.label} width={412} height={892}>
                <CalcVariantA phase={p.id}/>
              </DCArtboard>
            ))}
          </DCSection>
        )}

      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="表示">
          <TweakToggle
            label="フェーズ別の静止フレーム"
            value={tweaks.showStaticFrames}
            onChange={v => setTweak('showStaticFrames', v)}
          />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<Root />);
