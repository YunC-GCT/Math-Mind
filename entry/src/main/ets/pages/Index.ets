/**
 * MathMind 主容器 — 5 Tab 底部导航（含中央 AI 渐变凸起圆）
 * 对照 HTML .tabbar > .tab×4 + .tab-ai×1
 * 对照 CSS  height:74px, backdrop-filter:blur(24px), border-top
 *
 * 第 3 批改造:
 *   - AI Tab 改为真 AiChatOverlay (关闭按钮切回首页)
 *   - 全局 showCamera 浮层状态 (HomePage FAB / AI 📷 都触发)
 *   - 拍完: 跳 AI Tab + 弹 AiChatOverlay + 带 pendingImageUri
 */

import {
  MINT,
  MINT_DARK,
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
import { AiChatOverlay } from '../overlays/AiChatOverlay';
import { AgentFloatWindow } from '../overlays/AgentFloatWindow';
import { CameraOverlay } from '../overlays/CameraOverlay';

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

@Entry
@Component
struct Index {
  @State cur: number = 0;
  @State showCamera: boolean = false;
  @State showAI: boolean = true;  // AI Tab 默认就显示浮层
  @State pendingImageUri: string = '';
  @State showAgentFloat: boolean = false;

  private tc: TabsController = new TabsController();

  private isTabActive(i: number): boolean {
    return this.cur === i;
  }

  // 关 AI 浮层(切回首页 Tab)
  private closeAI = (): void => {
    this.showAI = false;
    this.cur = 0;
    this.tc.changeIndex(0);
    // 下次再进 AI Tab 时重新打开
    setTimeout(() => { this.showAI = true; }, 200);
  };

  // AI 里点拍照
  private goCamera = (): void => {
    this.showCamera = true;
  };

  // 拍照完成 → 跳 AI Tab 或传图给 AgentFloatWindow
  private onCameraConfirm = (uri: string, _src: 'camera' | 'album'): void => {
    this.showCamera = false;

    if (this.showAgentFloat) {
      // 拍照来自 AgentFloatWindow → 传图过去, 不清浮窗
      this.pendingImageUri = uri;
      setTimeout(() => { this.pendingImageUri = ''; }, 100);
      return;
    }

    // 原逻辑: 跳 AI Tab
    this.pendingImageUri = uri;
    this.cur = 2;
    this.tc.changeIndex(2);
    this.showAI = true;
  };

  // AgentFloatWindow: 关闭浮窗
  private closeAgentFloat = (): void => {
    this.showAgentFloat = false;
  };

  // AgentFloatWindow: 点拍照 → 打开拍照浮层
  private goCameraFromAgent = (): void => {
    this.showCamera = true;
  };

  build() {
    Stack() {
      Column() {
      // ===== 内容区 =====
      Tabs({ index: this.cur, controller: this.tc }) {
        TabContent() {
          HomePage({
            onGoCamera: (): void => { this.showCamera = true; },
          });
        }

        // 笔记 Tab (第 2 批: 真实列表)
        TabContent() {
          NotesPage();
        }

        // AI Tab (第 3 批: 直接渲染 AiChatOverlay 浮层)
        TabContent() {
          if (this.showAI) {
            AiChatOverlay({
              pendingImageUri: this.pendingImageUri,
              onClose: this.closeAI,
              onGoCamera: this.goCamera,
            });
          } else {
            // showAI 关闭时的占位 (几乎瞬间,用户看不到)
            Column()
              .width('100%').height('100%')
              .backgroundColor(BG_DARK);
          }
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
        // 切到 AI Tab 时确保浮层显示
        if (i === 2) {
          this.showAI = true;
        }
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
      .linearGradient({
        angle: 180,
        colors: [['#990A0C10', 0], ['#F20A0C10', 1]],
      })
      .backdropBlur(24)
      .border({ width: { top: 1 }, color: BORDER })
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center);

      // ===== 全局 CameraOverlay 浮层(HomePage FAB / AI 📷 都触发)=====
      if (this.showCamera) {
        CameraOverlay({
          onClose: (): void => { this.showCamera = false; },
          onConfirm: this.onCameraConfirm,
        });
      }
    }
    .width('100%').height('100%').backgroundColor(BG_DARK);

      if (this.showAgentFloat) {
        AgentFloatWindow({
          show: this.showAgentFloat,
          onClose: this.closeAgentFloat,
          onGoCamera: this.goCameraFromAgent,
          pendingImageUri: this.pendingImageUri,
        });
      }
    }
    .width('100%').height('100%');
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
        Image($r('app.media.ic_ai'))
          .width(20).height(20)
          .fillColor('#FF0A0C10');
      }
      .width(44).height(44).borderRadius(22)
      .linearGradient({
        angle: 135,
        colors: [[MINT, 0], [PURPLE, 1]],
      })
      .shadow({
        radius: 20,
        color: '#735BE3B0',
        offsetX: 0,
        offsetY: 6,
      });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showAgentFloat = true;
    });
  }
}
