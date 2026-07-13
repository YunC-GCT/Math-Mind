// common HSP - public API 入口

// 设计 Token
export {
  MINT, MINT_DARK, MINT_LIGHT, MINT_GLOW, MINT_BORDER,
  PURPLE, PURPLE_DARK, PURPLE_LIGHT, PINK, AMBER,
  BG_DARK, BG_CARD,
  SUBJECT_COLORS, TYPE_COLORS,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  BORDER,
  S_1, S_2, S_3, S_4, S_5, S_6,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL, F_3XL,
  SCREEN_W, SCREEN_H,
} from './constants/ColorTokens';

// 共享数据模型
export { NoteItem, NOTES, stripMD, recentDate, typeChar, typeColor, subjectColor }
  from './data/MockNotes';
