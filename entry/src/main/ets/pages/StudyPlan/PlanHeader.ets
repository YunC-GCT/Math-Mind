// ============================================================================
//  pages/StudyPlan/PlanHeader.ets — 学习计划页标题栏
//  ----------------------------------------------------------------------------
//  职责: "学习计划" 标题 + 右侧 AI 智能生成按钮(loading 时显示进度环)。
//
//  布局:
//    [学习计划] ........................ [🤖 智能生成 / ⏳ 生成中...]
//
//  行为:
//    点击"智能生成" → vm.generatePlan(knownTitles)
//    生成中 → 按钮变 loading,显示 LoadingProgress + "生成中..." 文字
//
//  依赖:
//    shared:     AppIcon
//    viewmodels: StudyPlanViewModel
//    common 令牌: MINT / BG_DARK / TEXT / TEXT_3 / BORDER / S_4 / S_5 /
//         R_FULL / F_XS / F_2XL / W_BOLD
//
//  来源: 2026-07-17 pages 重组(从 StudyPlanPage 拆出)
//  ============================================================================

import { MINT, BG_DARK, TEXT, TEXT_3, BORDER, S_4, S_5, R_FULL, F_XS, F_2XL, W_BOLD, StudyPlanItem } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../shared/components/AppIcon"

@Component
export struct PlanHeader {
  // 页面 ViewModel(响应式订阅)
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row() {
      // 标题
      Text("学习计划")
        .fontSize(F_2XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)

      Blank()

      // 右侧 AI 智能生成按钮
      Row({ space: 4 }) {
        if (this.vm.isLoading) {
          // 生成中: 进度环 + 文字
          LoadingProgress()
            .width(12)
            .height(12)
            .color(MINT)
          Text("生成中...")
            .fontSize(F_XS)
            .fontColor(MINT)
        } else {
          // 待生成: AI 图标 + 文字
          AppIcon({ name: "ai", iconSize: 12, color: TEXT_3, strokeWidth: 1.8 })
          Text("智能生成")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
        }
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .border({ width: 1, color: this.vm.isLoading ? MINT : BORDER, radius: R_FULL })
      .onClick((): void => {
        // 加载中点击无效
        if (this.vm.isLoading) { return }

        // 收集已有标题,避免 LLM 重复生成
        const knownTitles: string[] = this.vm.items.map((item: StudyPlanItem): string => item.title)
        this.vm.generatePlan(knownTitles)
      })
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })
    .backgroundColor(BG_DARK)
  }
}
