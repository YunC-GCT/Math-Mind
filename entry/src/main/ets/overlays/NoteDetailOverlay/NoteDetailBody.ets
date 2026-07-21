/**
 * NoteDetailBody.ets — 笔记详情正文六类分发入口
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailBody.ets
 * 职责: 将 KnowledgeUnit / NoteItem 转为 DetailRenderModel，并按 category 分发到六类正文 renderer。
 * 依赖: common models, DetailRenderModel, 六类 renderer
 *
 * 数据流:
 *   NoteDetailOverlay → NoteDetailBody
 *     → buildDetailRenderModel
 *     → Concept / Theorem / Formula / Proof / Computation / Fallback renderer
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 *   - 不使用 any / unknown
 */

import {
  NoteItem,
  KnowledgeUnit,
} from 'common'
import {
  DetailRenderModel,
  buildDetailRenderModel,
} from './model/DetailRenderModel'
import { ConceptDetailView } from './renderers/ConceptDetailView'
import { TheoremDetailView } from './renderers/TheoremDetailView'
import { FormulaDetailView } from './renderers/FormulaDetailView'
import { ProofDetailView } from './renderers/ProofDetailView'
import { ComputationDetailView } from './renderers/ComputationDetailView'
import { FallbackDetailView } from './renderers/FallbackDetailView'

@Component
export struct NoteDetailBody {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null
  @Prop units: KnowledgeUnit[] = []

  build() {
    Column() {
      if (this.renderModel().category === '概念') {
        ConceptDetailView({ model: this.renderModel() })
      } else if (this.renderModel().category === '定理') {
        TheoremDetailView({ model: this.renderModel() })
      } else if (this.renderModel().category === '公式') {
        FormulaDetailView({ model: this.renderModel() })
      } else if (this.renderModel().category === '证明题') {
        ProofDetailView({ model: this.renderModel() })
      } else if (this.renderModel().category === '计算题') {
        ComputationDetailView({ model: this.renderModel() })
      } else {
        FallbackDetailView({ model: this.renderModel() })
      }
    }
    .width('100%')
  }

  private renderModel = (): DetailRenderModel => {
    return buildDetailRenderModel(this.note, this.unit, this.units)
  }
}
