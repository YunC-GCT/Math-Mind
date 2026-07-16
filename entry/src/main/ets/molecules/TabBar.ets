// ============================================================================
//  molecules/TabBar.ets 閳?鎼存洟鍎寸€佃壈鍩呴弽蹇撳瀻鐎涙劗绮嶆禒?//  ----------------------------------------------------------------------------
//  閼卞矁鐭? 濞撳弶鐓?5 娑?Tab 閹稿鎸抽敍? 閺咁噣鈧?+ 1 娑擃厼銇?AI閿涘绱濋崥顐ｇ瑤閸欐鍎楅弲顖氭嫲濮ｆ稓骞撻悹鍐╂櫏閺嬫嚎鈧?//  閺夈儲绨? 娴?Index.ets 閹绘劕褰囬崘鍛颁粓 TabBar Row閵?//  閺佺増宓佸ù? @Prop cur + onTabChange callback 闁氨鐓￠悥鍓佺矋娴犺泛鍨忛幑顫偓?//  閹恒儱褰?
//    @Prop  cur      閳?瑜版挸澧犻柅澶夎厬 Tab 缁便垹绱?//    onTabChange      閳?(index: number) => void
//    onAiTap           閳?AI 閹稿鎸抽悙鐟板毊閸ョ偠鐨?//  娓氭繆绂? TabButton (atoms), AiTabButton (atoms)
//  ============================================================================

import {
  BG_DARK, BORDER,
  S_1, S_2,
  TAB_BAR_HEIGHT,
} from "common"
import { TabButton } from "../atoms/TabButton"
import { AiTabButton } from "../atoms/AiTabButton"

interface TabItem {
  idx: number
  name: string
  icon: Resource
}

const TABS: TabItem[] = [
  { idx: 0, name: "妫ｆ牠銆?, icon: $r("app.media.ic_home") },
  { idx: 1, name: "缁楁棁顔?, icon: $r("app.media.ic_notes") },
  { idx: 2, name: "AI",   icon: $r("app.media.ic_ai") },
  { idx: 3, name: "婢跺秳绡?, icon: $r("app.media.ic_review") },
  { idx: 4, name: "閹存垹娈?, icon: $r("app.media.ic_me") },
]

@Component
export struct TabBar {
  @Prop cur: number = 0
  onTabChange: (i: number) => void = (_i: number): void => {}
  onAiTap: () => void = (): void => {}

  build() {
    Row() {
      ForEach(TABS,
        (tab: TabItem, i: number): void => {
          if (i === 2) {
            AiTabButton({ onTap: (): void => { this.onAiTap() } })
          } else {
            TabButton({
              icon: tab.icon,
              label: tab.name,
              active: this.cur === i,
              onTap: (): void => { this.onTabChange(i) },
            })
          }
        },
        (tab: TabItem): string => tab.idx.toString()
      )
    }
    .width("100%").height(TAB_BAR_HEIGHT)
    .padding({ left: S_1 + 2, right: S_1 + 2, bottom: S_2 + 2 })
    .linearGradient({
      angle: 180,
      colors: [["#00FFFFFF", 0], [BG_DARK, 1]],
    })
    .backdropBlur(S_6)
    .border({ width: { top: S_1 / 4 }, color: BORDER })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
  }
}
