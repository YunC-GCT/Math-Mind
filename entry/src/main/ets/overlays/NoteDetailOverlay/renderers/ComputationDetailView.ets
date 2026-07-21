/**
 * ComputationDetailView.ets — 计算题详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/ComputationDetailView.ets
 * 职责: 按“问题 → 步骤 → 答案 → 方法总结/常见错误”组织计算题内容。
 * 依赖: DetailRenderModel, DetailSection, DetailStepsSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → ComputationDetailView → 阅读型分块
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
  splitReadableLines,
} from '../model/DetailRenderModel'
import { DetailSection } from '../components/DetailSection'
import { DetailStepsSection } from '../components/DetailStepsSection'
import { DetailMetaFooter } from '../components/DetailMetaFooter'

@Component
export struct ComputationDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      DetailSection({
        title: '先看：问题',
        content: sectionText(this.model, ['问题', '题目', '内容']),
        accentColor: MINT,
        emphasized: true,
      })

      DetailStepsSection({
        title: '展开：步骤',
        items: splitReadableLines(sectionText(this.model, ['步骤', '解题步骤'])),
        accentColor: MINT,
      })

      DetailSection({
        title: '核对：答案',
        content: sectionText(this.model, ['答案', '结果']),
        accentColor: MINT,
        emphasized: true,
      })

      DetailSection({
        title: '带走：方法总结',
        content: sectionText(this.model, ['方法总结']),
        accentColor: MINT,
      })

      DetailSection({
        title: '最后检查：常见错误',
        content: sectionText(this.model, ['常见错误', '易错点', '备注']),
        accentColor: MINT,
      })

      if (!hasAnySectionText(this.model, [['问题', '题目', '内容'], ['步骤', '解题步骤'], ['答案', '结果'], ['方法总结'], ['常见错误', '易错点', '备注']])) {
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
