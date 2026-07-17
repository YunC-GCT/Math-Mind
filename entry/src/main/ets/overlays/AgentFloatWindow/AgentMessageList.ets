/**
 * AgentMessageList.ets — AI 浮窗消息列表区
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentMessageList.ets
 * 职责: Scroll 消息列表，委托 prototypes/chat/ 组件渲染气泡/打字/空状态
 * 依赖: common, prototypes/chat/ChatBubble, TypingIndicator, EmptyStateHint
 */

import {
  F_XS, F_SM, F_BASE, F_LG, W_BOLD,
} from 'common';
import { ChatBubble } from '../../prototypes/chat/ChatBubble';
import { TypingIndicator } from '../../prototypes/chat/TypingIndicator';
import { EmptyStateHint } from '../../prototypes/chat/EmptyStateHint';
import { ChatMsg } from '../../prototypes/chat/ChatModels';

@Component
export struct AgentMessageList {
  @Prop messages: ChatMsg[] = [];
  @Prop busy: boolean = false;

  build() {
    Scroll() {
      Column() {
        if (this.messages.length === 0 && !this.busy) {
          EmptyStateHint();
        }

        ForEach(this.messages, (msg: ChatMsg) => {
          ChatBubble({
            msg: msg,
            onCopy: (_text: string): void => {},
            onRegen: (_m: ChatMsg): void => {},
            onFeedback: (_m: ChatMsg): void => {},
          });
        }, (msg: ChatMsg) => msg.id.toString());

        if (this.busy) {
          TypingIndicator();
        }

        Blank().height(4);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 });
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring);
  }
}
