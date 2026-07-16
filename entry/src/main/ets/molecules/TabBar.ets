// ============================================================================
//  molecules/TabBar.ets 鈥?搴曢儴瀵艰埅鏍忓垎瀛愮粍浠?//  ----------------------------------------------------------------------------
//  鑱岃矗: 娓叉煋 5 涓?Tab 鎸夐挳锛? 鏅€?+ 1 涓ぎ AI锛夛紝鍚笎鍙樿儗鏅拰姣涚幓鐠冩晥鏋溿€?//  鏉ユ簮: 浠?Index.ets 鎻愬彇鍐呰仈 TabBar Row銆?//  鏁版嵁娴? @Prop cur + onTabChange callback 閫氱煡鐖剁粍浠跺垏鎹€?//  鎺ュ彛:
//    @Prop  cur      鈥?褰撳墠閫変腑 Tab 绱㈠紩
//    onTabChange      鈥?(index: number) => void
//    onAiTap           鈥?AI 鎸夐挳鐐瑰嚮鍥炶皟
//  渚濊禆: TabButton (atoms), AiTabButton (atoms)
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
  { idx: 0, name: "棣栭〉", icon: $r("app.media.ic_home") },
  { idx: 1, name: "绗旇", icon: $r("app.media.ic_notes") },
  { idx: 2, name: "AI",   icon: $r("app.media.ic_ai") },
  { idx: 3, name: "澶嶄範", icon: $r("app.media.ic_review") },
  { idx: 4, name: "鎴戠殑", icon: $r("app.media.ic_me") },
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
      colors: [["#00000000", 0], [BG_DARK, 1]],
    })
    .backdropBlur(24)
    .border({ width: { top: 1 }, color: BORDER })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
  }
}
