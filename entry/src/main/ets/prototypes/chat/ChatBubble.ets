// ============================================================================
//  prototypes/chat/ChatBubble.ets — 消息气泡(用户/AI)
//  ----------------------------------------------------------------------------
//  职责: 渲染单条聊天气泡(user 右对齐 mint 浅底 / AI 左对齐 purple 浅底)。
//
//  AI 气泡带操作按钮: Copy / Retry / Flag
//
//  Props:
//    msg:       ChatMsg 消息数据
//    onCopy:    复制消息内容回调
//    onRegen:   重新生成回复回调
//    onFeedback: 反馈标记回调
//
//  依赖:
//    ./ChatModels:        ChatMsg 类型
//    ./ChatTextSanitizer: cleanMarkdown(markdown/LaTeX → 纯文本)
//
//  来源: 从 AgentFloatWindow 内联 @Builder 拆出
//  ============================================================================

import {
  MINT_DARK, MINT_LIGHT, PURPLE_LIGHT,
  TEXT_2, TEXT_4,
  S_1, S_2, S_3, R_MD, F_SM, W_SEMIBOLD,
} from "common"
import { ChatMsg } from "./ChatModels"
import { cleanMarkdown } from "./ChatTextSanitizer"

@Component
export struct ChatBubble {
  // 消息数据
  @Prop msg: ChatMsg = { id: 0, role: "ai", content: "", ts: 0 }

  // 复制按钮回调
  onCopy: (text: string) => void = (_text: string): void => {}

  // 重新生成回调
  onRegen: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  // 反馈标记回调
  onFeedback: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  build() {
    Column() {
      if (this.msg.role === "user") {
        // 用户气泡(右对齐 mint 浅底)
        Row() {
          Blank()
          Column() {
            Text(this.msg.content)
              .fontSize(F_SM)
              .fontColor(MINT_DARK)
              .lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              // 圆角:右下小角(尾巴效果)
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
              .backgroundColor(MINT_LIGHT)
              .constraintSize({ maxWidth: "88%" })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width("100%")
        .margin({ top: S_2 })
      } else {
        // AI 气泡(左对齐 purple 浅底 + 操作行)
        Row() {
          Column() {
            // AI 标签
            Text("AI")
              .fontSize(9)
              .fontColor(TEXT_4)
              .fontWeight(W_SEMIBOLD)
              .margin({ bottom: S_1, left: S_1 })

            // 消息内容(保留原始 LaTeX)
            Text(this.msg.content)
              .fontSize(F_SM)
              .fontColor(TEXT_2)
              .lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              // 圆角:左下小角(尾巴效果)
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
              .backgroundColor(PURPLE_LIGHT)
              .constraintSize({ maxWidth: "92%" })

            // 操作行: Copy / Retry / Flag
            Row() {
              Text("Copy")
                .fontSize(9)
                .fontColor(TEXT_4)
                .fontWeight(W_SEMIBOLD)
                .padding({ top: S_1, right: S_2 })
                .onClick((): void => { this.onCopy(this.msg.content) })
              Text("Retry")
                .fontSize(9)
                .fontColor(TEXT_4)
                .fontWeight(W_SEMIBOLD)
                .padding({ top: S_1 })
                .onClick((): void => { this.onRegen(this.msg) })
              Text("Flag")
                .fontSize(9)
                .fontColor(TEXT_4)
                .fontWeight(W_SEMIBOLD)
                .padding({ top: S_1, left: S_2 })
                .onClick((): void => { this.onFeedback(this.msg) })
            }
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
        }
        .width("100%")
        .margin({ top: S_2 })
      }
    }
  }
}
