/**
 * ==========================================================================
 *  ChatHeader.ets 鈥?娴獥澶撮儴缁勪欢
 *  ==========================================================================
 *  鑱岃矗: 鏄剧ず妯″瀷鍚?+ 鍦ㄧ嚎鐘舵€?+ 娣卞害鎬濊€冨紑鍏?+ 鏂板缓瀵硅瘽 + 鍏抽棴鎸夐挳銆? *
 *  UI:
 *    鈼?DeepSeek-V4   [鈼屄封棇 娣卞害鎬濊€僝  [+]  [鉁昡
 *
 *  鎺ュ彛:
 *    @Prop modelName       鈥?妯″瀷鍚?(榛樿 DeepSeek-V4)
 *    @Prop deepThink       鈥?娣卞害鎬濊€冨紑鍏崇姸鎬? *    onToggleThink()        鈥?鍒囨崲鎬濊€冩ā寮忓洖璋? *    onNewChat()            鈥?鏂板缓瀵硅瘽鍥炶皟
 *    onClose()              鈥?鍏抽棴娴獥鍥炶皟
 *
 *  渚濊禆: common ColorTokens + SVG Ellipse/Circle/Path
 * ==========================================================================
 */// chat/ChatHeader.ets 鈥?澶撮儴: 妯″瀷鍚?+ 娣卞害鎬濊€冭兌鍥?+ 鍏抽棴
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT, BG_DARK,
  TEXT, TEXT_2, TEXT_3, TEXT_4, S_1, S_2, S_3, S_4, S_6,
  R_FULL, F_XS, F_SM, F_BASE, F_MD, W_MEDIUM, W_SEMIBOLD, W_BOLD,
} from "common"

@Component
export struct ChatHeader {
  @Prop modelName: string = "DeepSeek-V4"
  @Prop deepThink: boolean = false
  onToggleThink?: () => void; onNewChat?: () => void
  onClose?: () => void
  build() {
    Row() {
      Circle({ width: 6, height: 6 }).fill(MINT).margin({ right: S_2 })
      Text(this.modelName).fontSize(F_XS).fontColor(TEXT_2).fontWeight(W_MEDIUM)
      Row() {
        Stack() {
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1)
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 60 })
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 120 })
          Circle({ width: 2, height: 2 }).fill(this.deepThink ? MINT : TEXT_3)
        }.width(12).height(12)
        Text(" \u6DF1\u5EA6\u601D\u8003").fontSize(F_XS).fontColor(this.deepThink ? MINT : TEXT_3).fontWeight(W_MEDIUM)
      }
      .padding({ left: S_3, right: S_3, top: S_1, bottom: S_1 }).borderRadius(R_FULL)
      .border({ width: 1, color: this.deepThink ? MINT : TEXT_4 })
      .backgroundColor(this.deepThink ? MINT_LIGHT : BG_DARK).margin({ left: S_4 })
      .onClick((): void => { if (this.onToggleThink) { this.onToggleThink() } })
      Text("+").fontSize(F_MD).fontColor(TEXT_3).width(32).height(44).textAlign(TextAlign.Center)
        .onClick((): void => { if (this.onNewChat) { this.onNewChat() } })
      Blank()
      Stack() {
        Path().width(14).height(14).commands("M18 6 L6 18 M6 6 L18 18")
          .stroke(TEXT_3).strokeWidth(2).strokeLineCap(LineCapStyle.Round).fill(Color.Transparent)
      }.width(32).height(44).alignContent(Alignment.Center)
      .onClick((): void => { if (this.onClose) { this.onClose() } })
    }.width("100%").padding({ left: S_4, right: S_3, top: S_2, bottom: S_1 })
  }
}
