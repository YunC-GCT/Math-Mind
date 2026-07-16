// ============================================================================
//  pages/Index.ets 鈥?涓诲鍣ㄨ閰嶅眰
//  ----------------------------------------------------------------------------
//  鑱岃矗: 5 Tab 瀵艰埅缂栨帓锛岀鐞?CameraOverlay / AgentFloatWindow 娴眰鐘舵€併€?//  鏁版嵁娴? @State cur 鈫?TabContent + TabBar锛屾诞灞傜姸鎬佺敱鍥炶皟鎺у埗銆?//  渚濊禆:
//    molecules: TabBar
//    pages:     HomePage, NotesPage, ReviewPage, MePage
//    prototypes: CameraOverlay, AgentFloatWindow
//  ============================================================================

import { BG_DARK } from "common"
import { HomePage } from "./HomePage"
import { NotesPage } from "./NotesPage"
import { ReviewPage } from "./ReviewPage"
import { MePage } from "./MePage"
import { TabBar } from "../molecules/TabBar"
import { AgentFloatWindow } from "../prototypes/AgentFloatWindow"
import { CameraOverlay } from "../prototypes/CameraOverlay"
import { KeyboardAvoidMode } from "@kit.ArkUI"

@Entry
@Component
struct Index {
  @State cur: number = 0
  @State showCamera: boolean = false
  @State pendingImageUri: string = ""
  @State showAgentFloat: boolean = false
  private tc: TabsController = new TabsController()

  aboutToAppear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
    } catch (e) {
      // 闄嶇骇: 閿洏閬胯澶辫触涓嶅奖鍝嶄富娴佺▼
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
        // 鍐呭鍖?        Tabs({ index: this.cur, controller: this.tc }) {
          TabContent() {
            HomePage({
              onGoReview: (): void => { this.cur = 3; this.tc.changeIndex(3) },
            })
          }
          TabContent() { NotesPage() }
          TabContent() {
            Column().width("100%").height("100%").backgroundColor(BG_DARK)
          }
          TabContent() {
            ReviewPage()
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
