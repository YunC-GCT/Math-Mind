/**
 * MathMind 复习计划页 — 对照 iOS Web MVP page-review
 * MVP 阶段：空状态 + 引导去 AI
 * 对照 CSS inline style: flex column centered, height 60vh, gap 12px
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
} from 'common';

@Component
export struct ReviewPage {
  // 父组件传入的 Tab 切换回调
  onGoAI: () => void = () => {
  };

  build() {
    Scroll() {
      Column() {
        Blank();

        // ===== 空状态区 =====
        Column() {
          // 📋 emoji（对照 CSS font-size:48px）
          Text('📋')
            .fontSize(F_2XL + 18)
            .margin({ bottom: 12 });

          // 标题（对照 CSS font-size:16px font-weight:600）
          Text('复习计划')
            .fontSize(F_BASE + 1)
            .fontWeight(600)
            .fontColor(TEXT)
            .margin({ bottom: 8 });

          // 副标题（对照 CSS font-size:13px color:var(--text-3)）
          Text('通过 AI 对话分析笔记后\n自动生成个性化复习计划')
            .fontSize(F_SM + 1)
            .fontColor(TEXT_3)
            .textAlign(TextAlign.Center)
            .lineHeight(20)
            .margin({ bottom: 16 });

          // "去 AI 对话" 按钮（对照 CSS .btn-primary mint 渐变）
          Button('去 AI 对话')
            .fontSize(F_SM)
            .fontWeight(600)
            .fontColor('#FF0A0C10')
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
            .onClick(() => {
              this.onGoAI();
            });
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%');

        Blank();
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
