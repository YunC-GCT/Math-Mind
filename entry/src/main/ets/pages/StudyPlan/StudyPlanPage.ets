// ============================================================================
//  pages/StudyPlan/StudyPlanPage.ets — 学习计划页面(编排层)
//  ----------------------------------------------------------------------------
//  职责: 页面骨架布局 + ViewModel 桥接到原子组件。
//
//  布局:
//    [状态栏占位]
//    [PlanHeader 标题 + 智能生成按钮]
//    [PlanStatsBar 进度统计]
//    [PlanListView 计划列表]
//    [PlanInputBar 底部输入栏]
//
//  MVVM 模式:
//    - ViewModel: StudyPlanViewModel(init/load/CRUD/generatePlan)
//    - View:      StudyPlanPage + 4 个子组件,只负责渲染和事件转发
//
//  依赖:
//    pages:      PlanHeader / PlanStatsBar / PlanListView / PlanInputBar
//    viewmodels: StudyPlanViewModel
//    common:     BG_DARK
//
//  对接:
//    - 持久化: StudyPlanDao (RDB study_plan 表)
//    - AI 生成: LlmClient.call(),按钮调用 vm.generatePlan()
//    - 关联笔记: linkedNoteId 字段对接 KnowledgeUnit.id
//
//  来源: 2026-07-17 pages 重组(从 StudyPlanPage 单文件拆出 4 个子组件)
//  ============================================================================

import {
  BG_DARK,
} from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { promptAction } from "@kit.ArkUI"
import { PlanHeader } from "./PlanHeader"
import { PlanStatsBar } from "./PlanStatsBar"
import { PlanListView } from "./PlanListView"
import { PlanInputBar } from "./PlanInputBar"

@Entry
@Component
export struct StudyPlanPage {
  // 状态栏高度(沉浸式占位)
  @StorageProp('statusBarHeight') sbh: number = 0

  // 页面 ViewModel(init/CRUD/AI 生成)
  @State vm: StudyPlanViewModel = new StudyPlanViewModel()

  aboutToAppear(): void {
    this.vm.init(getContext(this)).then((): void => {
      // 初始化失败提示(降级: 空列表 + toast)
      if (this.vm.initError) {
        promptAction.showToast({ message: "数据加载失败,请重启应用", duration: 2000 })
      }
    })
  }

  build() {
    Column() {
      // 状态栏占位
      Row()
        .width('100%')
        .height(this.sbh)
        .backgroundColor(BG_DARK)

      // 标题 + 智能生成按钮
      PlanHeader({ vm: this.vm })

      // 进度统计
      PlanStatsBar({ vm: this.vm })

      // 计划列表(占满剩余高度)
      PlanListView({ vm: this.vm })

      // 底部输入栏
      PlanInputBar({ vm: this.vm })
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
