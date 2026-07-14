/**
 * MathMind 主容器 — 5 Tab 底部导航（含中央 AI 渐变凸起圆）
 * 对照 HTML .tabbar > .tab×4 + .tab-ai×1
 * 对照 CSS  height:74px, backdrop-filter:blur(24px), border-top
 *
 * 第 W1 调整 (2026-07-14):
 *   - 删除 AiChatOverlay 老旧对话界面
 *   - AI Tab 内容改为占位, 切到 AI Tab 时自动开 AgentFloatWindow 浮窗
 *   - 全局 showCamera 浮层状态 (HomePage FAB / AI 📷 都触发)
 *   - 拍完: 强制回 AgentFloatWindow 浮窗 (不再跳 AI Tab)
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
import { AgentFloatWindow } from '../overlays/AgentFloatWindow';
import { CameraOverlay } from '../overlays/CameraOverlay';
import { promptAction, KeyboardAvoidMode } from '@kit.ArkUI';

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
  @State pendingImageUri: string = '';
  @State showAgentFloat: boolean = false;

  private tc: TabsController = new TabsController();

  private isTabActive(i: number): boolean {
    return this.cur === i;
  }

  aboutToAppear(): void {
    // W1.3 修复 (Part 2/2): 关闭系统键盘避让
    // 配合 AgentFloatWindow 监听 keyboardHeightChange 自己上移
    // 让 Index Stack 整体不被键盘顶起来, TabBar / HomePage 不动
    // 备注: KeyboardAvoidMode 影响整个 UIContext, 这里关闭后 AgentFloatWindow 自己处理
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
  }

  // AI 里点拍照 (W1 调整: 拍照后回浮窗, 此回调暂保留)
  private goCamera = (): void => {
    this.showCamera = true;
  };

  // 拍照完成 → 强制回到浮窗对话窗口 (不论之前浮窗是开是关)
  private onCameraConfirm = (uri: string, _src: 'camera' | 'album'): void => {
    this.showCamera = false;
    // 任何拍照后都回浮窗 (不再跳 AI Tab + AiChatOverlay 老旧界面)
    this.showAgentFloat = true;
    this.pendingImageUri = uri;
    setTimeout(() => { this.pendingImageUri = ''; }, 100);
  };

  // AgentFloatWindow: 关闭浮窗
  private closeAgentFloat = (): void => {
    this.showAgentFloat = false;
  };

    // AgentFloatWindow: 点拍照 → 先关 AI 浮窗, 再开相机
    private goCameraFromAgent = (): void => {
      this.showAgentFloat = false;
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

        // AI Tab (W1 调整: 占位背景, 浮窗在 Stack 全局渲染)
        TabContent() {
          Column()
            .width('100%').height('100%')
            .backgroundColor(BG_DARK);
        }

        // 复习 Tab (W1 调整: '去 AI 对话' 按钮给'功能未开发'提示)
        TabContent() {
          ReviewPage({
            onGoAI: (): void => {
              promptAction.showToast({ message: 'AI 对话功能开发中', duration: 1500 });
            }
          });
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
        // 切到 AI Tab 时自动开 AgentFloatWindow 浮窗
        if (i === 2) {
          this.showAgentFloat = true;
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
    }
    .width('100%').height('100%').backgroundColor(BG_DARK);

    // ===== 全局 CameraOverlay 浮层 (在 Stack 内 Column 外, 全屏覆盖) =====
    if (this.showCamera) {
      CameraOverlay({
        onClose: (): void => { this.showCamera = false; },
        onConfirm: this.onCameraConfirm,
      });
    }

    // ===== 全局 AgentFloatWindow 浮层 (W1.1 调整: 一直存在, 不再受 if 控制, 让 messages 状态跨开关保留) =====
    AgentFloatWindow({
      show: this.showAgentFloat,
      onClose: this.closeAgentFloat,
      onGoCamera: this.goCameraFromAgent,
      pendingImageUri: this.pendingImageUri,
    });
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
