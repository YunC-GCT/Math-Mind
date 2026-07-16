// ============================================================================
//  SettingsTopBar.ets — 设置页顶栏原子
//  UI: [← 返回]         模型配置         [   ]
// ============================================================================
import { MINT, TEXT, F_SM, F_MD, W_SEMIBOLD, S_2, S_3 } from "common"
import { router } from "@kit.ArkUI"

@Component
export struct PageHeader {
  @Prop title: string = "设置"
  build() {
    Row() {
      Text("← 返回").fontSize(F_SM).fontColor(MINT).onClick((): void => { router.back() })
      Blank()
      Text(this.title).fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Blank()
      Row().width(60)
    }.width("100%").padding({ left: S_2, right: S_2, top: S_3, bottom: S_3 })
  }
}
