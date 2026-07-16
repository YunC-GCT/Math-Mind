import { BG_DARK, TEXT_2, BORDER, GLASS_10, DANGER, S_2, S_4, S_6, R_MD, W_BOLD } from "common"

@Component
export struct NoteActionBar {
  onDelete: () => void = (): void => {}
  onEdit: () => void = (): void => {}
  onShare: () => void = (): void => {}

  build() {
    Row() {
      this.ActionBtn("Del", "删除", DANGER, (): void => this.onDelete())
      Blank().width(8)
      this.ActionBtn("Edit", "编辑", TEXT_2, (): void => this.onEdit())
      Blank().width(8)
      this.ActionBtn("Share", "分享", TEXT_2, (): void => this.onShare())
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_2, bottom: S_6 })
    .backgroundColor(BG_DARK)
    .border({ width: { top: 1 }, color: BORDER })
  }

  @Builder
  ActionBtn(icon: string, label: string, color: ResourceColor, action: () => void) {
    Column() {
      Text(icon).fontSize(10).fontColor(color).fontWeight(W_BOLD).maxLines(1)
      Text(label).fontSize(10).fontColor(color).margin({ top: 3 })
    }
    .layoutWeight(1).height(44)
    .borderRadius(R_MD)
    .backgroundColor(GLASS_10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => action())
  }
}
