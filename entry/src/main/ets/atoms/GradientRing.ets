// ============================================================================
//  components/GradientRing.ets — 渐变进度环原子组件
//  ----------------------------------------------------------------------------
//  职责: Canvas 绘制 MINT→PURPLE 渐变圆弧。
//  来源: 从 HomePage.ets 抽取。
//  ============================================================================

import { MINT, PURPLE } from "common"

@Component
export struct GradientRing {
  @Prop pct: number = 75
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  build() {
    Stack() {
      Circle({ width: 104, height: 104 })
        .fill("#00FFFFFF")
        .stroke("#10FFFFFF")
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
      color: "rgba(91, 227, 176, 0.45)",
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
    const sweep: number = (this.pct / 100) * 2 * Math.PI

    ctx.beginPath()
    ctx.arc(cx, cy, r, start, start + sweep)
    ctx.strokeStyle = grad
    ctx.lineWidth = lw
    ctx.lineCap = "round"
    ctx.stroke()
  }
}
