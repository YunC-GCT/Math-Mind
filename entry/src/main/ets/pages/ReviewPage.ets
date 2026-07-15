/**
 * MathMind 复习计划页 — 对照 iOS Web MVP page-review
 * W2 更新 (2026-07-15): 对接 StudyPlanPage，替换空状态占位
 *
 * 接口切换:
 *   - "去 AI 对话" → 导航到 StudyPlanPage (学习计划 Todo 列表)
 *   - "去 AI 对话"按钮保留但改为跳转学习计划
 */

import {
  MINT,
  MINT_DARK,
  TEXT,
  TEXT_3,
  S_1,
  S_2,
  S_3,
  R_FULL,
  F_SM,
  F_BASE,
  F_MD,
  F_XL,
  F_2XL,
} from "common";
import { router } from "@kit.ArkUI";

@Component
export struct ReviewPage {
  // 父组件传入的回调（保留兼容）
  onGoAI: () => void = (): void => {};

  build() {
    Scroll() {
      Column() {
        Blank();

        // ===== 空状态区 =====
        Column() {
          // 📋 emoji（对照 CSS font-size:48px）
          Text("📋")
            .fontSize(F_2XL + 18)
            .margin({ bottom: 12 });

          // 标题
          Text("学习计划")
            .fontSize(F_BASE + 1)
            .fontWeight(W_SEMIBOLD)
            .fontColor(TEXT)
            .margin({ bottom: 8 });

          // 副标题
          Text("管理你的学习待办事项\n标记完成、设置优先级")
            .fontSize(F_SM + 1)
            .fontColor(TEXT_3)
            .textAlign(TextAlign.Center)
            .lineHeight(20)
            .margin({ bottom: 16 });

          // "打开学习计划" 按钮（mint 渐变）
          Button("打开学习计划")
            .fontSize(F_SM)
            .fontWeight(W_SEMIBOLD)
            .fontColor("#FF0A0C10")
            .width(140)
            .height(40)
            .borderRadius(R_FULL)
            .linearGradient({
              angle: 135,
              colors: [
                [MINT, 0],
                [MINT_DARK, 1],
              ],
            })
            .onClick((): void => {
              router.pushUrl({ url: "pages/StudyPlanPage" });
            });
        }
        .alignItems(HorizontalAlign.Center)
        .width("100%");

        Blank();
      }
      .width("100%")
      .height("100%");
    }
    .width("100%")
    .height("100%");
  }
}
