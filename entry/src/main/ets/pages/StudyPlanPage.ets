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
  MINT,
  BG_DARK,
  BG_CARD,
  TEXT,
  TEXT_2,
  TEXT_3,
  BORDER,
  S_4,
  S_5,
  R_FULL,
  F_XS,
  F_BASE,
  F_MD,
  F_2XL,
  W_BOLD, GLASS_8,
} from "common"
import { StudyPlanItem } from "common"
import { StudyPlanViewModel } from "../viewmodels/StudyPlanViewModel"
import { PlanItemRow } from "../molecules/PlanItemRow"
import { AppIcon } from "../atoms/AppIcon"
import { promptAction } from "@kit.ArkUI"

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
      this.HeaderBar()
      this.StatsBar()
      this.PlanList()
      this.InputBar()
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }

  // ====================================================================
  //  @Builder 子组件（仅页面级骨架 — 不抽为 @Component 的原因：
  //  每个 @Builder 直接访问 this.vm，抽离需穿 @Prop 链，无复用收益）
  // ====================================================================

  @Builder
  HeaderBar() {
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

  @Builder
  StatsBar() {
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


  @Builder
  PlanList() {
    List() {
      ForEach(this.vm.items,
        (item: StudyPlanItem, _idx: number): void => {
          ListItem() {
            PlanItemRow({
              title: item.title,
              isDone: item.isDone,
              priority: item.priority,
              linkedNoteId: item.linkedNoteId,
              onToggle: (): void => { this.vm.toggleItem(item) },
            })
          }

        },
        (item: StudyPlanItem): string => item.id
      )
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: BORDER })
  }

  @Builder
  InputBar() {
    Row({ space: 8 }) {
      TextInput({
        placeholder: "新增学习计划...",
        text: this.vm.newTitle,
      })
      .onChange((value: string): void => { this.vm.newTitle = value })
      .onSubmit((): void => { this.vm.addItem() })
      .layoutWeight(1)
      .height(44)
      .borderRadius(R_FULL)
      .backgroundColor(BG_CARD)
      .padding({ left: 16, right: 16 })
      .fontColor(TEXT)
      .placeholderColor(TEXT_3)

      Button() {
        AppIcon({ name: "plus", iconSize: 22, color: MINT, strokeWidth: 2.2 })
      }
        .backgroundColor(GLASS_8)
        .onClick((): void => { this.vm.addItem() })
        .enabled(this.vm.newTitle.trim().length > 0)
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: 12, bottom: 12 })
    .backgroundColor(BG_CARD)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
