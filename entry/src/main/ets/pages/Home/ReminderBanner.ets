// ============================================================================
//  pages/Home/ReminderBanner.ets — 首页提醒横幅分子组件
//  ----------------------------------------------------------------------------
//  职责: 笔记数 < 3 时显示引导文案（欢迎/鼓励）。
//  来源: 从 HomePage.ets 提取，消除内联 if 块。
//  接口:
//    @Prop  notesCount — 当前笔记总数（控制显示和文案）
//  ============================================================================

import {
  MINT, MINT_LIGHT, PURPLE_LIGHT,
  S_2, S_3, S_4,
  R_MD,
  F_SM,
  LH_BASE,
} from "common"
import { AppIcon } from "../../shared/components/AppIcon"

@Component
export struct ReminderBanner {
  @Prop notesCount: number = 0

  build() {
    Row() {
      AppIcon({ name: this.notesCount === 0 ? "ai" : "review", iconSize: 16, color: MINT, strokeWidth: 1.8 })
        .margin({ right: S_2 })
      Text(this.notesCount === 0
        ? "欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记"
        : "已有 " + this.notesCount + " 条笔记，继续用 AI 充实知识库")
        .fontSize(F_SM).fontColor(MINT).lineHeight(LH_BASE)
      Blank()
      AppIcon({ name: "chevron-right", iconSize: 14, color: MINT, strokeWidth: 1.8 })
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_3, bottom: S_3 })
    .margin({ left: S_4, right: S_4, top: S_2 })
    .borderRadius(R_MD)
    .linearGradient({
      angle: 135,
      colors: [[MINT_LIGHT, 0], [PURPLE_LIGHT, 1]],
    })
    .border({ width: 1, color: MINT_LIGHT })
  }
}
