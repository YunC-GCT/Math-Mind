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
      Text("暂无笔记")
        .fontSize(F_BASE)
        .fontWeight(W_SEMIBOLD)
        .fontColor(TEXT_3)
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