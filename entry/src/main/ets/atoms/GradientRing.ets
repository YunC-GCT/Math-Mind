// ============================================================================
//  components/GradientRing.ets — 渐变进度环原子组件
//  ----------------------------------------------------------------------------
//  职责: Canvas 绘制 MINT→PURPLE 渐变圆弧 + 光晕呼吸动画。
//  来源: 从 HomePage.ets 抽取。
//  ============================================================================

import { MINT, PURPLE, HERO_RING_SIZE } from "common"


const RING_SIZE: number = HERO_RING_SIZE       // 120
const RING_STROKE: number = 10
const RING_CENTER: number = RING_SIZE / 2       // 60
const RING_BG: number = RING_SIZE - RING_STROKE * 2 + 4  // 104
const RING_RADIUS: number = RING_BG / 2          // 52
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
      Circle({ width: RING_BG, height: RING_BG })
        .fill("#00FFFFFF")
        .stroke("#10FFFFFF")
        .strokeWidth(RING_STROKE)

      Canvas(this.ctx)
        .width(RING_SIZE).height(RING_SIZE)
        .onReady((): void => {
          this.draw()
        })
    }
    .width(RING_SIZE).height(RING_SIZE)
    .borderRadius(RING_CENTER)
    .clip(true)
    .shadow({
      radius: RING_SIZE / 4 + 2, // 32
      color: "rgba(91, 227, 176, " + this.glow.toFixed(2) + ")",
      offsetX: 0,
      offsetY: 0,
    })
  }

  draw(): void {
    const ctx: CanvasRenderingContext2D = this.ctx
    const cx: number = RING_CENTER
    const cy: number = RING_CENTER
    const r: number = RING_RADIUS
    const lw: number = RING_STROKE

    ctx.clearRect(0, 0, RING_SIZE, RING_SIZE)

    const grad: CanvasGradient = ctx.createLinearGradient(0, 0, RING_SIZE, RING_SIZE)
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
