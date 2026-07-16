import { MINT, BG_CARD, TEXT, TEXT_3, GLASS_8, S_5, R_FULL } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct PlanInputBar {
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row({ space: 8 }) {
      TextInput({
        placeholder: this.vm.isEditing ? "修改学习计划..." : "新增学习计划...",
        text: this.vm.newTitle,
      })
      .onChange((value: string): void => { this.vm.newTitle = value })
      .onSubmit((): void => { this.vm.submitInput() })
      .layoutWeight(1)
      .height(44)
      .borderRadius(R_FULL)
      .backgroundColor(BG_CARD)
      .padding({ left: 16, right: 16 })
      .fontColor(TEXT)
      .placeholderColor(TEXT_3)

      Button() {
        AppIcon({ name: this.vm.isEditing ? "check" : "plus", iconSize: 22, color: MINT, strokeWidth: 2.2 })
      }
      .backgroundColor(GLASS_8)
      .onClick((): void => { this.vm.submitInput() })
      .enabled(this.vm.newTitle.trim().length > 0)
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: 12, bottom: 12 })
    .backgroundColor(BG_CARD)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
