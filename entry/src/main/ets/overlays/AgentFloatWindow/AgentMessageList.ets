/**
 * AgentMessageList.ets — AI 浮窗消息列表
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentMessageList.ets
 * 职责: Scroll 消息列表 + 空状态 + 打字指示器 · 引用 prototypes/chat/ 组件
 * 依赖: ChatBubble, EmptyStateHint, TypingIndicator, ChatModels
 */

import { S_2, S_4 } from 'common';
import { ChatBubble } from '../../prototypes/chat/ChatBubble';
import { EmptyStateHint } from '../../prototypes/chat/EmptyStateHint';
import { TypingIndicator } from '../../prototypes/chat/TypingIndicator';
import { ChatMsg } from '../../prototypes/chat/ChatModels';

@Component
export struct AgentMessageList {
  @Prop messages: ChatMsg[] = [];
  @Prop busy: boolean = false;
  scroller: Scroller = new Scroller();
  onRetry: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {};

  build() {
    Scroll(this.scroller) {
      Column() {
        if (this.messages.length === 0 && !this.busy) { EmptyStateHint(); }

        ForEach(this.messages,
          (msg: ChatMsg): void => {
            ChatBubble({
              msg: msg,
              onCopy: (_text: string): void => {},
              onFeedback: (_msg: ChatMsg): void => {},
              onRegen: (retryMsg: ChatMsg): void => { this.onRetry(retryMsg); },
            });
          },
          (msg: ChatMsg): string => msg.id.toString()
        );

        if (this.busy && this.messages.length > 0) { TypingIndicator(); }

        Blank().height(S_2);
      }
      .width('100%').padding({ left: S_4, right: S_4, top: S_2 });
    }
    .layoutWeight(1).width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring);
  }
}
