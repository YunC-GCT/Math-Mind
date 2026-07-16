// ============================================================================
//  pages/StudyPlanPage.ets — 学习计划页面（编排层）
//  ----------------------------------------------------------------------------
//  职责: 页面骨架布局 + ViewModel 桥接到原子组件。
//  来源: 基于 swiftui-to-arkui TodoPage，拆分为 PlanItemRow / PriorityBadge 原子组件。
//
//  对接:
//    - 持久化: 已对接 → StudyPlanDao (RDB study_plan 表)
//    - AI 生成: 已对接 → LlmClient.call()，按钮调用 vm.generatePlan()
//    - 关联笔记: linkedNoteId 字段已对接 KnowledgeUnit.id
//  ============================================================================

import {
  BG_DARK,
} from "common"
import { StudyPlanViewModel } from "../viewmodels/StudyPlanViewModel"
import { promptAction } from "@kit.ArkUI"
import { PlanHeader } from "./StudyPlanPage/PlanHeader"
import { PlanStatsBar } from "./StudyPlanPage/PlanStatsBar"
import { PlanListView } from "./StudyPlanPage/PlanListView"
import { PlanInputBar } from "./StudyPlanPage/PlanInputBar"

@Entry
@Component
export struct StudyPlanPage {
  @StorageProp('statusBarHeight') sbh: number = 0
  @State vm: StudyPlanViewModel = new StudyPlanViewModel()

  aboutToAppear(): void {
    this.vm.init(getContext(this)).then((): void => {
      if (this.vm.initError) {
        promptAction.showToast({ message: "数据加载失败，请重启应用", duration: 2000 })
      }
    })
  }

  build() {
    Column() {
      Row().width('100%').height(this.sbh).backgroundColor(BG_DARK)
      PlanHeader({ vm: this.vm })
      PlanStatsBar({ vm: this.vm })
      PlanListView({ vm: this.vm })
      PlanInputBar({ vm: this.vm })
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
