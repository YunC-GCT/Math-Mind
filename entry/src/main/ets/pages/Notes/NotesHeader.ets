// ============================================================================
//  pages/Notes/NotesHeader.ets — 笔记列表页顶栏
//  ----------------------------------------------------------------------------
//  职责: 状态栏避让占位 + "全部笔记"标题 + 笔记数计数。
//
//  布局:
//    [状态栏占位]
//    ["全部笔记" ............ "X 条"]
//
//  依赖: common 令牌(BG_DARK / TEXT / TEXT_3 / S_4 / S_5 / F_XS / F_MD / W_SEMIBOLD)
//
//  Props:
//    statusBarHeight: 状态栏高度(由 AppStorage 注入)
//    count:           笔记总数(显示在右上角)
//  ============================================================================

import {
  BG_DARK, TEXT, TEXT_3,
  S_4, S_5,
  F_XS, F_MD,
  W_SEMIBOLD,
} from "common"

@Component
export struct NotesHeader {
  // 状态栏高度(沉浸式占位)
  @Prop statusBarHeight: number = 0

  // 笔记总数
  @Prop count: number = 0

  build() {
    Column() {
      // 状态栏占位
      Row()
        .width("100%")
        .height(this.statusBarHeight)
        .backgroundColor(BG_DARK)

      // 标题 + 计数
      Row() {
        Text("全部笔记")
          .fontSize(F_MD)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
        Blank()
        Text(this.count + " 条")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
      .width("100%")
      .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })
    }
    .width("100%")
  }
}
