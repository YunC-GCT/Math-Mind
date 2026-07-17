// ============================================================================
//  prototypes/NoteDetailOverlay/NoteSection.ets — 笔记章节渲染
//  ----------------------------------------------------------------------------
//  职责: 渲染笔记正文的单个章节(标题 + 正文)。
//
//  布局:
//    章节标题(MINT 品牌色,小字号)
//    章节正文(默认正文色,长文本可换行)
//
//  导出:
//    Section:    类型 {title, content}
//    NoteSectionView: 组件
//
//  Props:
//    title:   章节标题(如 "## 定义" → "定义")
//    content: 章节正文
//
//  依赖: common ColorTokens (MINT / TEXT_2 / S_2 / S_3 / F_SM / F_BASE / W_BOLD)
//
//  来源: 从 NoteDetailOverlay 拆出(2026-07-15 W2 原子化)
//  ============================================================================

import { MINT, TEXT_2, S_2, S_3, F_SM, F_BASE, W_BOLD } from "common"

// 章节数据结构
export interface Section {
  title: string
  content: string
}

@Component
export struct NoteSectionView {
  // 章节标题
  @Prop title: string = ""

  // 章节正文
  @Prop content: string = ""

  build() {
    Column() {
      // 章节标题(MINT 品牌色,小字号 + 字间距)
      Text(this.title)
        .fontSize(F_SM)
        .fontWeight(W_BOLD)
        .fontColor(MINT)
        .letterSpacing(0.5)
        .width("100%")
        .margin({ top: S_3, bottom: S_2 })

      // 章节正文(空时显示 "—")
      Text(this.content.length > 0 ? this.content : "—")
        .fontSize(F_BASE)
        .fontColor(TEXT_2)
        .lineHeight(22)
        .width("100%")
    }
    .width("100%")
    .alignItems(HorizontalAlign.Start)
  }
}
