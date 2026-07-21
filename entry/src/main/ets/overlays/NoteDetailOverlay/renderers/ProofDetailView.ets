/**
 * ProofDetailView.ets — 证明题详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/ProofDetailView.ets
 * 职责: 按“命题 → 关键思路 → 证明过程 → 结论/检查”组织证明题内容。
 * 依赖: DetailRenderModel, DetailSection, DetailStepsSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → ProofDetailView → 阅读型分块
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 */

import { AMBER, S_2 } from 'common'
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
export struct ProofDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      DetailSection({
        title: '先读：命题',
        content: sectionText(this.model, ['命题', '题目', '问题', '内容']),
        accentColor: AMBER,
        emphasized: true,
      })

      DetailSection({
        title: '抓住：关键思路',
        content: sectionText(this.model, ['关键思路', '证明思路', '思路']),
        accentColor: AMBER,
        emphasized: true,
      })

      DetailSection({
        title: '辅助：已知条件',
        content: sectionText(this.model, ['已知', '条件']),
        accentColor: AMBER,
      })

      DetailStepsSection({
        title: '展开：证明过程',
        items: splitReadableLines(sectionText(this.model, ['证明过程', '过程'])),
        accentColor: AMBER,
      })

      DetailSection({
        title: '收束：结论',
        content: sectionText(this.model, ['结论']),
        accentColor: AMBER,
      })

      if (!hasAnySectionText(this.model, [['命题', '题目', '问题', '内容'], ['关键思路', '证明思路', '思路'], ['已知', '条件'], ['证明过程', '过程'], ['结论']])) {
        DetailSection({
          title: '正文',
          content: fallbackMainText(this.model),
          accentColor: AMBER,
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
