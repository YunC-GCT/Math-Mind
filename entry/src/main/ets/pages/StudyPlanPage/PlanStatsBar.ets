import { MINT, TEXT_2, TEXT_3, S_5, F_XS, F_BASE, F_MD } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct PlanStatsBar {
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row() {
      Row({ space: 6 }) {
        AppIcon({ name: "check", iconSize: F_MD, color: MINT, strokeWidth: 2.2 })
        Text(`${this.vm.completedCount}/${this.vm.totalCount} 已完成`)
          .fontSize(F_BASE)
          .fontColor(TEXT_2)
      }

      Blank()

      if (this.vm.totalCount > 0) {
        Progress({
          value: this.vm.completedCount,
          total: this.vm.totalCount,
          type: ProgressType.Linear,
        })
        .width(100).height(6)
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
