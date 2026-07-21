/**
 * FormulaDetailView.ets — 公式类笔记详情正文
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/renderers/FormulaDetailView.ets
 * 职责: 按“核心公式 → 参数 → 适用范围 → 推导/易错”组织公式类内容。
 * 依赖: DetailRenderModel, DetailSection, DetailMetaFooter
 *
 * 数据流:
 *   NoteDetailBody → FormulaDetailView → DetailSection / DetailMetaFooter
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 */

import { PINK, S_2 } from 'common'
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
export struct FormulaDetailView {
  @Prop model: DetailRenderModel = emptyDetailRenderModel()

  build() {
    Column() {
      DetailSection({
        title: '先记住：核心公式',
        content: sectionText(this.model, ['表达式', '核心公式', '公式', '内容']),
        accentColor: PINK,
        emphasized: true,
      })

      DetailSection({
        title: '再确认：参数',
        content: sectionText(this.model, ['参数', '变量', '符号说明', '参数说明']),
        accentColor: PINK,
      })

      DetailSection({
        title: '适用范围',
        content: sectionText(this.model, ['适用范围', '条件', '使用条件']),
        accentColor: PINK,
      })

      DetailSection({
        title: '理解：推导',
        content: sectionText(this.model, ['推导', '推导过程']),
        accentColor: PINK,
      })

      DetailSection({
        title: '最后检查：易错点',
        content: sectionText(this.model, ['备注', '易错点', '常见错误']),
        accentColor: PINK,
      })

      if (!hasAnySectionText(this.model, [['表达式', '核心公式', '公式', '内容'], ['参数', '变量', '符号说明', '参数说明'], ['适用范围', '条件', '使用条件'], ['推导', '推导过程'], ['备注', '易错点', '常见错误']])) {
        DetailSection({
          title: '正文',
          content: fallbackMainText(this.model),
          accentColor: PINK,
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
