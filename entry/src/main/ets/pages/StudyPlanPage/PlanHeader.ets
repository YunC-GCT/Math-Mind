import { MINT, BG_DARK, TEXT, TEXT_3, BORDER, S_4, S_5, R_FULL, F_XS, F_2XL, W_BOLD, StudyPlanItem } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct PlanHeader {
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row() {
      Text("学习计划")
        .fontSize(F_2XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)

      Blank()

      Row({ space: 4 }) {
        if (this.vm.isLoading) {
          LoadingProgress().width(12).height(12).color(MINT)
          Text("生成中...")
            .fontSize(F_XS)
            .fontColor(MINT)
        } else {
          AppIcon({ name: "ai", iconSize: 12, color: TEXT_3, strokeWidth: 1.8 })
          Text("智能生成")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
        }
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .border({ width: 1, color: this.vm.isLoading ? MINT : BORDER, radius: R_FULL })
      .onClick((): void => {
        if (this.vm.isLoading) {
          return
        }
        const knownTitles: string[] = this.vm.items.map((item: StudyPlanItem): string => item.title)
        this.vm.generatePlan(knownTitles)
      })
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })
    .backgroundColor(BG_DARK)
  }
}
