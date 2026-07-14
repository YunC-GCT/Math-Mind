/**
 * MathMind 6 边形 Logo — 32×32 浮空旋转 4s 循环
 *
 * 外六边形 (strokeWidth 1.5) + 内部 M 字一笔画 (strokeWidth 2)
 * 颜色 #5BE3B0 主题薄荷绿, 无填充, 圆角端点 + 圆角连接
 *
 * 动画 4s 循环:
 *   0%   rotate 0   ty  0
 *   30%  rotate 5°  ty -1.5
 *   60%  rotate -3° ty  1
 *   100% rotate 0   ty  0
 *
 * 链式 setTimeout: 0→30% (1200ms) + 30%→60% (1200ms) + 60%→100% (1600ms) = 4000ms
 *
 * ArkTS 1.1 strict 限制: struct 内禁普通方法, 全部动画逻辑放 aboutToAppear 内
 * 用 let 声明 + 立即初始化空函数 + 后续赋值, 避免 const 闭包 TDZ
 */
import { MINT } from 'common';

@Component
export struct HexLogo {
  @State rotate: number = 0;
  @State ty: number = 0;
  private timer: number = -1;

  aboutToAppear(): void {
    // 用 let + 立即空函数初始化, 避免 const 递归引用触发 TDZ
    let startCycle: () => void = (): void => {};
    startCycle = (): void => {
      // 0% → 30%: rotate 0→5°, ty 0→-1.5
      animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
        this.rotate = 5;
        this.ty = -1.5;
      });
      // 30% → 60%: rotate 5°→-3°, ty -1.5→1
      this.timer = setTimeout(() => {
        animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
          this.rotate = -3;
          this.ty = 1;
        });
        // 60% → 100%: rotate -3°→0, ty 1→0
        this.timer = setTimeout(() => {
          animateTo({ duration: 1600, curve: Curve.EaseInOut }, () => {
            this.rotate = 0;
            this.ty = 0;
          });
          // 100% 回到 0%, 启动下一个 4s 循环
          this.timer = setTimeout(startCycle, 1600);
        }, 1200);
      }, 1200);
    };
    startCycle();
  }

  aboutToDisappear(): void {
    clearTimeout(this.timer);
  }

  build() {
    Image($r('app.media.ic_brand_hex'))
      .width(32).height(32)
      .fillColor(MINT)
      .rotate(this.rotate)
      .translate({ y: this.ty });
  }
}
