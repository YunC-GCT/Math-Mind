// ============================================================================
//  atoms/ViewfinderCorners.ets — 取景框四角 L 形标线
//  ----------------------------------------------------------------------------
//  职责: 渲染 mint 色 L 形四角 (24vp × 2vp)。
//  接口: 无 @Prop (纯展示)
//  ============================================================================

import { MINT, S_1, S_6 } from "common"

@Component
export struct ViewfinderCorners {
  build() {
    Stack() {
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: S_6, y: S_6 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: S_6, y: S_6 })
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: "100%", y: S_6 }).markAnchor({ x: S_6, y: 0 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: "100%", y: S_6 }).markAnchor({ x: 0, y: 0 })
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: S_6, y: "100%" }).markAnchor({ x: 0, y: S_1 / -2 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: S_6, y: "100%" }).markAnchor({ x: 0, y: -S_6 })
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: "100%", y: "100%" }).markAnchor({ x: -S_6, y: S_1 / -2 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: "100%", y: "100%" }).markAnchor({ x: 0, y: -S_6 })
    }.width("100%").height("100%")
  }
}
