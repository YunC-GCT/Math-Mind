/**
 * MathMind 个人中心�?�?对照 iOS Web MVP page-me
 * 对照 CSS .me-wrap / .me-avatar / .me-stats / .me-menu / .mm / .me-logout-btn
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BG_CARD,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  S_1,
  S_2,
  S_3,
  S_4,
  R_MD,
  R_LG,
  R_FULL,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  F_LG,
  F_XL,
  F_2XL,
  NoteItem,
  NOTES,
} from 'common';
import { promptAction, router } from '@kit.ArkUI';

@Component
export struct MePage {
  // ========== 计算统计 ==========
  private notes: NoteItem[] = NOTES;
  private avg: number = this.notes.length > 0
    ? Math.round(this.notes.reduce((a: number, n: NoteItem) => a + n.conf, 0) / this.notes.length * 100)
    : 0;

  /** 今日新增（对�?app.js 计算当天日期�?*/
  private todayNew(): number {
    const today = new Date();
    const ds = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    return this.notes.filter((n: NoteItem) => n.date === ds).length;
  }

  build() {
    Scroll() {
      Column() {
        // ===== 头像�?=====
        Column() {
          // 头像（对�?CSS .me-avatar: 60×60, gradient #34d399�?10b981�?
          Stack() {
            Stack()
              .width(60)
              .height(60)
              .borderRadius(R_FULL)
              .linearGradient({
                angle: 135,
                colors: [
                  ['#FF34D399', 0],
                  ['#FF10B981', 1],
                ],
              })
              .shadow({
                radius: 14,
                color: '#5934D399',
                offsetY: 4,
              });

            Text('M')
              .fontSize(F_XL + 2)
              .fontWeight(700)
              .fontColor('#FF0A0C10');
          }
          .width(60)
          .height(60)
          .alignContent(Alignment.Center)
          .margin({ bottom: 12 });

          // 用户名（对照 CSS .me-name: 20px/700�?
          Text('Mini')
            .fontSize(F_LG)
            .fontWeight(700)
            .fontColor(TEXT)
            .margin({ bottom: 4 });

          // 邮箱（对�?CSS .me-email: 11.5px/text-3�?
          Text('已登�?· 模拟账号')
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ bottom: 10 });

          // tagline（对�?CSS .me-tagline: 12px/mint italic, purple dot�?
          Row() {
            Text('Where math clicks.')
              .fontSize(F_SM)
              .fontColor(MINT)
              .fontStyle(FontStyle.Italic);

            Text(' · ')
              .fontSize(F_SM)
              .fontColor(PURPLE)
              .fontWeight(700);

            Text('思维的长程记�?)
              .fontSize(F_SM)
              .fontColor(MINT)
              .fontStyle(FontStyle.Italic);
          }
          .margin({ bottom: 18 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // ===== 3 统计方块（对�?CSS .me-stats flex gap:10�?=====
        Row() {
          this.SBox(`${this.notes.length}`, '笔记');
          this.SBox(`${this.avg}%`, '掌握�?);
          this.SBox(`${this.todayNew()}`, '今日新增');
        }
        .width('100%')
        .padding({ left: S_2, right: S_2 })
        .margin({ bottom: 18 });

        // ===== 5 菜单项（对照 CSS .me-menu / .mm�?=====
        Column() {
          this.MenuItem('📋', '我的复习计划', '复习计划开发中');
          this.MenuItem('📕', '错题�?, '错题本开发中');
          this.MenuItem('�?, '我的收藏', '收藏功能开发中');
          this.MenuItem('⚙️', '设置', '');
          this.MenuItem('🚪', '切换账号', '切换账号开发中');
        }
        .width('100%')
        .padding({ left: S_2, right: S_2 })
        .margin({ bottom: 14 });

        // ===== 退出登录按钮（对照 CSS .me-logout-btn�?=====
        Button('退出登�?)
          .fontSize(F_SM)
          .fontWeight(600)
          .fontColor('#FFFF6B6B')
          .width('100%')
          .height(44)
          .borderRadius(R_LG)
          .backgroundColor('#26FF6B6B')
          .border({ width: 1, color: '#4DFF6B6B' })
          .margin({ left: S_2, right: S_2, bottom: 60 })
          .onClick(() => {
            this.toast('退出登录开发中');
          });
      }
      .width('100%')
      .padding({
        top: 20,
      });
    }
    .width('100%')
    .height('100%');
  }

  // ========== 统计方块 ==========
  @Builder
  SBox(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(F_MD + 3)
        .fontWeight(700)
        .fontColor(TEXT);
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: 3 });
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .borderRadius(12)
    .backgroundColor('#08FFFFFF')
    .border({ width: 1, color: BORDER })
    .alignItems(HorizontalAlign.Center)
    .margin({ left: S_1, right: S_1 });
  }

  // ========== 菜单项（对照 CSS .mm�?==========
  @Builder
  MenuItem(icon: string, label: string, msg: string) {
    Row() {
      // 左图�?
      Text(icon)
        .fontSize(F_MD + 1)
        .width(22)
        .textAlign(TextAlign.Center)
        .flexShrink(0);

      // 文字
      Text(label)
        .fontSize(F_SM)
        .fontColor(TEXT_2)
        .layoutWeight(1)
        .margin({ left: 12 });

      // 右箭�?�?
      Text('�?)
        .fontSize(F_MD + 1)
        .fontColor(TEXT_4);
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 13,
      bottom: 13,
    })
    .border({ width: { bottom: 1 }, color: BORDER })
    .onClick(() => { if (msg.length > 0) { this.toast(msg); } else if (label === '����') { router.pushUrl({ url: 'pages/AiSettingsPage' }); } });
  }

  // ========== Toast 提示 ==========
  private toast(msg: string): void {
    promptAction.showToast({
      message: msg,
      duration: 2000,
      bottom: '50%',
    });
  }
}
