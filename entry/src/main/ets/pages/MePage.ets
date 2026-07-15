/**
 * MathMind 个人中心页 — 对照 iOS Web MVP page-me
 *
 * W2 原子化 (2026-07-15): SBox→StatsBox, MenuItem→MenuItemRow, 硬编码→令牌
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BG_CARD,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  S_1,
  S_2,
  S_3,
  S_4, S_6,
  R_MD,
  R_LG,
  R_FULL,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  F_LG,
  F_XL,
  F_2XL,
  W_BOLD,
  GLASS_8,
  DANGER,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { router } from "@kit.ArkUI"
import { StatsBox } from "../atoms/StatsBox"
import { MenuItemRow } from "../atoms/MenuItemRow"

@Component
export struct MePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: number = 12
  @State avg: number = 78

  aboutToAppear(): void {
    // TODO: 从 RDB 加载真实统计数据
  }

  private todayNew(): number {
    return 3
  }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
  }

  build() {
    Scroll() {
      Column() {
        // ---- 状态栏占位 ----
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // ---- 头像区 ----
        Column() {
          Stack() {
            Circle({ width: 72, height: 72 })
              .fill(GLASS_10)
            Text("M")
              .fontSize(28)
              .fontWeight(W_BOLD)
              .fontColor(MINT)
          }
          .margin({ bottom: 12 })

          Text("Mini")
            .fontSize(F_XL)
            .fontWeight(W_BOLD)
            .fontColor(TEXT)

          Text("数学爱好者 · 学习 30 天")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 4 })
        }
        .width("100%")
        .padding({ top: 24, bottom: 24 })
        .alignItems(HorizontalAlign.Center)

        // ---- 统计行 ----
        Row() {
          StatsBox({ value: this.notes + "", label: "笔记" })
          StatsBox({ value: this.avg + "%", label: "掌握率" })
          StatsBox({ value: this.todayNew() + "", label: "今日新增" })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_4 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // ---- 菜单 ----
        Column() {
          MenuItemRow({
            icon: "📋",
            label: "我的复习计划",
            onTap: (): void => this.toast("复习计划开发中"),
          })
          MenuItemRow({
            icon: "📕",
            label: "错题本",
            onTap: (): void => this.toast("错题本开发中"),
          })
          MenuItemRow({
            icon: "⭐",
            label: "我的收藏",
            onTap: (): void => this.toast("收藏功能开发中"),
          })
          MenuItemRow({
            icon: "🤖",
            label: "模型",
            onTap: (): void => { router.pushUrl({ url: "pages/AiSettingsPage" }) },
          })
          MenuItemRow({
            icon: "🚪",
            label: "切换账号",
            onTap: (): void => this.toast("切换账号开发中"),
          })
        }
        .width("100%")
        .backgroundColor(BG_CARD)
        .borderRadius(R_LG)
        .margin({ left: S_4, right: S_4, top: S_2 })

        // ---- 退出登录 ----
        Button("退出登录")
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%")
          .height(44)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: 40 })
          .onClick((): void => this.toast("退出登录功能开发中"))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
