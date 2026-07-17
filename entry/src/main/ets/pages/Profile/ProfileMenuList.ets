import { BG_CARD, S_2, S_4, R_LG } from "common"
import { router } from "@kit.ArkUI"
import { MenuItemRow } from "./ProfileMenuItemRow"

@Component
export struct ProfileMenuList {
  onToast: (message: string) => void = (_message: string): void => {}

  build() {
    Column() {
      MenuItemRow({ icon: "review", label: "\u6211\u7684\u590d\u4e60\u8ba1\u5212", onTap: (): void => this.onToast("\u590d\u4e60\u8ba1\u5212\u5f00\u53d1\u4e2d") })
      MenuItemRow({ icon: "notes", label: "\u9519\u9898\u672c", onTap: (): void => this.onToast("\u9519\u9898\u672c\u5f00\u53d1\u4e2d") })
      MenuItemRow({ icon: "home", label: "\u6211\u7684\u6536\u85cf", onTap: (): void => this.onToast("\u6536\u85cf\u529f\u80fd\u5f00\u53d1\u4e2d") })
      MenuItemRow({ icon: "ai", label: "\u6a21\u578b", onTap: (): void => { router.pushUrl({ url: "pages/AiSettings/AiSettingsPage" }) } })
      MenuItemRow({ icon: "me", label: "\u5207\u6362\u8d26\u53f7", onTap: (): void => this.onToast("\u5207\u6362\u8d26\u53f7\u5f00\u53d1\u4e2d") })
    }
    .width("100%")
    .backgroundColor(BG_CARD)
    .borderRadius(R_LG)
    .margin({ left: S_4, right: S_4, top: S_2 })
  }
}