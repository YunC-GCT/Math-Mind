// ============================================================================
//  overlays/NoteDetailOverlay/NoteAiCard.ets — 笔记详情 AI 解答卡
//  ----------------------------------------------------------------------------
//  职责: 引导用户点击 AI 解答的卡片(mint→purple 渐变 + 钻石图标)。
//
//  布局:
//    [✦]  AI 解答                [›]
//          让 MathMind AI 解释这道题
//
//  Props:
//    onTap: 点击回调(由 NoteDetailOverlay 转发到 handleAskAi)
//
//  依赖:
//    atoms: AppIcon
//    common 令牌: MINT / MINT_BORDER / PURPLE / BG_DARK / TEXT / TEXT_3 /
//         S_4 / R_LG / F_XS / F_BASE / W_BOLD
//
//  来源: 从 NoteDetailOverlay 拆出(2026-07-15 W2 原子化)
//  ============================================================================

import {
  MINT, MINT_BORDER, PURPLE,
  BG_DARK, TEXT, TEXT_3,
  S_4, R_LG, F_XS, F_BASE, W_BOLD,
} from "common"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct NoteAiCard {
  // 点击回调
  onTap: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        // 左侧 AI 渐变图标(mint→purple)
        Stack() {
          AppIcon({ name: "star", iconSize: 14, color: BG_DARK, strokeWidth: 2 })
        }
        .width(28).height(28)
        .borderRadius(14)
        .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
        .alignContent(Alignment.Center)
        .margin({ right: 10 })

        // 中间文字区
        Column() {
          Text("AI 解答")
            .fontSize(F_BASE)
            .fontWeight(W_BOLD)
            .fontColor(TEXT)
          Text("让 MathMind AI 解释这道题")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧右箭头
        AppIcon({ name: "chevron-right", iconSize: 18, color: MINT, strokeWidth: 2 })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
    .borderRadius(R_LG)
    .backgroundColor("#0DFFFFFF")
    .border({ width: 1, color: MINT_BORDER })
    .linearGradient({
      angle: 135,
      colors: [["#1A5BE3B0", 0], ["#0D9775FA", 1]],
    })
    .onClick((): void => this.onTap())
  }
}
