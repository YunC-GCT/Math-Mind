// ============================================================================
//  components/NoteCard.ets 鈥?绗旇鍗＄墖鍘熷瓙缁勪欢
//  ----------------------------------------------------------------------------
//  鑱岃矗: 娓叉煋涓€鏉＄瑪璁版憳瑕侊紙娓愬彉鍥炬爣 + 瀛︾/绫诲瀷/鏃ユ湡 meta + 鏍囬 + 鎽樿锛夈€?//  娑堥櫎: HomePage.NCard 涓?NotesPage.NoteCard 鐨勯噸澶嶄唬鐮併€?//  鏉ユ簮: 鍚堝苟鑷?HomePage + NotesPage锛岀粺涓€璁捐 Token 瀛楀彿銆?//  ============================================================================

import {
  BG_DARK,
  S_1, S_3,
  BORDER,
  TEXT,
  TEXT_3,
  TEXT_4,
  R_MD,
  F_XS,
  F_SM,
  F_MD,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  LH_TIGHT,
  NoteItem,
  stripMD,
  recentDate,
  typeChar,
  typeColor,
  subjectColor,
} from "common"
import { confColor } from "../atoms/ConfBadge"

@Component
export struct NoteCard {
  @Prop note: NoteItem = new NoteItem(0, "", "", "", "", 0, "", [], "")
  @Prop isLast: boolean = false
  onTap?: () => void

  build() {
    Row() {
      // ---- 娓愬彉鍥炬爣 36脳36 ----
      Stack() {
        Stack()
          .width(NOTE_ICON_SIZE).height(NOTE_ICON_SIZE)
          .borderRadius(R_MD + 1)
          .linearGradient({
            angle: 135,
            colors: [
              [typeColor(this.note.type), 0],
              [subjectColor(this.note.subject), 1],
            ],
          })

        Text(typeChar(this.note.type))
          .fontSize(F_MD + 2)
          .fontWeight(W_BOLD)
          .fontColor(BG_DARK)
      }
      .width(NOTE_ICON_SIZE).height(NOTE_ICON_SIZE)
      .alignContent(Alignment.Center)

      // ---- 鍙充晶鍐呭 ----
      Column() {
        // Meta 琛岋細瀛︾ 路 绫诲瀷 路 鏃ユ湡 路 缃俊搴?        Row() {
          Text(this.note.subject)
            .fontSize(F_XS)
            .fontColor(subjectColor(this.note.subject))
            .fontWeight(W_MEDIUM)
          Text(" 路 ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(this.note.type)
            .fontSize(F_XS)
            .fontColor(typeColor(this.note.type))
            .fontWeight(W_MEDIUM)
          Text(" 路 ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(recentDate(this.note.date))
            .fontSize(F_XS)
            .fontColor(TEXT_3)

          Blank()

          Text(Math.round(this.note.conf * 100) + "%")
            .fontSize(F_XS)
            .fontWeight(W_SEMIBOLD)
            .fontColor(confColor(this.note.conf))
        }
        .width("100%")

        // 鏍囬
        Text(this.note.title)
          .fontSize(F_SM)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
          .margin({ top: S_1 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width("100%")

        // 鎽樿锛? 琛屾埅鏂級
        Text(stripMD(this.note.body, 80))
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ top: S_1 / 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(LH_TIGHT)
          .width("100%")
      }
      .layoutWeight(1)
      .margin({ left: S_3 })
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
    .padding({ top: S_3, bottom: S_3 })
    .border({
      width: { bottom: this.isLast ? 0 : 1 },
      color: BORDER,
    })
    .onClick((): void => {
      if (this.onTap) {
        this.onTap()
      }
    })
  }
}
