// ============================================================================
//  molecules/ReminderBanner.ets 鈥?棣栭〉鎻愰啋妯箙鍒嗗瓙缁勪欢
//  ----------------------------------------------------------------------------
//  鑱岃矗: 绗旇鏁?< 3 鏃舵樉绀哄紩瀵兼枃妗堬紙娆㈣繋/榧撳姳锛夈€?//  鏉ユ簮: 浠?HomePage.ets 鎻愬彇锛屾秷闄ゅ唴鑱?if 鍧椼€?//  鎺ュ彛:
//    @Prop  notesCount 鈥?褰撳墠绗旇鎬绘暟锛堟帶鍒舵樉绀哄拰鏂囨锛?//  ============================================================================

import {
  MINT, MINT_LIGHT, PURPLE_LIGHT,
  S_2, S_3, S_4,
  R_MD,
  F_SM,
  LH_BASE,
} from "common"

@Component
export struct ReminderBanner {
  @Prop notesCount: number = 0

  build() {
    Row() {
      Text(this.notesCount === 0
        ? "馃憢 娆㈣繋浣跨敤 MathMind锛佽瘯璇?AI 瀵硅瘽鎴栨媿鐓э紝甯綘鏁寸悊鐭ヨ瘑绗旇 >"
        : "鈴?宸叉湁 " + this.notesCount + " 鏉＄瑪璁帮紝缁х画鐢?AI 鍏呭疄鐭ヨ瘑搴?>")
        .fontSize(F_SM).fontColor(MINT).lineHeight(LH_BASE)
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_3, bottom: S_3 })
    .margin({ left: S_4, right: S_4, top: S_2 })
    .borderRadius(R_MD)
    .linearGradient({
      angle: 135,
      colors: [[MINT_LIGHT, 0], [PURPLE_LIGHT, 1]],
    })
    .border({ width: S_1 / 4, color: MINT_LIGHT })
  }
}
