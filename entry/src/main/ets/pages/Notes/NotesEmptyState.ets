// ============================================================================
//  pages/Notes/NotesEmptyState.ets — 笔记列表空状态
//  ----------------------------------------------------------------------------
//  职责: 笔记为 0 时显示的居中提示,引导用户拍照/对话。
//
//  布局(垂直居中):
//    "暂无笔记"
//    "拍照或对话生成的知识点会显示在这里"
//
//  依赖: common 令牌(TEXT_3 / TEXT_4 / S_6 / F_SM / F_BASE / W_SEMIBOLD)
//  ============================================================================

import {
  TEXT_3, TEXT_4,
  S_6,
  F_SM, F_BASE,
  W_SEMIBOLD,
} from "common"

@Component
export struct NotesEmptyState {
  build() {
    Column() {
      // 主提示
      Text("暂无笔记")
        .fontSize(F_BASE)
        .fontWeight(W_SEMIBOLD)
        .fontColor(TEXT_3)

      // 副提示
      Text("拍照或对话生成的知识点会显示在这里")
        .fontSize(F_SM)
        .fontColor(TEXT_4)
        .margin({ top: S_6 / 3 })
    }
    .width("100%")
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: S_6, right: S_6 })
  }
}
