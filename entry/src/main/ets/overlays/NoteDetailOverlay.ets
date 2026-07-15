/**
 * MathMind 绗旇璇︽儏娴眰 鈥?绗?3 鎵?
 *
 * 瑙﹀彂: HomePage / NotesPage 鐐圭瑪璁板崱鐗?
 * 娴佺▼: 鏄剧ず绗旇璇︽儏(瀛︾鏉?/ 鏍囬 / meta / 鏍囩 / 姝ｆ枃 / AI 鍗?
 *
 * MVP 闃舵:
 *   - 姝ｆ枃绔犺妭鎸?## 鍒囧垎娓叉煋(涓嶈В鏋?LaTeX,鐩存帴鏄剧ず绾枃鏈?
 *   - AI 鍗℃寜閽?toast 鎻愮ず"W1 鎺ョ湡 AI"
 *   - 搴曢儴"缂栬緫"鎸夐挳 toast 鎻愮ず(鍚庣画鍐嶅仛)
 *
 * 渚濊禆:
 *   - common.NoteItem (class, 9 瀛楁)
 *   - common.typeColor / subjectColor (宸ュ叿鍑芥暟)
 */

import {
  MINT, MINT_DARK, MINT_GLOW, MINT_BORDER, PURPLE, PINK, AMBER,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL,
  NoteItem, typeColor, subjectColor, recentDate, stripMD,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import { AlertDialog } from '@kit.ArkUI';

// 椤跺眰宸ュ叿(ArkTS 绂?struct 鍐呮櫘閫氭柟娉?
function confColor(c: number): string {
  if (c >= 0.85) {
    return MINT;
  }
  if (c >= 0.6) {
    return AMBER;
  }
  return '#FF6B6B';
}

function confLabel(c: number): string {
  if (c >= 0.85) {
    return '宸叉帉鎻?;
  }
  if (c >= 0.6) {
    return '涓€鑸?;
  }
  return '寰呭珐鍥?;
}

// 瑙ｆ瀽 body 鎴愮珷鑺?
interface Section {
  title: string;
  content: string;
}

function parseSections(body: string): Section[] {
  if (!body) {
    return [];
  }
  const lines: string[] = body.split('\n');
  const sections: Section[] = [];
  let curTitle = '鍐呭';
  let curLines: string[] = [];

  for (const line of lines) {
    if (line.indexOf('## ') === 0) {
      // 鍒囧埌鏂扮珷鑺?
      if (curLines.length > 0) {
        sections.push({ title: curTitle, content: curLines.join('\n').trim() });
      }
      curTitle = line.substring(3).trim();
      curLines = [];
    } else {
      curLines.push(line);
    }
  }
  // 鎺ㄦ渶鍚庝竴娈?
  if (curLines.length > 0 || sections.length === 0) {
    sections.push({ title: curTitle, content: curLines.join('\n').trim() });
  }
  return sections;
}

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');

  onClose: () => void = () => {};
  onAskAi: (note: NoteItem) => void = () => {};
  onEdit: (id: number) => void = () => {};
  onDelete: (id: number) => void = () => {};

  build() {
    Stack() {
      // ===== 鍗婇€忔槑閬僵 =====
      Column()
        .width('100%').height('100%')
        .backgroundColor('#CC000000')
        .onClick(() => this.onClose());

      // ===== 娴眰涓讳綋 =====
      Column() {
        // drag bar
        Row() {
          Row()
            .width(40).height(4)
            .borderRadius(2)
            .backgroundColor(TEXT_4);
        }
        .width('100%')
        .height(24)
        .margin({ top: 8 })
        .justifyContent(FlexAlign.Center);

        // 椤舵爮
        Row() {
          // 瀛︾ 路 绫诲瀷鏉?
          Row() {
            Text(this.note.subject)
              .fontSize(F_XS)
              .fontColor(subjectColor(this.note.subject))
              .fontWeight(700);
            Text(' 路 ')
              .fontSize(F_XS)
              .fontColor(TEXT_4);
            Text(this.note.type)
              .fontSize(F_XS)
              .fontColor(typeColor(this.note.type))
              .fontWeight(600);
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(R_FULL)
          .backgroundColor('#1AFFFFFF')
          .border({ width: 1, color: BORDER });

          Blank();

          // 鍏抽棴
          this.CloseBtn();
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 4, bottom: 8 });

        // ===== 鍐呭 Scroll 鍖?=====
        Scroll() {
          Column() {
            // 鏍囬
            Text(this.note.title)
              .fontSize(F_2XL)
              .fontWeight(700)
              .fontColor(TEXT)
              .lineHeight(30)
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 4 });

            // meta 琛?绔犺妭 + 鏃ユ湡 + 缃俊搴?
            Row() {
              // 绔犺妭
              if (this.note.chapter && this.note.chapter.length > 0) {
                Text(`馃摉 ${this.note.chapter}`)
                  .fontSize(F_XS)
                  .fontColor(TEXT_2);
                Text('  路  ')
                  .fontSize(F_XS)
                  .fontColor(TEXT_4);
              }
              // 鏃ユ湡
              Text(recentDate(this.note.date))
                .fontSize(F_XS)
                .fontColor(TEXT_3);

              Blank();

              // 缃俊搴︽潯
              this.ConfBadge();
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 4, bottom: 12 });

            // 鏍囩 chips
            if (this.note.tags && this.note.tags.length > 0) {
              Row() {
                ForEach(this.note.tags, (tag: string) => {
                  this.TagChip(tag);
                }, (tag: string) => tag);
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 16 });
            }

            // 鍒嗛殧绾?
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(BORDER)
              .margin({ left: 20, right: 20, bottom: 12 });

            // 姝ｆ枃(鎸夌珷鑺傛覆鏌?
            Column() {
              ForEach(parseSections(this.note.body), (sec: Section) => {
                this.SectionView(sec);
              }, (sec: Section) => sec.title + '_' + sec.content.length.toString());
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 16 });

            // AI 鍗?
            this.AiCard();

            // 搴曢儴鐣欑櫧
            Blank().height(80);
          }
          .width('100%');
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // ===== 搴曢儴鎿嶄綔鏍?=====
        Row() {
          // 鍒犻櫎
          this.ActionBtn('馃棏', '鍒犻櫎', '#FF6B6B', () => this.confirmDelete());
          Blank().width(8);
          // 缂栬緫
          this.ActionBtn('鉁?, '缂栬緫', TEXT_2, () => this.mockEdit());
          Blank().width(8);
          // 鍒嗕韩
          this.ActionBtn('鈫?, '鍒嗕韩', TEXT_2, () => this.mockShare());
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 28 })
        .backgroundColor(BG_DARK)
        .border({ width: { top: 1 }, color: BORDER });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  // ========== 绔犺妭娓叉煋 ==========
  @Builder
  SectionView(sec: Section) {
    Column() {
      // 绔犺妭鏍囬
      Text(sec.title)
        .fontSize(F_SM)
        .fontWeight(700)
        .fontColor(MINT)
        .letterSpacing(0.5)
        .width('100%')
        .margin({ top: 12, bottom: 6 });

      // 绔犺妭鍐呭
      Text(sec.content && sec.content.length > 0 ? sec.content : '鈥?)
        .fontSize(F_BASE)
        .fontColor(TEXT_2)
        .lineHeight(22)
        .width('100%');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // ========== 缃俊搴﹀窘绔?==========
  @Builder
  ConfBadge() {
    Row() {
      // 鍦嗙偣
      Column()
        .width(6).height(6)
        .borderRadius(3)
        .backgroundColor(confColor(this.note.conf));
      Text('  ')
        .fontSize(F_XS);
      Text(`${Math.round(this.note.conf * 100)}% ${confLabel(this.note.conf)}`)
        .fontSize(F_XS)
        .fontWeight(600)
        .fontColor(confColor(this.note.conf));
    }
    .alignItems(VerticalAlign.Center);
  }

  // ========== 鏍囩 chip ==========
  @Builder
  TagChip(tag: string) {
    Text(`#${tag}`)
      .fontSize(F_XS)
      .fontColor(MINT)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(R_FULL)
      .backgroundColor(MINT_GLOW)
      .margin({ right: 6, bottom: 6 });
  }

  // ========== AI 鍗?==========
  @Builder
  AiCard() {
    Column() {
      Row() {
        // AI 鍥炬爣
        Stack() {
          Text('鉁?)
            .fontSize(14)
            .fontWeight(700)
            .fontColor(BG_DARK);
        }
        .width(28).height(28)
        .borderRadius(14)
        .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
        .alignContent(Alignment.Center)
        .margin({ right: 10 });

        Column() {
          Text('AI 瑙ｇ瓟')
            .fontSize(F_BASE)
            .fontWeight(700)
            .fontColor(TEXT);
          Text('璁?MathMind AI 瑙ｉ噴杩欓亾棰?)
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Text('鈥?)
          .fontSize(20)
          .fontColor(MINT)
          .fontWeight(500);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(R_LG)
    .backgroundColor('#0DFFFFFF')
    .border({ width: 1, color: MINT_BORDER })
    .linearGradient({
      angle: 135,
      colors: [['#1A5BE3B0', 0], ['#0D9775FA', 1]],
    })
    .onClick(() => this.handleAskAi());
  }

  // ========== 椤舵爮鎸夐挳 ==========
  @Builder
  CloseBtn() {
    Stack() {
      Text('鉁?)
        .fontSize(16)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(32).height(32)
    .borderRadius(16)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  // ========== 搴曢儴鎿嶄綔鎸夐挳 ==========
  @Builder
  ActionBtn(icon: string, label: string, color: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(16)
        .fontColor(color);
      Text(label)
        .fontSize(10)
        .fontColor(color)
        .margin({ top: 2 });
    }
    .layoutWeight(1)
    .height(44)
    .borderRadius(R_MD)
    .backgroundColor('#1AFFFFFF')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => action());
  }

  // ========== 琛屼负(绠ご鍑芥暟) ==========
  private handleAskAi = (): void => {
    promptAction.showToast({ message: '姝ｅ湪鍛煎彨 AI...', duration: 1500 });
    this.onAskAi(this.note);
  };

  private mockEdit = (): void => {
    promptAction.showToast({ message: '缂栬緫鍔熻兘 W2 涓婄嚎', duration: 1500 });
    this.onEdit(this.note.id);
  };

  private mockShare = (): void => {
    promptAction.showToast({ message: '宸插鍒剁瑪璁板埌鍓创鏉?, duration: 1500 });
  };

  private confirmDelete = (): void => {
    promptAction.showToast({ message: '鍒犻櫎鍔熻兘 W2 涓婄嚎', duration: 1500 });
    this.onDelete(this.note.id);
  };
}
