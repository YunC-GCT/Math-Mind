/**
 * ConfDot.ets — 置信度指示点
 *
 * 路径: entry/src/main/ets/atoms/ConfDot.ets
 * 职责: 对齐 v2-ui .cd / .cd-hi / .cd-md / .cd-lo
 *       根据 confidence 值显示不同颜色的状态点
 * 依赖: common
 *
 * 映射:
 *   ≥0.8 → MINT (绿·高)
 *   ≥0.5 → AMBER (橙·中)
 *   <0.5 → DANGER (红·低)
 */

import { MINT, AMBER, DANGER, S_1 } from 'common';

@Component
export struct ConfDot {
  @Prop confidence: number = 0.8;

  build() {
    Circle({ width: 6, height: 6 })
      .fill(this.dotColor())
      .margin({ left: S_1, right: S_1 });
  }

  private dotColor(): string {
    if (this.confidence >= 0.8) { return MINT; }
    if (this.confidence >= 0.5) { return AMBER; }
    return DANGER;
  }
}
