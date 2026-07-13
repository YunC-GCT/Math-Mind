// MathMind - MePage (我的 Tab)
// 来源: Web MVP index.html page-me 区块
// 任务编号: UI 批次 2 · 第 3 步
// 责任: 你 + Mavis
// 状态: 真实 UI 实现(第 2 批)
//
// 结构(对照 Web MVP):
//   - 头像区: 圆形"M"头像 + 用户名"Mini" + 邮箱 + tagline
//   - 3 统计方块(笔记 5 / 掌握率 75% / 今日新增 0)
//   - 5 菜单项(复习计划/错题本/收藏/设置/切换账号)→ 点击 toast
//   - 退出登录按钮(红色描边)
//   - 底部 80vp 留白

import { promptAction } from '@kit.ArkUI';
import {
  BG, MINT, MINT_LIGHT, PURPLE, RED,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  SURFACE, BORDER,
  S_1, S_2, S_3, S_4, S_5, S_6,
  T_BASE, T_SM, T_MD, T_LG
} from 'common/src/main/ets/constants/ColorTokens';

@Component
export struct MePage {
  @State userName: string = 'Mini';
  @State notesCount: number = 5;
  @State masteredPct: number = 75;
  @State todayNew: number = 0;

  // 工具:全局 toast(用 HarmonyOS 系统 promptAction)
  showToast(msg: string) {
    promptAction.showToast({ message: msg, duration: 2000 });
  }

  build() {
    Scroll() {
      Column() {
        // ============ 1. 头像区 ============
        Column() {
          // 头像"M"圆形渐变绿
          Text('M')
            .width(60).height(60)
            .borderRadius(9999)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(BG)
            .textAlign(TextAlign.Center)
            .linearGradient({
              angle: 135,
              colors: [['#34D399', 0.0], ['#10B981', 1.0]]
            })
            .margin({ top: S_5, bottom: S_3 })

          // 用户名
          Text(this.userName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT)

          // 邮箱
          Text('已登录 · 模拟账号')
            .fontSize(11.5)
            .fontColor(TEXT_3)
            .margin({ top: S_1, bottom: S_2 + 2 })

          // tagline
          Row() {
            Text('Where math clicks. ')
              .fontColor(MINT)
              .fontStyle(FontStyle.Italic)
            Text('·')
              .fontColor(PURPLE)
              .fontWeight(FontWeight.Bold)
            Text(' 思维的长程记忆')
              .fontColor(MINT)
              .fontStyle(FontStyle.Italic)
          }
          .fontSize(T_BASE)
          .margin({ bottom: S_4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // ============ 2. 3 统计方块 ============
        Row({ space: 10 }) {
          this.StatBox(this.notesCount.toString(), '笔记')
          this.StatBox(this.masteredPct + '%', '掌握率')
          this.StatBox(this.todayNew.toString(), '今日新增')
        }
        .width('100%')
        .padding({ left: S_5, right: S_5 })

        // ============ 3. 5 菜单项 ============
        Column() {
          this.MenuRow('📋', '我的复习计划')
          this.MenuRow('📕', '错题本')
          this.MenuRow('⭐', '我的收藏')
          this.MenuRow('⚙️', '设置')
          this.MenuRow('🚪', '切换账号')
        }
        .width('100%')
        .margin({ top: S_3, left: S_4, right: S_4 })
        .backgroundColor(SURFACE)
        .border({ width: 1, color: BORDER })
        .borderRadius(S_3)
        .clip(true)

        // ============ 4. 退出登录按钮 ============
        Button('退出登录')
          .width('100%')
          .height(44)
          .margin({ left: S_4, right: S_4, top: S_3 })
          .fontSize(T_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(RED)
          .backgroundColor(SURFACE)
          .border({ width: 1, color: '#33FF6B6B' })
          .borderRadius(S_3)
          .onClick(() => {
            this.showToast('已退出登录(模拟)');
          })

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
  StatBox(num: string, label: string) {
    Column() {
      Text(num)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT)
      Text(label)
        .fontSize(10)
        .fontColor(TEXT_3)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .backgroundColor(SURFACE)
    .border({ width: 1, color: BORDER })
    .borderRadius(S_3)
    .padding(S_3)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuRow(icon: string, label: string) {
    Row({ space: S_3 }) {
      Text(icon)
        .fontSize(18)
        .width(22)
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(T_MD)
        .fontColor(TEXT_2)
        .layoutWeight(1)
      Text('›')
        .fontSize(18)
        .fontColor(TEXT_4)
    }
    .width('100%')
    .padding({ left: S_4, right: S_4, top: S_3 + 2, bottom: S_3 + 2 })
    .backgroundColor(SURFACE)
    .onClick(() => {
      this.showToast(label + ' 开发中');
    })
  }
}
