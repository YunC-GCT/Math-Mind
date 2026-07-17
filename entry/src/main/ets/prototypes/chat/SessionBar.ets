// ============================================================================
//  prototypes/chat/SessionBar.ets — 会话切换栏
//  ----------------------------------------------------------------------------
//  职责: 水平滚动的会话标签列表,支持切换/删除/新建。
//
//  UI:
//    [● 会话1] [○ 会话2 ✕] [○ 会话3 ✕] ... [+]
//    ● 当前激活(MINT 高亮) / ○ 非激活(灰色)
//
//  Props:
//    sessions:   会话列表 [{id, name}]
//    activeSid:  当前激活会话 ID
//    onSwitch:   切换会话回调
//    onDelete:   删除会话回调(只在会话数 > 1 时显示 ✕)
//    onNew:      新建会话回调
//
//  依赖: common ColorTokens (MINT/MINT_LIGHT/TEXT_3/TEXT_4/GLASS_10)
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { MINT, MINT_LIGHT, TEXT_3, TEXT_4, S_1, S_2, R_FULL, F_XS, F_SM, W_MEDIUM, GLASS_10 } from "common"
import { ChatSession } from "./ChatModels"

@Component
export struct SessionBar {
  // 会话列表
  @Prop sessions: ChatSession[] = []

  // 当前激活会话 ID
  @Prop activeSid: string = ""

  // 切换会话回调
  onSwitch: (sid: string) => void = (_sid: string): void => {}

  // 删除会话回调
  onDelete: (sid: string) => void = (_sid: string): void => {}

  // 新建会话回调
  onNew: () => void = (): void => {}

  build() {
    Row() {
      // 横向滚动容器
      Scroll() {
        Row() {
          // 会话标签
          ForEach(this.sessions, (s: ChatSession): void => {
            Row() {
              // ●/○ 状态 + 名称
              Text(s.id === this.activeSid ? "● " + s.name : "○ " + s.name)
                .fontSize(F_XS)
                .fontColor(s.id === this.activeSid ? MINT : TEXT_3)
                .fontWeight(W_MEDIUM)

              // ✕ 删除按钮(只有 > 1 个会话时才显示)
              if (this.sessions.length > 1) {
                Text("✕")
                  .fontSize(9)
                  .fontColor(TEXT_4)
                  .margin({ left: S_1 })
                  .onClick((): void => { this.onDelete(s.id) })
              }
            }
            .padding({ left: S_2, right: S_2, top: S_1, bottom: S_1 })
            .borderRadius(R_FULL)
            // 激活: mint 浅底;非激活: glass 灰底
            .backgroundColor(s.id === this.activeSid ? MINT_LIGHT : GLASS_10)
            .margin({ right: S_2 })
            .onClick((): void => { this.onSwitch(s.id) })
          },
          // ForEach keyGenerator 必填
          (s: ChatSession): string => s.id)

          // [+] 新建按钮
          Text("+")
            .fontSize(F_SM)
            .fontColor(TEXT_3)
            .width(28).height(28)
            .borderRadius(14)
            .textAlign(TextAlign.Center)
            .backgroundColor(GLASS_10)
            .onClick((): void => { this.onNew() })
        }
        .padding({ left: S_2, right: S_2 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width("100%")
    .height(36)
    .padding({ top: S_1, bottom: S_1 })
  }
}
