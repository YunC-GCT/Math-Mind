import { TEXT_2, GLASS_10, S_4 } from "common"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct NoteCloseButton {
  onClose: () => void = (): void => {}

  build() {
    Stack() {
      AppIcon({ name: "close", iconSize: 16, color: TEXT_2, strokeWidth: 2 })
    }
    .width(S_4 * 2).height(S_4 * 2)
    .borderRadius(22)
    .backgroundColor(GLASS_10)
    .alignContent(Alignment.Center)
    .onClick((): void => this.onClose())
  }
}
