// MathMind - NotesPage (笔记 Tab)
// 来源: Web MVP index.html page-notes 区块
// 任务编号: UI 批次 2 · 第 1 步
// 责任: 你 + Mavis
// 状态: 真实 UI 实现(第 2 批)
//
// 结构:
//   - 顶部标题: "全部笔记 · 5 条"
//   - 5 条笔记列表(复用 HomePage 的 NoteCard 视觉)
//   - Scroll 包装(5 条全可见)
//   - 底部 80vp 留白避免被 FAB 遮

import {
  BG, TEXT, TEXT_2, TEXT_3,
  S_2, S_3, S_4, S_5, S_6,
  T_BASE, T_MD, T_SM, T_LG, T_XS
} from 'common/src/main/ets/constants/ColorTokens';

import {
  NoteView, MOCK_NOTES,
  getTypeColor, getSubjectColor, getConfColor, getConfText, getBodyPreview
} from '../components/notes/notesData';

@Component
export struct NotesPage {
  @State notes: NoteView[] = MOCK_NOTES;

  build() {
    Scroll() {
      Column() {
        // 顶部标题
        Row() {
          Text('全部笔记')
            .fontSize(T_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT)
          Text(' · ' + this.notes.length + ' 条')
            .fontSize(T_SM)
            .fontColor(TEXT_3)
        }
        .width('100%')
        .padding({ left: S_5, right: S_5, top: S_3, bottom: S_2 })

        // 笔记列表(ForEach + Column 避免 nested scroll)
        Column() {
          ForEach(this.notes, (note: NoteView) => {
            this.NoteCard(note)
          }, (note: NoteView) => note.id.toString())
        }
        .width('100%')

        // 底部留白
        Blank().height(80)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .friction(0.6)
  }

  @Builder
  NoteCard(note: NoteView) {
    Row({ space: S_3 }) {
      // 类型图标(渐变)
      Text(getTypeColor(note.type).substring(1, 2))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BG)
        .width(36).height(36)
        .borderRadius(10)
        .linearGradient({
          angle: 135,
          colors: [
            [getTypeColor(note.type), 0.0],
            [getSubjectColor(note.subject), 1.0]
          ]
        })
        .textAlign(TextAlign.Center)

      // 笔记信息
      Column({ space: 3 }) {
        Row() {
          Text(note.subject)
            .fontSize(10.5)
            .fontColor(getSubjectColor(note.subject))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 6 })
          Text(note.type)
            .fontSize(10.5)
            .fontColor(getTypeColor(note.type))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 6 })
          Text(note.date)
            .fontSize(10.5)
            .fontColor(TEXT_3)
          Text(' · ' + getConfText(note.conf))
            .fontSize(10.5)
            .fontColor(getConfColor(note.conf))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Text(note.title)
          .fontSize(T_MD)
          .fontColor(TEXT)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(getBodyPreview(note.body))
          .fontSize(12.5)
          .fontColor(TEXT_3)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: S_5, right: S_5, top: S_3 + 2, bottom: S_3 + 2 })
    .alignItems(VerticalAlign.Top)
  }
}
