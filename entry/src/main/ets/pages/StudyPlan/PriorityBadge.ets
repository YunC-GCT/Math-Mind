// ============================================================================
//  pages/StudyPlan/PriorityBadge.ets — 优先级标签原子组件
//  ----------------------------------------------------------------------------
//  职责: 根据 priority 值渲染"高"/"低"标签（中等优先级不显示）。
//  可复用: 任何需要展示优先级的列表/详情场景。
//  ============================================================================

import { TEXT_3, BORDER, DANGER_BRIGHT, R_SM, F_XS } from "common"

// ---- 优先级色板 (本地常量，未提升到 common 以保持 ColorTokens 精简) ----

@Component
export struct PriorityBadge {
  @Prop priority: number = 2

  build() {
    if (this.priority === 1) {
      Text("高")
        .fontSize(F_XS)
        .fontColor(DANGER_BRIGHT)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .border({ width: 1, color: "#44EF4444", radius: R_SM })
    } else if (this.priority === 3) {
      Text("低")
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .border({ width: 1, color: BORDER, radius: R_SM })
    }
    // priority === 2 (中) 不渲染任何标签
  }
}
