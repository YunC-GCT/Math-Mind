// ============================================================================
//  prototypes/NoteDetailOverlay/NoteActionBar.ets — 笔记详情底部操作栏
//  ----------------------------------------------------------------------------
//  职责: 笔记详情浮层底部的 [删除] [编辑] [分享] 三个操作按钮。
//
//  布局:
//    [Del 删除]   [Edit 编辑]   [Share 分享]
//
//  Props:
//    onDelete: 删除回调
//    onEdit:   编辑回调
//    onShare:  分享回调
//
//  依赖: common ColorTokens (BG_DARK / TEXT_2 / BORDER / GLASS_10 / DANGER /
//         S_2 / S_4 / S_6 / R_MD / W_BOLD)
//
//  来源: 从 NoteDetailOverlay 拆出(2026-07-15 W2 原子化)
//  ============================================================================

import { BG_DARK, TEXT_2, BORDER, GLASS_10, DANGER, S_2, S_4, S_6, R_MD, W_BOLD } from "common"

@Component
export struct NoteActionBar {
  // 删除回调
  onDelete: () => void = (): void => {}

  // 编辑回调
  onEdit: () => void = (): void => {}

  // 分享回调
  onShare: () => void = (): void => {}

  build() {
    Row() {
      // [Del] 删除(危险色)
      this.ActionBtn("Del", "删除", DANGER, (): void => this.onDelete())
      Blank().width(8)

      // [Edit] 编辑(默认色)
      this.ActionBtn("Edit", "编辑", TEXT_2, (): void => this.onEdit())
      Blank().width(8)

      // [Share] 分享(默认色)
      this.ActionBtn("Share", "分享", TEXT_2, (): void => this.onShare())
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_2, bottom: S_6 })
    .backgroundColor(BG_DARK)
    // 顶部分隔线(区分内容区)
    .border({ width: { top: 1 }, color: BORDER })
  }

  // 复用操作按钮(icon + label 垂直布局)
  @Builder
  ActionBtn(icon: string, label: string, color: ResourceColor, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(10)
        .fontColor(color)
        .fontWeight(W_BOLD)
        .maxLines(1)
      Text(label)
        .fontSize(10)
        .fontColor(color)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .height(44)
    .borderRadius(R_MD)
    .backgroundColor(GLASS_10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => action())
  }
}
