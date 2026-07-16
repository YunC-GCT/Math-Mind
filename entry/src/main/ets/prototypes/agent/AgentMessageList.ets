import { S_2, S_4 } from "common"
import { ChatBubble } from "../chat/ChatBubble"
import { EmptyStateHint } from "../chat/EmptyStateHint"
import { TypingIndicator } from "../chat/TypingIndicator"
import { ChatMsg } from "../chat/ChatModels"

@Component
export struct AgentMessageList {
  @Prop messages: ChatMsg[] = []
  @Prop busy: boolean = false
  scroller: Scroller = new Scroller()
  onRetry: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  build() {
    Scroll(this.scroller) {
      Column() {
        if (this.messages.length === 0 && !this.busy) {
          EmptyStateHint()
        }
        ForEach(this.messages,
          (msg: ChatMsg): void => {
            ChatBubble({
              msg: msg,
              onCopy: (_text: string): void => {},
              onFeedback: (_msg: ChatMsg): void => {},
              onRegen: (retryMsg: ChatMsg): void => { this.onRetry(retryMsg) },
            })
          },
          (msg: ChatMsg): string => msg.id.toString()
        )
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
