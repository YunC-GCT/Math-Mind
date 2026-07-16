// ============================================================================
//  molecules/TabBar.ets — 底部导航栏分子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染 5 个 Tab 按钮（4 普通 + 1 中央 AI），含渐变背景和毛玻璃效果。
//  来源: 从 Index.ets 提取内联 TabBar Row。
//  数据流: @Prop cur + onTabChange callback 通知父组件切换。
//  接口:
//    @Prop  cur      — 当前选中 Tab 索引
//    onTabChange      — (index: number) => void
//    onAiTap           — AI 按钮点击回调
//  依赖: TabButton (atoms), AiTabButton (atoms)
//  ============================================================================

import {
  MINT_DARK, BG_DARK, BORDER,
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
  { idx: 0, name: "首页", icon: $r("app.media.ic_home") },
  { idx: 1, name: "笔记", icon: $r("app.media.ic_notes") },
  { idx: 2, name: "AI",   icon: $r("app.media.ic_ai") },
  { idx: 3, name: "复习", icon: $r("app.media.ic_review") },
  { idx: 4, name: "我的", icon: $r("app.media.ic_me") },
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
