// ============================================================================
//  overlays/NoteDetailOverlay/NoteTagChip.ets — 笔记标签 chip
//  ----------------------------------------------------------------------------
//  职责: 单个标签展示("#" 前缀 + mint 浅底 + 圆角)。
//
//  布局:
//    [#tag] (MINT 文字 + MINT_GLOW 浅底)
//
//  Props:
//    tag: 标签名(不含 #)
//
//  依赖: common ColorTokens (MINT / MINT_GLOW / S_2 / S_3 / R_FULL / F_XS)
//
//  来源: 从 NoteDetailOverlay 拆出(2026-07-15 W2 原子化)
//  ============================================================================

import { MINT, MINT_GLOW, S_2, S_3, R_FULL, F_XS } from "common"

@Component
export struct NoteTagChip {
  // 标签名(不含 # 前缀)
  @Prop tag: string = ""

  build() {
    Text("#" + this.tag)
      .fontSize(F_XS)
      .fontColor(MINT)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL)
      .backgroundColor(MINT_GLOW)
      // 右下间距(多个标签时换行/换列排版好看)
      .margin({ right: S_2, bottom: S_2 })
  }
}
