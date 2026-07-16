// ============================================================================
//  MathMind 设计 Token — 令牌层
//  ----------------------------------------------------------------------------
//  对照: styles.css :root + app.js tc()/sc()
//  层级: 令牌层是所有视觉属性的唯一真相源 (single source of truth)
//
//  分类:
//    主色板 → 语义色 → 玻璃色 → 文字/边框 → 间距/圆角/字号 → 字重/行高/阴影
//  ============================================================================

// ========================================================================
//  主色板 (Palette) — 11 个
// ========================================================================
export const MINT: string         = "#FF5BE3B0"
export const MINT_DARK: string    = "#FF1F8F65"
export const MINT_LIGHT: string   = "#245BE3B0"
export const MINT_GLOW: string    = "#6B5BE3B0"
export const MINT_BORDER: string  = "#475BE3B0"
export const PURPLE: string       = "#FF9775FA"
export const PURPLE_DARK: string  = "#FF7C5CE0"
export const PURPLE_LIGHT: string = "#249775FA"
export const PINK: string         = "#FFFF6B9D"
export const PINK_LIGHT: string  = "#1AFF6B9D"   // PINK 10% (Hero 梯度收尾)
export const AMBER: string        = "#FFF0C674"
export const BG_DARK: string      = "#FF0A0C10"

// ========================================================================
//  扩展背景色
// ========================================================================
export const BG_CARD: string = "#FF10131A"

// ========================================================================
//  语义色 (Semantic)
// ========================================================================
export const DANGER: string        = "#FF6B6B"    // 错误/删除 (软红)
export const DANGER_BRIGHT: string = "#FFEF4444"  // 高亮红 (高优先级/删除按钮)
export const WARNING: string       = "#FFFBBF24"  // 告警/中等置信度
export const SUCCESS: string       = MINT          // 成功 alias

// ========================================================================
//  玻璃色 (Glass) — 白色半透明阶梯，深色背景上叠层用
// ========================================================================
export const GLASS_8: string  = "#08FFFFFF"  // 8%  极淡玻璃
export const GLASS_10: string = "#1AFFFFFF"  // 10% 边框/按钮背景 (原 BORDER)
export const GLASS_14: string = "#0DFFFFFF"  // ~5%? AI 卡背景 (原硬编码)
// 注意: GLASS_10 与 BORDER 值相同，BORDER 保留作为语义别名

// ========================================================================
//  遮罩色 (Overlay)
// ========================================================================
export const OVERLAY_MASK: string     = "#80000000"  // 50% 黑 (AgentFloatWindow)
export const OVERLAY_MASK_SOLID: string = "#CC000000" // 80% 黑 (NoteDetailOverlay)

// ========================================================================
//  学科色 (Record)
// ========================================================================
export const SUBJECT_COLORS: Record<string, string> = {
  "数学分析": PINK,
  "高等代数": PURPLE,
  "空间解析几何": AMBER,
  "解析几何": AMBER,
}

// ========================================================================
//  类型色 (Record)
// ========================================================================
export const TYPE_COLORS: Record<string, string> = {
  "概念": MINT,
  "计算": PURPLE,
  "证明": AMBER,
}

// ========================================================================
//  文字色 — 4 级
// ========================================================================
export const TEXT: string   = "#FFFFFFFF"
export const TEXT_2: string = "#FFB0B3C1"
export const TEXT_3: string = "#FF6B7280"
export const TEXT_4: string = "#FF4B5563"

// ========================================================================
//  边框色
// ========================================================================
export const BORDER: string = GLASS_10  // alias

// ========================================================================
//  间距 (Spacing) — 6 级 (vp)
// ========================================================================
export const S_1: number = 4
export const S_2: number = 8
export const S_3: number = 12
export const S_4: number = 16
export const S_5: number = 20
export const S_6: number = 24

// ========================================================================
//  圆角 (Radius) — 6 级 (vp)
// ========================================================================
export const R_SM: number  = 6
export const R_MD: number  = 8
export const R_LG: number  = 12
export const R_XL: number  = 16
export const R_2XL: number = 24
export const R_FULL: number = 9999

// ========================================================================
//  字号 (Font Size) — 8 级 (fp)
// ========================================================================
export const F_XS: number   = 11
export const F_SM: number   = 12
export const F_BASE: number = 14
export const F_MD: number   = 16
export const F_LG: number   = 18
export const F_XL: number   = 20
export const F_2XL: number  = 24
export const F_3XL: number  = 30

// ========================================================================
//  字重 (Font Weight) — 4 级
// ========================================================================
export const W_NORMAL: number = 400
export const W_MEDIUM: number = 500
export const W_SEMIBOLD: number = 600
export const W_BOLD: number = 700

// ========================================================================
//  行高 (Line Height) — 5 级 (vp)
// ========================================================================
export const LH_TIGHT: number  = 16
export const LH_BASE: number   = 18
export const LH_COMFORT: number = 20
export const LH_LOOSE: number  = 22
export const LH_HEADING: number = 30

// ========================================================================
//  阴影 (Shadow) — 预设
// ========================================================================
interface ShadowPreset {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

export const SHADOW_FAB: ShadowPreset = {
  radius: 28,
  color: "#595BE3B0",
  offsetX: 0,
  offsetY: 8,
}

export function SHADOW_GLOW_MINT(alpha: number): ShadowPreset {
  return {
    radius: 32,
    color: "rgba(91, 227, 176, " + alpha.toFixed(2) + ")",
    offsetX: 0,
    offsetY: 0,
  }
}

// ========================================================================
//  动画时长 (ms)
// ========================================================================
export const DUR_FAST: number    = 200
export const DUR_NORMAL: number  = 400
export const DUR_SLOW: number    = 1200
export const DUR_BREATH: number  = 3000   // 光晕呼吸周期

// ========================================================================
//  屏幕尺寸 (vp) — 固定参考值
// ========================================================================
export const SCREEN_W: number = 377
export const SCREEN_H: number = 816

// ========================================================================
//  组件尺寸 (vp)
// ========================================================================
export const HEADER_H: number       = 60
export const FAB_SIZE: number       = 54
export const HERO_RING_SIZE: number = 120
export const NOTE_ICON_SIZE: number = 36
export const DOT_SIZE: number       = 8
