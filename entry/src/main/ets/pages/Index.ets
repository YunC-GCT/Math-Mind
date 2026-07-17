// ============================================================================
//  pages/Index.ets — 主容器装配层
//  ----------------------------------------------------------------------------
//  职责: 5 Tab 导航编排，管理 CameraOverlay / AgentFloatWindow 浮层状态。
//  数据流: @State cur → TabContent + TabBar，浮层状态由回调控制。
//  依赖:
//    molecules: TabBar
//    pages:     HomePage, NotesPage, ReviewPage, ProfilePage
//    prototypes: CameraOverlay, AgentFloatWindow
//  ============================================================================

import { BG_DARK } from "common"
import { HomePage } from "./Home/HomePage"
import { NotesPage } from "./Notes/NotesPage"
import { ReviewPage } from "./Review/ReviewPage"
import { ProfilePage } from "./Profile/ProfilePage"
import { TabBar } from "../molecules/TabBar"
import { AgentFloatWindow } from "../prototypes/AgentFloatWindow"
import { CameraOverlay } from "../prototypes/CameraOverlay"
import { AiService } from "../services/AiService"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"
import { common } from "@kit.AbilityKit"

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

  // 拍照/选图完成 → 触发整链 + 回 AI 浮窗
  // 整链: imageUri → AiService.capture() → Dispatcher → OcrTool → TypeClassifier → KnowledgeModel → NoteDao.insert()
  private onCameraConfirm = async (uri: string, _src: "camera" | "album"): Promise<void> => {
    this.showCamera = false
    this.showAgentFloat = true
    this.pendingImageUri = uri
    setTimeout((): void => { this.pendingImageUri = "" }, 100)

    try {
      const ctx = getContext(this) as common.UIAbilityContext
      const unit = await new AiService(ctx).capture(uri)
      try {
        promptAction.showToast({ message: "笔记已生成: " + unit.title, duration: 2000 })
      } catch (e) { /* toast 失败忽略 */ }
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e)
      try {
        promptAction.showToast({ message: "处理失败: " + errMsg.substring(0, 80), duration: 2500 })
      } catch (e) { /* toast 失败忽略 */ }
    }
  }

  private closeAgentFloat = (): void => { this.showAgentFloat = false }

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
