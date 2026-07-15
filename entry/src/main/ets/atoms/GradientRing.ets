// ============================================================================
//  components/GradientRing.ets — 渐变进度环原子组件
//  ----------------------------------------------------------------------------
//  职责: Canvas 绘制 MINT→PURPLE 渐变圆弧 + 光晕呼吸动画。
//  来源: 从 HomePage.ets 抽取。
//  ============================================================================

import { MINT, PURPLE } from "common"

@Component
export struct GradientRing {
  @Prop pct: number = 75
  @State animPct: number = 0
  @State glow: number = 0.45
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private fillTimerId: number = -1
  private glowTimerId: number = -1
  private glowDir: number = 1

  aboutToAppear(): void {
    const startTs: number = Date.now()
    const duration: number = 1400
    this.fillTimerId = setInterval((): void => {
      const elapsed: number = Date.now() - startTs
      const t: number = Math.min(1, elapsed / duration)
      const eased: number = 1 - Math.pow(1 - t, 3)
      this.animPct = this.pct * eased
      this.draw()
      if (t >= 1) {
        clearInterval(this.fillTimerId)
        this.fillTimerId = -1
      }
    }, 16)

    this.glowTimerId = setInterval((): void => {
      this.glow = this.glow + this.glowDir * 0.020
      if (this.glow >= 0.80) { this.glow = 0.80; this.glowDir = -1 }
      if (this.glow <= 0.30) { this.glow = 0.30; this.glowDir = 1 }
    }, 30)
  }

  aboutToDisappear(): void {
    if (this.fillTimerId !== -1) {
      clearInterval(this.fillTimerId)
      this.fillTimerId = -1
    }
    if (this.glowTimerId !== -1) {
      clearInterval(this.glowTimerId)
      this.glowTimerId = -1
    }
  }

  build() {
    Stack() {
      Circle({ width: 104, height: 104 })
        .fill("#00000000")
        .stroke("#0FFFFFFF")
        .strokeWidth(10)

      Canvas(this.ctx)
        .width(120).height(120)
        .onReady((): void => {
          this.draw()
        })
    }
    .width(120).height(120)
    .borderRadius(60)
    .clip(true)
    .shadow({
      radius: 32,
      color: "rgba(91, 227, 176, " + this.glow.toFixed(2) + ")",
      offsetX: 0,
      offsetY: 0,
    })
  }

  draw(): void {
    const ctx: CanvasRenderingContext2D = this.ctx
    const cx: number = 60
    const cy: number = 60
    const r: number = 52
    const lw: number = 10

    ctx.clearRect(0, 0, 120, 120)

    const grad: CanvasGradient = ctx.createLinearGradient(0, 0, 120, 120)
    grad.addColorStop(0, MINT)
    grad.addColorStop(1, PURPLE)

    const start: number = -Math.PI / 2
    const sweep: number = (this.animPct / 100) * 2 * Math.PI

    ctx.beginPath()
    ctx.arc(cx, cy, r, start, start + sweep)
    ctx.strokeStyle = grad
    ctx.lineWidth = lw
    ctx.lineCap = "round"
    ctx.stroke()
  }
}
