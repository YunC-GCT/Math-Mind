/**
 * ReminderBanner 分子组件 — 首页提醒横幅
 * 从 HomePage 提取，笔记 < 3 条时显示
 */
import {
  MINT, MINT_LIGHT, PURPLE_LIGHT,
  S_2, S_3, S_4,
  R_MD,
  F_SM,
  LH_BASE,
} from "common"

@Component
export struct ReminderBanner {
  @Prop notesCount: number = 0

  build() {
    Row() {
      Text(this.notesCount === 0
        ? "👋 欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记 >"
        : "⏰ 已有 " + this.notesCount + " 条笔记，继续用 AI 充实知识库 >")
        .fontSize(F_SM).fontColor(MINT).lineHeight(LH_BASE)
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
