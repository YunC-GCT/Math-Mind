// ============================================================================
//  SectionHeader.ets — 分组标题原子组件
//  ----------------------------------------------------------------------------
//  用途: 设置页分组区域的标题行（标题 + 可选灰色描述）
//  UI:    服务端点                    ← 粗体标题
//         选择预设或输入自定义地址     ← 小号灰色描述
//  接口:
//    @Prop title   — 分组标题文字
//    @Prop desc    — 描述文字（为空时不渲染）
//  依赖: common ColorTokens (TEXT/TEXT_4/F_XS/F_SM/W_SEMIBOLD)
//  复用: AiSettingsPage 4 处 SectionHeader
// ============================================================================// ============================================================================
//  atoms/SectionHeader.ets — 分组标题原子
//  来源: AiSettingsPage SectionHeader @Builder
// ============================================================================

import { TEXT, TEXT_4, F_XS, F_SM, W_SEMIBOLD, S_2 } from "common"

@Component
export struct SectionHeader {
  @Prop title: string = ""
  @Prop desc: string = ""

  build() {
    Column() {
      Text(this.title).fontSize(F_SM).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      if (this.desc.length > 0) {
        Text(this.desc).fontSize(F_XS).fontColor(TEXT_4).margin({ top: 2 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width("100%").padding({ left: 20, right: S_2, top: 20, bottom: 8 })
  }
}
