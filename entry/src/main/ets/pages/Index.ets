// ============================================================================
//  pages/Index.ets — 主容器装配层
//  ----------------------------------------------------------------------------
//  职责: 5 Tab 导航编排，管理 CameraOverlay / AgentFloatWindow 浮层状态。
//  数据流: @State cur → TabContent + TabBar，浮层状态由回调控制。
//  依赖:
//    molecules: TabBar
//    pages:     HomePage, NotesPage, ReviewPage, ProfilePage
//    prototypes: CameraOverlay
//    overlays:   AgentFloatWindow
//  ============================================================================

import { BG_DARK } from "common"
import { HomePage } from "./Home/HomePage"
import { NotesPage } from "./Notes/NotesPage"
import { ReviewPage } from "./Review/ReviewPage"
import { ProfilePage } from "./Profile/ProfilePage"
import { TabBar } from "../molecules/TabBar"
import { AgentFloatWindow } from "../overlays/AgentFloatWindow"
import { CameraOverlay } from "../prototypes/CameraOverlay"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"

@Entry
@Component
struct Index {
  @State cur: number = 0
  @State showCamera: boolean = false
  @State pendingImageUri: string = ""
  @State showAgentFloat: boolean = false
  @State lastContentIndex: number = 0
  private tc: TabsController = new TabsController()

  aboutToAppear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
    } catch (e) {
      // 降级: 键盘避让失败不影响主流程
    }
  }

  // 拍照/选图完成 → 仅把图片传给 AI 浮窗(由用户点"发送"触发整链)
  // P1 修复: 旧版 (5b6f155) 选完图立刻跑 AiService.capture(), 用户无法编辑/取消
  // 新版: 跟文字一样, 走对话模式 — 选图后图片进浮窗 input, 用户写文字, 点"发送"才触发
  // 整链: imageUri + userText → AiService.capture(uri, userText) → Dispatcher → ... → NoteDao.insert()
  //
  // P1 修复 v2: 之前用 setTimeout(100ms) 清空 pendingImageUri, 跟 AgentFloatWindow 重新挂载时序冲突:
  //   showAgentFloat=true → AgentFloatWindow 挂载 → @Watch 默认不触发
  //   setTimeout 100ms 后清空 → 即便后续 @Watch 触发也是 ""→"", 不会存到 imagePreview
  //   用户点发送 → hasImage=false → 走 realReply 弹开场白
  // 现在: pendingImageUri 一直保留, 直到用户点发送后 AgentFloatWindow 自己清 imagePreview
  //   或用户主动关闭浮窗 (aboutToDisappear)
  private onCameraConfirm = (uri: string, _src: "camera" | "album"): void => {
    this.showCamera = false
    this.showAgentFloat = true
    // P1 修复 v3: 先清空再设值, 强制 @Watch 触发 (ArkUI 对相同字符串值不触发)
    //   选同一张图时, oldValue == newValue, @Watch 不调, imagePreview 不更新
    this.pendingImageUri = ""
    // 下一帧再设新值, 让 ArkUI 完成旧→新的同步
    setTimeout((): void => { this.pendingImageUri = uri }, 0)
    console.info('[Index.onCameraConfirm] uri=' + uri + ', showAgentFloat=true, pendingImageUri reset then set')
  }

  private closeAgentFloat = (): void => {
    this.showAgentFloat = false
    // P1 修复 v2: 浮窗关闭时清空 pendingImageUri, 避免下次开浮窗还显示旧图
    this.pendingImageUri = ""
  }

  private goCameraFromAgent = (): void => {
    this.showAgentFloat = false
    this.showCamera = true
  }

  build() {
    Stack() {
      Column() {
        // 内容区
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
                try { promptAction.showToast({ message: "AI 对话功能开发中", duration: 1500 }) } catch (e) {}
              }
            })
          }
          TabContent() { ProfilePage() }
        }
        .barHeight(0)
        .layoutWeight(1)
        .scrollable(false)
        .onChange((i: number): void => {
          if (i === 2) {
            this.showAgentFloat = true
            this.cur = this.lastContentIndex
            this.tc.changeIndex(this.lastContentIndex)
            return
          }
          this.cur = i
          this.lastContentIndex = i
        })

        // TabBar
        TabBar({
          cur: this.cur,
          onTabChange: (i: number): void => {
            this.cur = i
            this.tc.changeIndex(i)
          },
          onAiTap: (): void => { this.showAgentFloat = true },
        })
      }
      .width("100%").height("100%").backgroundColor(BG_DARK)

      // CameraOverlay
      if (this.showCamera) {
        CameraOverlay({
          onClose: (): void => { this.showCamera = false },
          onConfirm: this.onCameraConfirm,
        })
      }

      // AgentFloatWindow
      AgentFloatWindow({
        show: this.showAgentFloat,
        onClose: this.closeAgentFloat,
        onGoCamera: this.goCameraFromAgent,
        pendingImageUri: this.pendingImageUri,
      })
    }
    .width("100%").height("100%")
  }
}
