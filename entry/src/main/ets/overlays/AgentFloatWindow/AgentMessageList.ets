/**
 * AgentMessageList.ets — AI 浮窗消息列表
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentMessageList.ets
 * 职责: Scroll 消息列表 + 空状态 + 处理中临时 AI 气泡
 * 依赖: ChatBubble, EmptyStateHint, ChatModels
 */

import { S_2, S_4 } from 'common';
import { ChatBubble } from './chat/ChatBubble';
import { EmptyStateHint } from './chat/EmptyStateHint';
import { ChatMsg, ChatStatusMeta } from './chat/ChatModels';

@Component
export struct AgentMessageList {
  @Prop messages: ChatMsg[] = [];
  @Prop busy: boolean = false;
  @Prop statusMeta: ChatStatusMeta | null = null;
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

        if (this.busy) {
          this.TransientStatusBubble(this.statusMeta);
        }

        Blank().height(S_2);
      }
      .width('100%').padding({ left: S_4, right: S_4, top: S_2 });
    }
    .layoutWeight(1).width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring);
  }

  @Builder TransientStatusBubble(meta: ChatStatusMeta | null) {
    if (meta !== null && meta.step !== 'completed') {
      ChatBubble({
        msg: {
          id: -1,
          role: 'ai',
          content: '',
          ts: 0,
        },
        statusMeta: meta,
        transient: true,
        onCopy: (_text: string): void => {},
        onFeedback: (_msg: ChatMsg): void => {},
        onRegen: (_msg: ChatMsg): void => {},
      });
    }
  }
}
