/**
 * HexLogo.ets — MathMind 6 边形 Logo
 *
 * 路径: entry/src/main/ets/atoms/HexLogo.ets
 * 职责: 32×32 浮空旋转 4s 循环的 6 边形品牌标识，用于 HomeTopBar 左侧。
 * 依赖: common (MINT / DUR_SLOWEST / DUR_SLOWER / DUR_BREATH)
 *
 * 视觉规格:
 *   - 外六边形 strokeWidth 1.5
 *   - 内部 M 字一笔画 strokeWidth 2
 *   - 颜色 #5BE3B0 主题薄荷绿，无填充，圆角端点 + 圆角连接
 *
 * 动画 4s 循环 (链式 setTimeout):
 *   0%   rotate 0°   ty  0
 *   30%  rotate 5°   ty -1.5
 *   60%  rotate -3°  ty  1
 *   100% rotate 0°   ty  0
 *   0→30% (1200ms) + 30→60% (1200ms) + 60→100% (1600ms) = 4000ms
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内禁普通方法，全部动画逻辑放 aboutToAppear
 *   - 状态名避开 ImageAttribute.rotate/translate (rotDeg / ty 不用 rotate/translate)
 *   - 用字段 startCycle + 立即初始化空函数 + 后续赋值，避免 const 闭包 TDZ
 *   - Image.rotate 接受 RotateOptions {angle} 对象，不接受 number 直接
 *   - 删 .fillColor() 让 SVG 内部 fill="none" 生效 (ArkUI 1.1 .fillColor 会覆盖)
 */
import { MINT, DUR_SLOWEST, DUR_SLOWER, DUR_BREATH } from 'common';

@Component
export struct HexLogo {
  // 状态名避开 ImageAttribute.rotate/translate (避免跟 base type 方法签名冲突)
  @State rotDeg: number = 0;
  @State ty: number = 0;
  private timer: number = -1;
  // 链式 setTimeout 循环需要闭包引用, 但 let 闭包互相引用在 ArkTS 1.1 strict
  // 可能触发 TDZ 编译错误. 改用 struct 字段 (字段赋值后调用合法).
  private startCycle: () => void = (): void => { return; };

  aboutToAppear(): void {
    this.startCycle = (): void => {
      // 0% → 30%: rotate 0→5°, ty 0→-1.5
      animateTo({ duration: DUR_SLOWEST, curve: Curve.EaseInOut }, () => {
        this.rotDeg = 5;
        this.ty = -1.5;
      });
      // 30% → 60%: rotate 5°→-3°, ty -1.5→1
      this.timer = setTimeout(() => {
        animateTo({ duration: DUR_SLOWEST, curve: Curve.EaseInOut }, () => {
          this.rotDeg = -3;
          this.ty = 1;
        });
        // 60% → 100%: rotate -3°→0, ty 1→0
        this.timer = setTimeout(() => {
          animateTo({ duration: DUR_SLOWER, curve: Curve.EaseInOut }, () => {
            this.rotDeg = 0;
            this.ty = 0;
          });
          // 100% 回到 0%, 启动下一个 4s 循环
          this.timer = setTimeout(() => { this.startCycle(); }, 1600);
        }, 1200);
      }, 1200);
    };
    this.startCycle();
  }

  aboutToDisappear(): void {
    clearTimeout(this.timer);
  }

  build() {
    Image($r('app.media.ic_brand_hex'))
      .width(32).height(32)
      // SVG 已硬编码 stroke="#5BE3B0" + fill="none", Image.fillColor 在 ArkUI 1.1 可能覆盖 SVG fill
      // 删 fillColor 让 SVG fill="none" 生效, 6 边形保持空心线条 (不变成实心)
      // Image.rotate 接受 RotateOptions { angle: number } 对象, 不接受 number 直接
      .rotate({ angle: this.rotDeg })
      .translate({ y: this.ty });
  }
}
