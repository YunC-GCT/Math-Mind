// ============================================================================
//  pages/StudyPlan/PlanStatsBar.ets — 学习计划进度统计
//  ----------------------------------------------------------------------------
//  职责: 显示 "X/Y 已完成" + 线性进度条(总计划为 0 时显示"暂无计划")。
//
//  布局:
//    [✓  X/Y 已完成]  ........................ [Progress 进度条 / 暂无计划]
//
//  依赖:
//    shared:     AppIcon
//    viewmodels: StudyPlanViewModel
//    common 令牌: MINT / TEXT_2 / TEXT_3 / S_5 / F_XS / F_BASE / F_MD
//
//  来源: 2026-07-17 pages 重组(从 StudyPlanPage 拆出)
//  ============================================================================

import { MINT, TEXT_2, TEXT_3, S_5, F_XS, F_BASE, F_MD } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../shared/components/AppIcon"

@Component
export struct PlanStatsBar {
  // 页面 ViewModel(响应式订阅)
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row() {
      // 左侧: 已完成计数
      Row({ space: 6 }) {
        AppIcon({ name: "check", iconSize: F_MD, color: MINT, strokeWidth: 2.2 })
        Text(`${this.vm.completedCount}/${this.vm.totalCount} 已完成`)
          .fontSize(F_BASE)
          .fontColor(TEXT_2)
      }

      Blank()

      // 右侧: 进度条 或 空状态文字
      if (this.vm.totalCount > 0) {
        // 线性进度条
        Progress({
          value: this.vm.completedCount,
          total: this.vm.totalCount,
          type: ProgressType.Linear,
        })
        .width(100)
        .height(6)
        .color(MINT)
        .style({ strokeWidth: 6, strokeRadius: 3 })
      } else {
        Text("暂无计划")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: 8, bottom: 8 })
  }
}
