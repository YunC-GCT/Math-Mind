// ============================================================================
//  prototypes/agent/AgentMessageList.ets — AI 浮窗消息列表
//  ----------------------------------------------------------------------------
//  职责: 滚动消息列表容器(空状态 / 消息列表 / 思考中指示器)。
//
//  渲染逻辑:
//    messages 为空且不忙 → EmptyStateHint
//    否则 → ForEach 渲染所有 ChatBubble
//    busy 时且有消息 → TypingIndicator 追加
//
//  Props:
//    messages:  ChatMsg[] 消息列表
//    busy:      boolean AI 是否在思考
//    scroller:  Scroller 滚动控制器(供外部滚动到底部)
//    onRetry:   重新生成某条 AI 消息的回调
//
//  依赖:
//    chat/ChatBubble:      单条消息气泡
//    chat/EmptyStateHint:  空状态引导
//    chat/TypingIndicator: AI 思考中动画
//    chat/ChatModels:      ChatMsg 类型
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { S_2, S_4 } from "common"
import { ChatBubble } from "../chat/ChatBubble"
import { EmptyStateHint } from "../chat/EmptyStateHint"
import { TypingIndicator } from "../chat/TypingIndicator"
import { ChatMsg } from "../chat/ChatModels"

@Component
export struct AgentMessageList {
  // 消息列表
  @Prop messages: ChatMsg[] = []

  // AI 是否在思考(显示 TypingIndicator)
  @Prop busy: boolean = false

  // 滚动控制器(供外部调用 scrollToEnd 等)
  scroller: Scroller = new Scroller()

  // 重新生成回调
  onRetry: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  build() {
    Scroll(this.scroller) {
      Column() {
        // 空状态:消息为 0 且不忙时显示引导
        if (this.messages.length === 0 && !this.busy) {
          EmptyStateHint()
        }

        // 消息列表
        ForEach(this.messages,
          (msg: ChatMsg): void => {
            ChatBubble({
              msg: msg,
              // 复制 / 反馈(暂未实现)
              onCopy: (_text: string): void => {},
              onFeedback: (_msg: ChatMsg): void => {},
              // 重新生成(转发给外部 onRetry)
              onRegen: (retryMsg: ChatMsg): void => { this.onRetry(retryMsg) },
            })
          },
          // ForEach keyGenerator 必填
          (msg: ChatMsg): string => msg.id.toString()
        )

        // 思考中指示器(有消息时)
        if (this.busy && this.messages.length > 0) {
          TypingIndicator()
        }

        Blank().height(S_2)
      }
      .width("100%")
      .padding({ left: S_4, right: S_4, top: S_2 })
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
