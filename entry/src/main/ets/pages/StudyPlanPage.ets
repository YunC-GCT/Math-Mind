// ============================================================================
//  pages/StudyPlanPage.ets 鈥?瀛︿範璁″垝椤甸潰锛堢紪鎺掑眰锛?//  ----------------------------------------------------------------------------
//  鑱岃矗: 椤甸潰楠ㄦ灦甯冨眬 + ViewModel 妗ユ帴鍒板師瀛愮粍浠躲€?//  鏉ユ簮: 鍩轰簬 swiftui-to-arkui TodoPage锛屾媶鍒嗕负 PlanItemRow / PriorityBadge 鍘熷瓙缁勪欢銆?//
//  瀵规帴:
//    - 鎸佷箙鍖? 宸插鎺?鈫?StudyPlanDao (RDB study_plan 琛?
//    - AI 鐢熸垚: 宸插鎺?鈫?LlmClient.call()锛屾寜閽皟鐢?vm.generatePlan()
//    - 鍏宠仈绗旇: linkedNoteId 瀛楁宸插鎺?KnowledgeUnit.id
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
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
export struct StudyPlanPage {
  @StorageProp('statusBarHeight') sbh: number = 0
  @State vm: StudyPlanViewModel = new StudyPlanViewModel()

  aboutToAppear(): void {
    this.vm.init(getContext(this)).then((): void => {
      if (this.vm.initError) {
        promptAction.showToast({ message: "鏁版嵁鍔犺浇澶辫触锛岃閲嶅惎搴旂敤", duration: 2000 })
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
  //  @Builder 瀛愮粍浠讹紙浠呴〉闈㈢骇楠ㄦ灦锛?  // ====================================================================
  //  @Builder 子组件（仅页面级骨架 — 不抽为 @Component 的原因：
  //  每个 @Builder 直接访问 this.vm，抽离需穿 @Prop 链，无复用收益）

  @Builder
  HeaderBar() {
    Row() {
      Text("瀛︿範璁″垝")
        .fontSize(F_2XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)

      Blank()

      Text(this.vm.isLoading ? "鈴?鐢熸垚涓?.." : "馃 鏅鸿兘鐢熸垚")
        .fontSize(F_XS)
        .fontColor(this.vm.isLoading ? MINT : TEXT_3)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .border({ width: 1, color: this.vm.isLoading ? MINT : BORDER, radius: R_FULL })
        .onClick((): void => {
          if (this.vm.isLoading) {
            return
          }
          const knownTitles: string[] = []
          for (let i: number = 0; i < this.vm.items.length; i++) {
            knownTitles.push(this.vm.items[i].title)
          }
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
        Text("鉁?)
          .fontSize(F_MD)
          .fontColor(MINT)
        Text(`${this.vm.completedCount}/${this.vm.totalCount} 宸插畬鎴恅)
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
        Text("鏆傛棤璁″垝")
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
        placeholder: "鏂板瀛︿範璁″垝...",
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

      Button("锛?)
        .fontSize(28)
        .fontColor(MINT)
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
