/**
 * ==========================================================================
 *  EmptyStateHint.ets — 空状态引导组件
 *  ==========================================================================
 *  职责: 无消息时显示品牌钻石 SVG + 引导文案。
 *
 *  UI:
 *        ◆ (钻石 SVG, MINT 渐变)
 *     有什么数学问题?
 *    试试下方的推荐问题，或直接输入
 *
 *  接口: 无 — 纯展示组件
 *
 *  依赖: common ColorTokens (MINT/TEXT/TEXT_3)
 * ==========================================================================
 */// chat/EmptyStateHint.ets — 空状态: 钻石 SVG + 引导文案
import { MINT, TEXT, TEXT_3, S_2, S_3, S_6, F_XS, F_MD, W_SEMIBOLD } from "common"
@Component
export struct EmptyStateHint {
  build() {
    Column() {
      Stack() {
        Path().width(30).height(30).commands("M 15 0 L 28 15 L 15 30 L 2 15 Z").fill(MINT).opacity(0.3)
        Path().width(18).height(18).commands("M 15 4 L 26 15 L 15 26 L 4 15 Z").fill(MINT)
      }.width(48).height(48).margin({ bottom: S_3 })
      Text("\u6709\u4EC0\u4E48\u6570\u5B66\u95EE\u9898\uFF1F").fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Text("\u8BD5\u8BD5\u4E0B\u65B9\u7684\u63A8\u8350\u95EE\u9898\uFF0C\u6216\u76F4\u63A5\u8F93\u5165").fontSize(F_XS).fontColor(TEXT_3).margin({ top: S_2 })
    }.width("100%").padding({ top: S_6, bottom: S_6 }).alignItems(HorizontalAlign.Center)
  }
}
