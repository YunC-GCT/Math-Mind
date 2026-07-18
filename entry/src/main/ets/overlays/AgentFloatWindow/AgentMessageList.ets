/**
 * AgentMessageList.ets — AI 浮窗消息列表
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentMessageList.ets
 * 职责: Scroll 消息列表 + 空状态 + 打字转圈
 * 依赖: ChatBubble, EmptyStateHint, ChatModels
 */

import { PURPLE, PURPLE_LIGHT, TEXT_3, F_XS, S_2, S_4 } from 'common';
import { ChatBubble } from './chat/ChatBubble';
import { EmptyStateHint } from './chat/EmptyStateHint';
import { ChatMsg } from './chat/ChatModels';

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

        if (this.busy) { this.TypingBubble(); }

        Blank().height(S_2);
      }
      .width('100%').padding({ left: S_4, right: S_4, top: S_2 });
    }
    .layoutWeight(1).width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring);
  }

  @Builder TypingBubble() {
    Row() {
      Row() {
        LoadingProgress().width(12).height(12).color(PURPLE);
        Text(' AI 思考中...').fontSize(F_XS).fontColor(TEXT_3).margin({ left: 4 });
      }
      .padding({ left: 10, right: 10, top: 8, bottom: 8 }).borderRadius(10).backgroundColor(PURPLE_LIGHT);
      Blank();
    }.width('100%').margin({ top: 6 });
  }
}
