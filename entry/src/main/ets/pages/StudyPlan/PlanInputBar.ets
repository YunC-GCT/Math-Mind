// ============================================================================
//  pages/StudyPlan/PlanInputBar.ets — 学习计划底部输入栏
//  ----------------------------------------------------------------------------
//  职责: 底部 TextInput + 提交按钮。新增/编辑计划项。
//
//  布局:
//    [TextInput ............. ] [+ 按钮 / ✓ 按钮(编辑模式)]
//
//  行为:
//    onChange → vm.newTitle
//    onSubmit → vm.submitInput()(新增/保存编辑)
//    点击 +/✓ → vm.submitInput()
//
//  编辑态切换:
//    vm.isEditing=true → placeholder 改 "修改学习计划..."、按钮变 ✓
//
//  依赖:
//    shared:     AppIcon
//    viewmodels: StudyPlanViewModel
//    common 令牌: MINT / BG_CARD / TEXT / TEXT_3 / GLASS_8 / S_5 / R_FULL
//
//  来源: 2026-07-17 pages 重组(从 StudyPlanPage 拆出)
//  ============================================================================

import { MINT, BG_CARD, TEXT, TEXT_3, GLASS_8, S_5, R_FULL } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { AppIcon } from "../../shared/components/AppIcon"

@Component
export struct PlanInputBar {
  // 页面 ViewModel(响应式订阅)
  @ObjectLink vm: StudyPlanViewModel

  build() {
    Row({ space: 8 }) {
      // 输入框
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

      // 提交按钮(+ 新增 / ✓ 编辑)
      Button() {
        AppIcon({
          name: this.vm.isEditing ? "check" : "plus",
          iconSize: 22,
          color: MINT,
          strokeWidth: 2.2
        })
      }
      .backgroundColor(GLASS_8)
      .onClick((): void => { this.vm.submitInput() })
      // 输入为空时禁用
      .enabled(this.vm.newTitle.trim().length > 0)
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: 12, bottom: 12 })
    .backgroundColor(BG_CARD)
    // 适配底部安全区(iPhone X 系列 home indicator)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
