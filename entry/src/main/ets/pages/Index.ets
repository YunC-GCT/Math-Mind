// MathMind - Index (4 Tab 容器,主入口)
// 任务编号: UI 批次 1 · 第 3 步
// 责任: 你 + Mavis
// 状态: 真实 UI 实现(第 1 批,5 个 Tab 框架,只 HomePage 真实实现)
//
// 结构(对照 Web MVP index.html):
//   - Stack:
//     ├─ 当前 Tab 内容(Home / Notes / AI / Review / Me)
//     └─ 底部 Tab 栏(5 个 Tab,中间 AI 是渐变圆形凸起)
//
// 第 1 批只挂 HomePage; 其它 Tab 占位 Text
//   - NotesPage / ReviewPage / MePage → 第 2 批
//   - AI 浮层 / Camera 浮层 / NoteDetail 浮层 → 第 3 批

import { HomePage } from './HomePage';
import {
  MINT, MINT_DARK,
  PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_3, TEXT_4,
  BG, BG_2, BORDER,
  R_FULL,
  T_SM, T_BASE,
  TABBAR_H
} from 'common/src/main/ets/constants/ColorTokens';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;  // 0=Home 1=Notes 2=AI 3=Review 4=Me

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 主内容区
      Stack() {
        if (this.currentTab === 0) {
          HomePage()
        } else if (this.currentTab === 1) {
          this.PlaceholderTab('笔记 Tab', '全部笔记列表 (待第 2 批实现)')
        } else if (this.currentTab === 2) {
          this.PlaceholderTab('AI 浮层', 'AI 对话入口 (待第 3 批实现)')
        } else if (this.currentTab === 3) {
          this.PlaceholderTab('复习 Tab', '复习计划 (待第 2 批实现)')
        } else {
          this.PlaceholderTab('我的 Tab', '个人中心 (待第 2 批实现)')
        }
      }
      .width('100%')
      .height('100%')

      // 底部 Tab 栏
      this.TabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG)
  }

  @Builder
  PlaceholderTab(title: string, sub: string) {
    Column() {
      Blank()
      Text(title)
        .fontSize(T_BASE + 4)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT)
        .margin({ bottom: 8 })
      Text(sub)
        .fontSize(T_SM)
        .fontColor(TEXT_3)
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40 })
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG)
  }

  @Builder
  TabBar() {
    Row() {
      this.TabItem(0, '首页', '🏠')
      this.TabItem(1, '笔记', '📁')
      this.AiTabItem(2)
      this.TabItem(3, '复习', '📋')
      this.TabItem(4, '我的', '👤')
    }
    .width('100%')
    .height(TABBAR_H)
    .padding({ left: 6, right: 6, bottom: 10 })
    .backgroundColor(BG_2)
    .linearGradient({
      angle: 180,
      colors: [
        ['rgba(10,12,16,0.6)', 0.0],
        ['rgba(10,12,16,0.95)', 1.0]
      ]
    })
    .border({ width: { top: 1 }, color: BORDER })
  }

  @Builder
  TabItem(index: number, label: string, icon: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(20)
        .fontColor(this.currentTab === index ? MINT : TEXT_3)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? MINT : TEXT_3)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
    }
    .layoutWeight(1)
    .padding({ top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index;
    })
  }

  // 中间 AI Tab 凸起圆形
  @Builder
  AiTabItem(index: number) {
    Column() {
      Text('✦')
        .fontSize(20)
        .fontColor(BG)
        .width(44).height(44)
        .borderRadius(R_FULL)
        .linearGradient({
          angle: 135,
          colors: [[MINT, 0.0], [PURPLE, 1.0]]
        })
        .textAlign(TextAlign.Center)
        .shadow({
          radius: 20,
          color: MINT,
          offsetX: 0,
          offsetY: 6
        })
    }
    .layoutWeight(1)
    .padding({ top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index;
    })
  }
}
