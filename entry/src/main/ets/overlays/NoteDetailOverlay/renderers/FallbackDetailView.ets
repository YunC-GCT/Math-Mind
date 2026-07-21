/**
 * FallbackDetailView.ets — 其它/旧数据详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/FallbackDetailView.ets
 * 职责: 对未知类型、手动笔记、旧数据按原 section 顺序稳定展示。
 * 依赖: DetailRenderModel, DetailSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → FallbackDetailView → DetailSection / DetailMetaFooter
 *
 * ArkTS 1.1 strict 适配:
 *   - ForEach 使用 section.key
 *   - struct 内无普通方法
 */

import { TEXT_3, S_2 } from 'common'
import {
  DetailRenderModel,
  DetailSectionData,
  emptyDetailRenderModel,
  fallbackMainText,
} from '../model/DetailRenderModel'
import { DetailSection } from '../components/DetailSection'
import { DetailMetaFooter } from '../components/DetailMetaFooter'

@Component
export struct FallbackDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      if (this.model.sections.length > 0) {
        ForEach(this.model.sections,
          (section: DetailSectionData): void => {
            DetailSection({
              title: section.title,
              content: section.content,
              accentColor: TEXT_3,
            })
          },
          (section: DetailSectionData): string => section.key
        )
      } else {
        DetailSection({
          title: this.model.summary.length > 0 ? '摘要' : '正文',
          content: fallbackMainText(this.model),
          accentColor: TEXT_3,
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
