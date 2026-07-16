/**
 * ==========================================================================
 *  SessionBar.ets — 会话切换栏组件
 *  ==========================================================================
 *  职责: 水平滚动的会话标签列表, 支持切换/删除/新建。
 *
 *  UI:
 *    [● 会话1] [○ 会话2 ✕] [○ 会话3 ✕] ... [+]
 *    ● 当前激活 (MINT 高亮) / ○ 非激活 (灰色)
 *
 *  接口:
 *    @Prop sessions    — 会话列表 [{id, name}]
 *    @Prop activeSid   — 当前激活会话 ID
 *    onSwitch(sid)     — 切换会话回调
 *    onDelete(sid)     — 删除会话回调
 *    onNew()           — 新建会话回调
 *
 *  依赖: common ColorTokens (MINT_MINT_LIGHT/TEXT_3/TEXT_4/GLASS_10)
 * ==========================================================================
 */// chat/SessionBar.ets — 会话切换栏
import { MINT, MINT_LIGHT, TEXT_3, TEXT_4, S_1, S_2, R_FULL, F_XS, F_SM, W_MEDIUM, GLASS_10 } from "common"

interface Session { id: string; name: string; messages: object[] }

@Component
export struct SessionBar {
  @Prop sessions: Session[] = []
  @Prop activeSid: string = ""
  onSwitch?: (sid: string) => void
  onDelete?: (sid: string) => void
  onNew?: () => void

  build() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.sessions, (s: Session): void => {
            Row() {
              Text(s.id === this.activeSid ? "\u25CF " + s.name : "\u25CB " + s.name)
                .fontSize(F_XS).fontColor(s.id === this.activeSid ? MINT : TEXT_3).fontWeight(W_MEDIUM)
              if (this.sessions.length > 1) { Text("\u2715").fontSize(9).fontColor(TEXT_4).margin({ left: S_1 }).onClick((): void => { if (this.onDelete) { this.onDelete(s.id) } }) }
            }.padding({ left: S_2, right: S_2, top: S_1, bottom: S_1 }).borderRadius(R_FULL)
             .backgroundColor(s.id === this.activeSid ? MINT_LIGHT : GLASS_10).margin({ right: S_2 })
             .onClick((): void => { if (this.onSwitch) { this.onSwitch(s.id) } })
          }, (s: Session): string => s.id)
          Text("+").fontSize(F_SM).fontColor(TEXT_3).width(28).height(28).borderRadius(14).textAlign(TextAlign.Center).backgroundColor(GLASS_10)
            .onClick((): void => { if (this.onNew) { this.onNew() } })
        }.padding({ left: S_2, right: S_2 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width("100%").height(36).padding({ top: S_1, bottom: S_1 })
  }
}
