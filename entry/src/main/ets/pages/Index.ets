/**
 * MathMind 主容器 — 5 Tab 底部导航（含中央 AI 渐变凸起圆）
 * W3 编码修复 + UI 优化: Tab 文字还原、字号令牌化、间距统一
 */

import {
  MINT, MINT_DARK, PURPLE, BG_DARK, BORDER,
  TEXT, TEXT_2, TEXT_3,
  S_1, S_2,
  F_XS, F_BASE, F_3XL,
  W_MEDIUM,
} from "common"
import { HomePage } from "./HomePage"
import { NotesPage } from "./NotesPage"
import { ReviewPage } from "./ReviewPage"
import { MePage } from "./MePage"
import { AgentFloatWindow } from "../prototypes/AgentFloatWindow"
import { CameraOverlay } from "../prototypes/CameraOverlay"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"

interface TabItem {
  idx: number
  name: string
  icon: Resource
}

const TABS: TabItem[] = [
  { idx: 0, name: "首页", icon: $r("app.media.ic_home") },
  { idx: 1, name: "笔记", icon: $r("app.media.ic_notes") },
  { idx: 2, name: "AI",   icon: $r("app.media.ic_ai") },
  { idx: 3, name: "复习", icon: $r("app.media.ic_review") },
  { idx: 4, name: "我的", icon: $r("app.media.ic_me") },
]

@Entry
@Component
struct Index {
  @State cur: number = 0
  @State showCamera: boolean = false
  @State pendingImageUri: string = ""
  @State showAgentFloat: boolean = false
  private tc: TabsController = new TabsController()

  private isTabActive(i: number): boolean {
    return this.cur === i
  }

  aboutToAppear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
    } catch (e) {
      // 降级: 键盘避让失败不影响主流程
    }
  }

  private onCameraConfirm = (uri: string, _src: "camera" | "album"): void => {
    this.showCamera = false
    this.showAgentFloat = true
    this.pendingImageUri = uri
    setTimeout((): void => { this.pendingImageUri = "" }, 100)
  }

  private closeAgentFloat = (): void => { this.showAgentFloat = false }

  private goCameraFromAgent = (): void => {
    this.showAgentFloat = false
    this.showCamera = true
  }

  build() {
    Stack() {
      Column() {
        // ===== 内容区 5 Tab =====
        Tabs({ index: this.cur, controller: this.tc }) {
          TabContent() {
            HomePage({
              onGoCamera: (): void => { this.showCamera = true },
              onGoReview: (): void => { this.cur = 3; this.tc.changeIndex(3) },
            })
          }
          TabContent() { NotesPage() }
          TabContent() {
            Column().width("100%").height("100%").backgroundColor(BG_DARK)
          }
          TabContent() {
            ReviewPage({
              onGoAI: (): void => {
                promptAction.showToast({ message: "AI 对话功能开发中", duration: 1500 })
              }
            })
          }
          TabContent() { MePage() }
        }
        .barHeight(0)
        .layoutWeight(1)
        .scrollable(false)
        .onChange((i: number): void => {
          this.cur = i
          if (i === 2) { this.showAgentFloat = true }
        })

        // ===== 自定义 TabBar 74vp =====
        Row() {
          ForEach(TABS,
            (tab: TabItem, i: number): void => {
              if (i === 2) {
                this.AiBtn(i)
              } else {
                this.TabBtn(tab, i)
              }
            },
            (tab: TabItem): string => tab.idx.toString()
          )
        }
        .width("100%").height(74)
        .padding({ left: 6, right: 6, bottom: 10 })
        .linearGradient({
          angle: 180,
          colors: [[MINT_DARK + "00", 0], [BG_DARK, 1]],
        })
        .backdropBlur(24)
        .border({ width: { top: 1 }, color: BORDER })
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
      }
      .width("100%").height("100%").backgroundColor(BG_DARK)

      // ===== 全局 CameraOverlay =====
      if (this.showCamera) {
        CameraOverlay({
          onClose: (): void => { this.showCamera = false },
          onConfirm: this.onCameraConfirm,
        })
      }

      // ===== 全局 AgentFloatWindow =====
      AgentFloatWindow({
        show: this.showAgentFloat,
        onClose: this.closeAgentFloat,
        onGoCamera: this.goCameraFromAgent,
        pendingImageUri: this.pendingImageUri,
      })
    }
    .width("100%").height("100%")
  }

  // ========== 普通 Tab 按钮 ==========
  @Builder
  TabBtn(tab: TabItem, i: number) {
    Column() {
      Image(tab.icon)
        .width(22).height(22)
        .fillColor(this.isTabActive(i) ? MINT : TEXT_3)
      Text(tab.name)
        .fontSize(F_XS).fontWeight(W_MEDIUM)
        .fontColor(this.isTabActive(i) ? MINT : TEXT_3)
        .margin({ top: S_1 })
    }
    .layoutWeight(1)
    .padding({ top: S_2, bottom: S_2 })
    .borderRadius(14)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => {
      this.cur = i
      this.tc.changeIndex(i)
    })
  }

  // ========== 中央 AI 渐变凸起圆 ==========
  @Builder
  AiBtn(_i: number) {
    Column() {
      Stack() {
        Image($r("app.media.ic_ai"))
          .width(20).height(20)
          .fillColor(BG_DARK)
      }
      .width(44).height(44).borderRadius(22)
      .linearGradient({
        angle: 135,
        colors: [[MINT, 0], [PURPLE, 1]],
      })
      .shadow({
        radius: 20,
        color: MINT + "73",
        offsetX: 0,
        offsetY: 6,
      })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => { this.showAgentFloat = true })
  }
}
