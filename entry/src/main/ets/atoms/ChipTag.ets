/**
 * ChipTag.ets — 标签片 / Chip 通用原子
 *
 * 路径: entry/src/main/ets/atoms/ChipTag.ets
 * 职责: 对齐 v2-ui .chip / .form-chip / .tag 三种变体
 * 依赖: common (ColorTokens)
 *
 * 变体:
 *   'chip'       — 药丸标签 (类型过滤/知识点), 带边框半透底
 *   'chipActive' — 选中态 (渐变底+发光)
 *   'form'       — 表单片
 *   'formSelected' — 表单片选中
 *   'tag'        — 小标签 (行内短标签)
 */

import {
  MINT, PURPLE, TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4,
  R_FULL, R_MD, R_SM,
  F_XS, F_SM,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  GLASS_10,
} from 'common';

@Component
export struct ChipTag {
  @Prop label: string = '';
  @Prop variant: string = 'chip';  // 'chip' | 'chipActive' | 'form' | 'formSelected' | 'tag'
  @Prop colorOverride: string = ''; // 优先覆盖背景色 (如类型颜色)
  onTap?: () => void = (): void => {};

  build() {
    Text(this.label)
      .fontSize(this.variant === 'tag' ? 9 : F_XS)
      .fontColor(this.textColor())
      .fontWeight(this.variant === 'chipActive' ? W_BOLD : (this.variant === 'formSelected' ? W_SEMIBOLD : W_MEDIUM))
      .padding(this.chipPadding())
      .borderRadius(this.variant === 'tag' ? R_SM : R_FULL)
      .backgroundColor(this.chipBg())
      .border(this.variant === 'tag' ? { width: 0 } : { width: 1, color: BORDER })
      .onClick((): void => { if (this.onTap) { this.onTap(); } });
  }

  private textColor(): string {
    if (this.variant === 'chipActive') { return TEXT; }
    if (this.variant === 'formSelected') { return MINT; }
    if (this.variant === 'tag') { return TEXT_3; }
    return TEXT_2;
  }

  private chipBg(): string {
    if (this.colorOverride.length > 0) { return this.colorOverride; }
    if (this.variant === 'chipActive') { return MINT; }
    if (this.variant === 'formSelected') { return GLASS_10; }
    if (this.variant === 'tag') { return GLASS_10; }
    return GLASS_10;
  }

  private chipPadding(): Padding {
    if (this.variant === 'tag') {
      return { left: S_2, right: S_2, top: S_1, bottom: S_1 };
    }
    return { left: S_3, right: S_3, top: 4, bottom: 4 };
  }
}
