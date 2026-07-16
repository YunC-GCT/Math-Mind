// ============================================================================
//  components/PlanItemRow.ets 鈥?瀛︿範璁″垝鍗曡鍘熷瓙缁勪欢
//  ----------------------------------------------------------------------------
//  鑱岃矗: 娓叉煋涓€鏉″涔犺鍒掗」锛堝畬鎴愮姸鎬佸浘鏍?+ 鏍囬 + 鍏宠仈绗旇 + 浼樺厛绾ф爣绛撅級銆?//  涓?ViewModel 瑙ｈ€? 閫氳繃 onToggle / onDelete 鍥炶皟閫氱煡鐖剁粍浠躲€?//
//  ArkTS 1.1 strict: @Prop 浠呮帴鏀跺師濮嬬被鍨嬶紙string/boolean/number锛夛紝閬垮厤 class 娴呮嫹璐濆鑷?UI 涓嶆洿鏂般€?//  ============================================================================

import { MINT, TEXT, TEXT_3, S_1, S_3, S_5, F_XL, F_MD, F_XS } from "common"
import { PriorityBadge } from "../atoms/PriorityBadge"

@Component
export struct PlanItemRow {
  @Prop title: string = ""
  @Prop isDone: boolean = false
  @Prop priority: number = 2
  @Prop linkedNoteId: string = ""
  onToggle?: () => void

  build() {
    Row({ space: S_3 }) {
      // ---- 瀹屾垚鐘舵€佸浘鏍?----
      Text(this.isDone ? "鈼? : "鈼?)
        .fontSize(F_XL + 2)
        .fontColor(this.isDone ? MINT : TEXT_3)
        .onClick((): void => {
          if (this.onToggle) {
            this.onToggle()
          }
        })

      // ---- 鏍囬 + 鍏宠仈绗旇 ----
      Column({ space: S_1 / 2 }) {
        Text(this.title)
          .fontSize(F_MD)
          .fontColor(this.isDone ? TEXT_3 : TEXT)
          .decoration(this.isDone
            ? { type: TextDecorationType.LineThrough, color: TEXT_3 }
            : { type: TextDecorationType.None })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.linkedNoteId.length > 0) {
          Text("馃搸 鍏宠仈绗旇: " + this.linkedNoteId)
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .maxLines(1)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // ---- 浼樺厛绾ф爣绛?----
      PriorityBadge({ priority: this.priority })
    }
    .width("100%")
    .padding({ top: S_3 + 2, bottom: S_3 + 2, left: S_5, right: S_5 })

  }
}
