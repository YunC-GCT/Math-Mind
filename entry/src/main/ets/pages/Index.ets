/**
 * MathMind 涓诲鍣?鈥?5 Tab 搴曢儴瀵艰埅锛堝惈涓ぎ AI 娓愬彉鍑歌捣鍦嗭級
 * 瀵圭収 HTML .tabbar > .tab脳4 + .tab-ai脳1
 * 瀵圭収 CSS  height:74px, backdrop-filter:blur(24px), border-top
 *
 * 绗?W1 璋冩暣 (2026-07-14):
 *   - 鍒犻櫎 AiChatOverlay 鑰佹棫瀵硅瘽鐣岄潰
 *   - AI Tab 鍐呭鏀逛负鍗犱綅, 鍒囧埌 AI Tab 鏃惰嚜鍔ㄥ紑 AgentFloatWindow 娴獥
 *   - 鍏ㄥ眬 showCamera 娴眰鐘舵€?(HomePage FAB / AI 馃摲 閮借Е鍙?
 *   - 鎷嶅畬: 寮哄埗鍥?AgentFloatWindow 娴獥 (涓嶅啀璺?AI Tab)
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
  { idx: 0, name: '棣栭〉', icon: $r('app.media.ic_home') },
  { idx: 1, name: '绗旇', icon: $r('app.media.ic_notes') },
  { idx: 2, name: 'AI', icon: $r('app.media.ic_ai') },
  { idx: 3, name: '澶嶄範', icon: $r('app.media.ic_review') },
  { idx: 4, name: '鎴戠殑', icon: $r('app.media.ic_me') },
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
    // W1.3: 鍏抽棴绯荤粺閿洏閬胯, 閰嶅悎 AgentFloatWindow 鐩戝惉 keyboardHeightChange 鑷繁涓婄Щ
    // 璁?Index Stack 鏁翠綋涓嶈閿洏椤惰捣鏉? TabBar / HomePage 涓嶅姩
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    } catch (e) {
      // 闃插尽鎬? API 璋冪敤澶辫触, 娴獥閿洏閬胯鍙兘澶辨晥, 涓氬姟鍙户缁?
    }
  }

  // AI 閲岀偣鎷嶇収 (W1 璋冩暣: 鎷嶇収鍚庡洖娴獥, 姝ゅ洖璋冩殏淇濈暀)
  private goCamera = (): void => {
    this.showCamera = true;
  };

  // 鎷嶇収瀹屾垚 鈫?寮哄埗鍥炲埌娴獥瀵硅瘽绐楀彛 (涓嶈涔嬪墠娴獥鏄紑鏄叧)
  private onCameraConfirm = (uri: string, _src: 'camera' | 'album'): void => {
    this.showCamera = false;
    // 浠讳綍鎷嶇収鍚庨兘鍥炴诞绐?(涓嶅啀璺?AI Tab + AiChatOverlay 鑰佹棫鐣岄潰)
    this.showAgentFloat = true;
    this.pendingImageUri = uri;
    setTimeout(() => { this.pendingImageUri = ''; }, 100);
  };

  // AgentFloatWindow: 鍏抽棴娴獥
  private closeAgentFloat = (): void => {
    this.showAgentFloat = false;
  };

    // AgentFloatWindow: 鐐规媿鐓?鈫?鍏堝叧 AI 娴獥, 鍐嶅紑鐩告満
    private goCameraFromAgent = (): void => {
      this.showAgentFloat = false;
      this.showCamera = true;
    };

  build() {
    Stack() {
      Column() {
      // ===== 鍐呭鍖?=====
      Tabs({ index: this.cur, controller: this.tc }) {
        TabContent() {
          HomePage({
            onGoCamera: (): void => { this.showCamera = true; },
            onGoReview: (): void => { this.cur = 3; this.tc.changeIndex(3); },
          });
        }

        // 绗旇 Tab (绗?2 鎵? 鐪熷疄鍒楄〃)
        TabContent() {
          NotesPage();
        }

        // AI Tab (W1 璋冩暣: 鍗犱綅鑳屾櫙, 娴獥鍦?Stack 鍏ㄥ眬娓叉煋)
        TabContent() {
          Column()
            .width('100%').height('100%')
            .backgroundColor(BG_DARK);
        }

        // 澶嶄範 Tab (W1 璋冩暣: '鍘?AI 瀵硅瘽' 鎸夐挳缁?鍔熻兘鏈紑鍙?鎻愮ず)
        TabContent() {
          ReviewPage({
            onGoAI: (): void => {
              promptAction.showToast({ message: 'AI 瀵硅瘽鍔熻兘寮€鍙戜腑', duration: 1500 });
            }
          });
        }

        // 鎴戠殑 Tab (绗?2 鎵? 澶村儚 + 缁熻 + 5 鑿滃崟)
        TabContent() {
          MePage();
        }
      }
      .barHeight(0)
      .layoutWeight(1)
      .scrollable(false)
      .onChange((i: number) => {
        this.cur = i;
        // 鍒囧埌 AI Tab 鏃惰嚜鍔ㄥ紑 AgentFloatWindow 娴獥
        if (i === 2) {
          this.showAgentFloat = true;
        }
      });

      // ===== 鑷畾涔?TabBar 74vp =====
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

    // ===== 鍏ㄥ眬 CameraOverlay 娴眰 (鍦?Stack 鍐?Column 澶? 鍏ㄥ睆瑕嗙洊) =====
    if (this.showCamera) {
      CameraOverlay({
        onClose: (): void => { this.showCamera = false; },
        onConfirm: this.onCameraConfirm,
      });
    }

    // ===== 鍏ㄥ眬 AgentFloatWindow 娴眰 (W1.1 璋冩暣: 涓€鐩村瓨鍦? 涓嶅啀鍙?if 鎺у埗, 璁?messages 鐘舵€佽法寮€鍏充繚鐣? =====
    AgentFloatWindow({
      show: this.showAgentFloat,
      onClose: this.closeAgentFloat,
      onGoCamera: this.goCameraFromAgent,
      pendingImageUri: this.pendingImageUri,
    });
  }
  .width('100%').height('100%');
}

  // ========== 鏅€?Tab ==========
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

  // ========== 涓ぎ AI 娓愬彉鍑歌捣鍦?==========
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
