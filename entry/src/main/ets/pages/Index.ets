/**
 * MathMind 主容器 — 5 Tab 底部导航（含中央 AI 渐变凸起圆）
 * 对照 HTML .tabbar > .tab×4 + .tab-ai×1
 * 对照 CSS  height:74px, backdrop-filter:blur(24px), border-top
 */

import {
  MINT,
  MINT_DARK,
  MINT_GLOW,
  PURPLE,
  BG_DARK,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  S_1,
  S_2,
  F_XS,
  F_BASE,
  F_3XL,
} from 'common';
import { HomePage } from './HomePage';
import { NotesPage } from './NotesPage';
import { ReviewPage } from './ReviewPage';
import { MePage } from './MePage';

interface TabItem {
  idx: number;
  name: string;
  icon: Resource;
}

const TABS: TabItem[] = [
  { idx: 0, name: '首页', icon: $r('app.media.ic_home') },
  { idx: 1, name: '笔记', icon: $r('app.media.ic_notes') },
  { idx: 2, name: 'AI', icon: $r('app.media.ic_ai') },
  { idx: 3, name: '复习', icon: $r('app.media.ic_review') },
  { idx: 4, name: '我的', icon: $r('app.media.ic_me') },
];

const PH: Record<number, string> = {
  1: '全部笔记列表 (待第 2 批实现)',
  2: 'AI 对话功能 (待第 3 批实现)',
  3: '复习计划内容 (待第 2 批实现)',
  4: '个人中心 (待第 2 批实现)',
};

@Entry
@Component
struct Index {
  @State cur: number = 0;
  private tc: TabsController = new TabsController();

  private tabName(idx: number): string {
    return ['首页', '笔记', 'AI', '复习', '我的'][idx];
  }

  private isTabActive(i: number): boolean {
    return this.cur === i;
  }

  build() {
    Column() {
      // ===== 内容区 =====
      Tabs({ index: this.cur, controller: this.tc }) {
        TabContent() {
          HomePage();
        }

        // 笔记 Tab (第 2 批: 真实列表)
        TabContent() {
          NotesPage();
        }

        // AI Tab (仍占位, 第 3 批做 AiChatOverlay)
        TabContent() {
          this.Place(2);
        }

        // 复习 Tab (第 2 批: 空状态 + 引导)
        TabContent() {
          ReviewPage({ onGoAI: () => { this.cur = 2; this.tc.changeIndex(2); } });
        }

        // 我的 Tab (第 2 批: 头像 + 统计 + 5 菜单)
        TabContent() {
          MePage();
        }
      }
      .barHeight(0)
      .layoutWeight(1)
      .scrollable(false)
      .onChange((i: number) => {
        this.cur = i;
      });

      // ===== 自定义 TabBar 74vp =====
      Row() {
        ForEach(TABS, (tab: TabItem, i: number) => {
          if (i === 2) {
            this.AiBtn(i);
          } else {
            this.TabBtn(tab, i);
          }
        }, (tab: TabItem) => tab.idx.toString());
      }
      .width('100%')
      .height(74)
      .padding({ left: 6, right: 6, bottom: 10 })
      // CSS: background rgba(10,12,16,0.6)~rgba(10,12,16,0.95)
      .linearGradient({
        angle: 180,
        colors: [['#990A0C10', 0], ['#F20A0C10', 1]],
      })
      .backdropBlur(24)
      .border({ width: { top: 1 }, color: BORDER })
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center);
    }
    .width('100%').height('100%').backgroundColor(BG_DARK);
  }

  // ========== 占位页 ==========
  @Builder
  Place(idx: number) {
    Column() {
      Text(this.tabName(idx) + ' Tab')
        .fontSize(F_3XL).fontWeight(700).fontColor(TEXT)
        .margin({ bottom: S_2 });
      Text(PH[idx] || '')
        .fontSize(F_BASE).fontColor(TEXT_3).textAlign(TextAlign.Center);
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).backgroundColor(BG_DARK);
  }

  // ========== 普通 Tab ==========
  @Builder
  TabBtn(tab: TabItem, i: number) {
    Column() {
      Image(tab.icon)
        .width(22).height(22)
        .fillColor(this.isTabActive(i) ? MINT : TEXT_3);
      Text(tab.name)
        .fontSize(F_XS).fontWeight(500)
        .fontColor(this.isTabActive(i) ? MINT : TEXT_3)
        .margin({ top: 2 });
    }
    .layoutWeight(1)
    .padding({ top: 6, bottom: 6 })
    .borderRadius(14)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.cur = i;
      this.tc.changeIndex(i);
    });
  }

  // ========== 中央 AI 渐变凸起圆 ==========
  @Builder
  AiBtn(i: number) {
    Column() {
      Stack() {
        // CSS .tab-ai-icon: 44×44 circle, linear-gradient(135deg, #5BE3B0, #9775FA)
        Circle({ width: 44, height: 44 })
          .fill('#00000000')
          .linearGradient({
            angle: 135,
            colors: [[MINT, 0], [PURPLE, 1]],
          })
          // CSS box-shadow: 0 6px 20px rgba(91,227,176,0.45), 0 0 28px rgba(151,117,250,0.35)
          .shadow({
            radius: 20,
            color: '#735BE3B0',
            offsetX: 0,
            offsetY: 6,
          });

        // CSS .tab-ai-icon svg: 20×20, color:#0A0C10
        Image($r('app.media.ic_ai'))
          .width(20).height(20)
          .fillColor('#FF0A0C10');
      }
      .width(44).height(44);
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.cur = i;
      this.tc.changeIndex(i);
    });
  }
}