/**
 * MathMind 主容器 — 5 Tab 底部导航 · MVP 版
 *
 * 基于 Index.ets 修改:
 *   使用 AgentFloatWindowMVP 替代 AgentFloatWindow
 *   有图片时走 AiServiceMVP → KnowledgeModelMVP 管线
 *   纯文本时保持普通 AI 对话
 *
 * 原文件 Index.ets 未改动
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
import { AgentFloatWindowMVP } from '../overlays/AgentFloatWindowMVP';
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
struct IndexMVP {
  @State cur: number = 0;
  @State showCamera: boolean = false;
  @State pendingImageUri: string = '';
  @State showAgentFloat: boolean = false;

  private tc: TabsController = new TabsController();

  private isTabActive(i: number): boolean {
    return this.cur === i;
  }

  aboutToAppear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    } catch (e) {
      // 防御性
    }
  }

  private goCamera = (): void => {
    this.showCamera = true;
  };

  private onCameraConfirm = (uri: string, _src: 'camera' | 'album'): void => {
    this.showCamera = false;
    this.showAgentFloat = true;
    this.pendingImageUri = uri;
    setTimeout(() => { this.pendingImageUri = ''; }, 100);
  };

  private closeAgentFloat = (): void => {
    this.showAgentFloat = false;
  };

    private goCameraFromAgent = (): void => {
      this.showAgentFloat = false;
      this.showCamera = true;
    };

  build() {
    Stack() {
      Column() {
      Tabs({ index: this.cur, controller: this.tc }) {
        TabContent() {
          HomePage({
            onGoCamera: (): void => { this.showCamera = true; },
          });
        }

        TabContent() {
          NotesPage();
        }

        TabContent() {
          Column()
            .width('100%').height('100%')
            .backgroundColor(BG_DARK);
        }

        TabContent() {
          ReviewPage({
            onGoAI: (): void => {
              promptAction.showToast({ message: 'AI 对话功能开发中', duration: 1500 });
            }
          });
        }

        TabContent() {
          MePage();
        }
      }
      .barHeight(0)
      .layoutWeight(1)
      .scrollable(false)
      .onChange((i: number) => {
        this.cur = i;
        if (i === 2) {
          this.showAgentFloat = true;
        }
      });

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

    if (this.showCamera) {
      CameraOverlay({
        onClose: (): void => { this.showCamera = false; },
        onConfirm: this.onCameraConfirm,
      });
    }

    // ===== 全局 AgentFloatWindowMVP 浮层 =====
    AgentFloatWindowMVP({
      show: this.showAgentFloat,
      onClose: this.closeAgentFloat,
      onGoCamera: this.goCameraFromAgent,
      pendingImageUri: this.pendingImageUri,
    });
  }
  .width('100%').height('100%');
}

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
