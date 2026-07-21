// ============================================================================
//  overlays/AgentFloatWindow/chat/ChatBubble.ets - message bubble
// ============================================================================

import {
  MINT, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  S_1, S_2, S_3, R_MD, F_SM, W_SEMIBOLD,
} from 'common'
import { ChatMsg, ChatStatusMeta } from './ChatModels'
import { MathTextRenderer } from '../../../shared/components/MathTextRenderer'

@Component
export struct ChatBubble {
  @Prop msg: ChatMsg = { id: 0, role: 'ai', content: '', ts: 0 }
  @Prop statusMeta: ChatStatusMeta | null = null
  @Prop transient: boolean = false
  onCopy: (text: string) => void = (_text: string): void => {}
  onRegen: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}
  onFeedback: (msg: ChatMsg) => void = (_msg: ChatMsg): void => {}

  build() {
    Column() {
      if (this.msg.role === 'user') {
        Row() {
          Blank()
          Column() {
            Column() {
              if (this.containsFormulaSyntax(this.msg.content)) {
                MathTextRenderer({
                  text: this.msg.content,
                  profile: 'chatUser',
                  textColor: TEXT,
                  formulaColor: TEXT,
                  formulaBackground: 'rgba(10,12,16,0.18)',
                  formulaBorder: 'rgba(255,255,255,0.18)',
                  fontSize: F_SM,
                  lineHeight: 20,
                  formulaFontSize: F_SM,
                  formulaLineHeight: 20,
                })
                .width('100%')
              } else {
                Text(this.msg.content)
                  .fontSize(F_SM)
                  .fontColor(TEXT)
                  .lineHeight(20)
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
            }
            .width('100%')
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
            .backgroundColor('rgba(31,143,101,0.82)')
            .border({ width: 0.5, color: MINT })
            .constraintSize({ maxWidth: '78%' })
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

            Column() {
              if (this.msg.content.trim().length > 0) {
                if (this.containsFormulaSyntax(this.msg.content)) {
                  MathTextRenderer({
                    text: this.msg.content,
                    profile: 'chat',
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
                } else {
                  Text(this.msg.content)
                    .fontSize(F_SM)
                    .fontColor(TEXT_2)
                    .lineHeight(20)
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
              }

              if (this.statusMeta !== null && this.statusMeta.step !== 'completed') {
                this.StatusMetaLine(this.statusMeta)
              }
            }
            .width('100%')
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
            .backgroundColor(this.msg.content.length > 240 ? 'rgba(255,255,255,0.035)' : PURPLE_LIGHT)
            .constraintSize({ maxWidth: this.msg.content.length > 240 ? '94%' : '88%' })

            if (!this.transient) {
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
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
        }
        .width('100%')
        .margin({ top: S_2 })
      }
    }
  }

  private containsFormulaSyntax = (text: string): boolean => {
    return text.indexOf('$$') >= 0
      || text.indexOf('$') >= 0
      || text.indexOf('\\[') >= 0
      || text.indexOf('\\]') >= 0
      || text.indexOf('\\(') >= 0
      || text.indexOf('\\)') >= 0
      || text.indexOf('\\frac') >= 0
      || text.indexOf('\\sqrt') >= 0
      || text.indexOf('\\sum') >= 0
      || text.indexOf('\\int') >= 0
      || text.indexOf('\\lim') >= 0
      || text.indexOf('\\begin') >= 0
      || text.indexOf('\\alpha') >= 0
      || text.indexOf('\\beta') >= 0
      || text.indexOf('\\theta') >= 0
      || (text.indexOf('=') >= 0 && (text.indexOf('^') >= 0 || text.indexOf('_') >= 0))
  }

  @Builder StatusMetaLine(meta: ChatStatusMeta | null) {
    if (meta !== null) {
      Row() {
        LoadingProgress()
          .width(9)
          .height(9)
          .color(MINT)
        Text(meta.title)
          .fontSize(10)
          .fontColor(TEXT_3)
          .fontWeight(W_SEMIBOLD)
          .margin({ left: S_1 })
        Text('·')
          .fontSize(10)
          .fontColor(TEXT_4)
          .margin({ left: S_1, right: S_1 })
        Text(meta.detail)
          .fontSize(10)
          .fontColor(TEXT_4)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .height(16)
      .margin({ top: S_1 })
    }
  }
}
