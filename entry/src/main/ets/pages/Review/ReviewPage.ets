// ============================================================================
//  pages/Review/ReviewPage.ets — 复习计划页
//  ----------------------------------------------------------------------------
//  职责: MVP 阶段复习页空状态 + 引导用户打开学习计划。
//
//  布局(垂直居中):
//    [状态栏占位]
//    [复习图标]
//    "学习计划"
//    "通过 AI 对话分析笔记后 / 自动生成个性化复习计划"
//    [打开学习计划] 按钮(跳转 StudyPlanPage)
//
//  依赖:
//    atoms: AppIcon
//    common 令牌: MINT / MINT_DARK / BG_DARK / TEXT / TEXT_3 / R_FULL /
//         F_SM / F_BASE / F_2XL / W_SEMIBOLD
//
//  Props:
//    onGoAI: 点击 AI 按钮回调(由 Index.ets 注入,目前 toast 提示)
//
//  来源: W3 refactor 状态栏避让 + 令牌化
//  ============================================================================

import {
  MINT, MINT_DARK, BG_DARK, TEXT, TEXT_3, R_FULL,
  F_SM, F_BASE, F_2XL, W_SEMIBOLD,
} from "common"
import { router } from "@kit.ArkUI"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct ReviewPage {
  // 状态栏高度(沉浸式占位)
  @StorageProp("statusBarHeight") sbh: number = 0

  // 外部回调(由 Index.ets 注入,默认空函数防未注入报错)
  onGoAI: () => void = (): void => {}

  build() {
    Column() {
      // 状态栏占位
      Row()
        .width("100%")
        .height(this.sbh)
        .backgroundColor(BG_DARK)

      Scroll() {
        Column() {
          Blank()

          // 空状态区(垂直居中)
          Column() {
            // 复习图标
            AppIcon({ name: "review", iconSize: F_2XL + 18, color: MINT, strokeWidth: 1.8 })
              .margin({ bottom: 12 })

            // 标题
            Text("学习计划")
              .fontSize(F_BASE + 1)
              .fontWeight(W_SEMIBOLD)
              .fontColor(TEXT)
              .margin({ bottom: 8 })

            // 副描述
            Text("通过 AI 对话分析笔记后\n自动生成个性化复习计划")
              .fontSize(F_SM + 1)
              .fontColor(TEXT_3)
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .margin({ bottom: 16 })

            // 跳转学习计划页按钮
            Button("打开学习计划")
              .fontSize(F_SM)
              .fontWeight(W_SEMIBOLD)
              .fontColor(BG_DARK)
              .width(140)
              .height(44)
              .borderRadius(R_FULL)
              .linearGradient({ angle: 135, colors: [[MINT, 0], [MINT_DARK, 1]] })
              .onClick((): void => {
                router.pushUrl({ url: "pages/StudyPlan/StudyPlanPage" })
              })
          }
          .alignItems(HorizontalAlign.Center)
          .width("100%")

          Blank()
        }
        .width("100%")
        .height("100%")
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
