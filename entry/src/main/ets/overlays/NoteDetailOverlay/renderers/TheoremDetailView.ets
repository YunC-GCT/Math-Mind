/**
 * TheoremDetailView.ets — 定理类笔记详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/TheoremDetailView.ets
 * 职责: 按“条件 → 结论 → 证明思路 → 应用”组织定理类内容。
 * 依赖: DetailRenderModel, DetailSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → TheoremDetailView → DetailSection / DetailMetaFooter
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 */

import { PURPLE, S_2 } from 'common'
import {
  DetailRenderModel,
  emptyDetailRenderModel,
  sectionText,
  fallbackMainText,
  hasAnySectionText,
} from '../model/DetailRenderModel'
import { DetailSection } from '../components/DetailSection'
import { DetailMetaFooter } from '../components/DetailMetaFooter'

@Component
export struct TheoremDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      DetailSection({
        title: '先读：定理陈述',
        content: sectionText(this.model, ['陈述', '定理陈述', '内容']),
        accentColor: PURPLE,
        emphasized: true,
      })

      DetailSection({
        title: '先核对：条件',
        content: sectionText(this.model, ['条件', '适用范围']),
        accentColor: PURPLE,
      })

      DetailSection({
        title: '要记住：结论',
        content: sectionText(this.model, ['结论']),
        accentColor: PURPLE,
        emphasized: true,
      })

      DetailSection({
        title: '理解：证明思路',
        content: sectionText(this.model, ['证明思路', '思路', '关键思路']),
        accentColor: PURPLE,
      })

      DetailSection({
        title: '应用',
        content: sectionText(this.model, ['应用']),
        accentColor: PURPLE,
      })

      if (!hasAnySectionText(this.model, [['陈述', '定理陈述', '内容'], ['条件', '适用范围'], ['结论'], ['证明思路', '思路', '关键思路'], ['应用']])) {
        DetailSection({
          title: '正文',
          content: fallbackMainText(this.model),
          accentColor: PURPLE,
          emphasized: true,
        })
      }

      DetailMetaFooter({ model: this.model })
      Blank().height(80)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: S_2, bottom: S_2 })
    .alignItems(HorizontalAlign.Start)
  }
}
