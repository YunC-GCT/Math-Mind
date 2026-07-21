/**
 * ConceptDetailView.ets — 概念类笔记详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/ConceptDetailView.ets
 * 职责: 按“定义边界 → 判断性质 → 示例反例 → 元信息”组织概念类内容。
 * 依赖: DetailRenderModel, DetailSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → ConceptDetailView → DetailSection / DetailMetaFooter
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 */

import { MINT, S_2 } from 'common'
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
export struct ConceptDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      DetailSection({
        title: '先读：定义边界',
        content: sectionText(this.model, ['定义', '内容']),
        accentColor: MINT,
        emphasized: true,
      })

      DetailSection({
        title: '再看：判断性质',
        content: sectionText(this.model, ['性质', '特征']),
        accentColor: MINT,
      })

      DetailSection({
        title: '最后：例子和反例',
        content: sectionText(this.model, ['示例', '例子', '反例']),
        accentColor: MINT,
      })

      DetailSection({
        title: '关联概念',
        content: sectionText(this.model, ['相关概念']),
        accentColor: MINT,
      })

      if (!hasAnySectionText(this.model, [['定义', '内容'], ['性质', '特征'], ['示例', '例子', '反例'], ['相关概念']])) {
        DetailSection({
          title: '正文',
          content: fallbackMainText(this.model),
          accentColor: MINT,
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
