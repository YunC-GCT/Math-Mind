// ============================================================================
//  overlays/AgentFloatWindow/chat/ChatBubble.ets - message bubble
// ============================================================================

import {
  MINT_DARK, MINT_LIGHT, PURPLE_LIGHT,
  TEXT_2, TEXT_4,
  S_1, S_2, S_3, R_MD, F_SM, W_SEMIBOLD,
} from 'common'
import { ChatMsg } from './ChatModels'
import { MathTextRenderer } from '../../../shared/components/MathTextRenderer'

@Component
export struct ChatBubble {
  @Prop msg: ChatMsg = { id: 0, role: 'ai', content: '', ts: 0 }
  onCopy: (text: string) => void = (_text: string): void => {}
  onRegen: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}
  onFeedback: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  build() {
    Column() {
      if (this.msg.role === 'user') {
        Row() {
          Blank()
          Column() {
            MathTextRenderer({
              text: this.msg.content,
              textColor: MINT_DARK,
              formulaColor: MINT_DARK,
              formulaBackground: 'rgba(255,255,255,0.10)',
              formulaBorder: 'rgba(255,255,255,0.18)',
              fontSize: F_SM,
              lineHeight: 20,
              formulaFontSize: F_SM,
              formulaLineHeight: 20,
            })
            .width('100%')
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
            .backgroundColor(MINT_LIGHT)
            .constraintSize({ maxWidth: '88%' })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .margin({ top: S_2 })
      } else {
        Row() {
          Column() {
            Text('AI')
              .fontSize(9)
              .fontColor(TEXT_4)
              .fontWeight(W_SEMIBOLD)
              .margin({ bottom: S_1, left: S_1 })

            MathTextRenderer({
              text: this.msg.content,
              textColor: TEXT_2,
              formulaColor: TEXT_2,
              formulaBackground: 'rgba(255,255,255,0.06)',
              formulaBorder: 'rgba(255,255,255,0.12)',
              fontSize: F_SM,
              lineHeight: 20,
              formulaFontSize: F_SM,
              formulaLineHeight: 20,
            })
            .width('100%')
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
            .backgroundColor(PURPLE_LIGHT)
            .constraintSize({ maxWidth: '92%' })

            Row() {
              Text('Copy')
                .fontSize(9)
                .fontColor(TEXT_4)
                .fontWeight(W_SEMIBOLD)
                .padding({ top: S_1, right: S_2 })
                .onClick((): void => { this.onCopy(this.msg.content) })
              Text('Retry')
                .fontSize(9)
                .fontColor(TEXT_4)
                .fontWeight(W_SEMIBOLD)
                .padding({ top: S_1 })
                .onClick((): void => { this.onRegen(this.msg) })
              Text('Flag')
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
        .width('100%')
        .margin({ top: S_2 })
      }
    }
  }
}