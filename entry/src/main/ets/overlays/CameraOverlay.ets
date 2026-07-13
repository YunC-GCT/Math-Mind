/**
 * MathMind 相机浮层 — 第 3 批
 * 状态机: camera (选/拍) -> preview (确认)
 *
 * 触发: HomePage FAB [+]  /  AI 浮层 → 拍照
 * 流程: 拍/选图 -> imageUri -> onConfirm 回调
 *
 * MVP 阶段:
 *   - 拍照/选图都用 mock uri(模拟器无相机权限,build 跑通优先)
 *   - 真实 cameraPicker / photoViewPicker 调用代码注释保留,W1 接续
 *   - 业务层 AiService.capture() 是空壳,所以 confirm 直接回调给父组件
 *
 * 后续 (W1):
 *   - 替换 mock 为真 cameraPicker (API 12+)
 *   - 调 AiService.capture(uri) -> KnowledgeUnit
 *   - 失败时降级 toast 提示
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BG_CARD,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG,
} from 'common';

// 浮层状态
type CameraState = 'camera' | 'preview';

// 顶层 mock 工具(ArkTS 禁 struct 内普通方法)
function mockCaptureUri(src: 'camera' | 'album'): string {
  return `mock_${src}_${Date.now()}.jpg`;
}

@Component
export struct CameraOverlay {
  @State state: CameraState = 'camera';
  @State capturedUri: string = '';
  @State capturedSrc: 'camera' | 'album' | '' = '';
  @State busy: boolean = false;

  // 回调
  onClose: () => void = () => {};
  onConfirm: (uri: string, src: 'camera' | 'album') => void = () => {};

  build() {
    Stack() {
      // ===== 半透明遮罩 =====
      Column()
        .width('100%').height('100%')
        .backgroundColor('#CC000000');

      // ===== 浮层主体 =====
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

        if (this.state === 'camera') {
          this.CameraView();
        } else {
          this.PreviewView();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  // ========== 相机状态 UI ==========
  @Builder
  CameraView() {
    Column() {
      // 顶栏
      Row() {
        this.CloseBtn();
        Blank();
        Text('拍照记题')
          .fontSize(F_MD)
          .fontColor(TEXT)
          .fontWeight(600);
        Blank();
        Column().width(36).height(36);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 });

      // 相机预览占位(深色)
      Stack() {
        Column() {
          Text('📷')
            .fontSize(72)
            .fontColor(TEXT_3);
          Text('相机预览')
            .fontSize(F_MD)
            .fontColor(TEXT_2)
            .margin({ top: 16 });
          Text('对准题目点击下方快门')
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 6 });
        }
        .alignItems(HorizontalAlign.Center);

        // 模拟取景框(4 角 L 形)
        this.ViewfinderCorners();
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FF000000')
      .margin({ top: 8 });

      // 底部按钮区
      Row() {
        // 相册
        this.AlbumBtn();
        Blank();
        // 快门
        this.ShutterBtn();
        Blank();
        // 占位(保持对称,留给翻转)
        Column().width(56).height(56);
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 24, bottom: 50 })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%').height('100%');
  }

  // 取景框 4 角
  @Builder
  ViewfinderCorners() {
    Stack() {
      // 左上
      Column()
        .width(20).height(2)
        .backgroundColor(MINT)
        .position({ x: 24, y: 24 });
      Column()
        .width(2).height(20)
        .backgroundColor(MINT)
        .position({ x: 24, y: 24 });
      // 右上
      Column()
        .width(20).height(2)
        .backgroundColor(MINT)
        .position({ x: '100%', y: 24 })
        .markAnchor({ x: 20, y: 0 });
      Column()
        .width(2).height(20)
        .backgroundColor(MINT)
        .position({ x: '100%', y: 24 })
        .markAnchor({ x: 0, y: 0 });
      // 左下
      Column()
        .width(20).height(2)
        .backgroundColor(MINT)
        .position({ x: 24, y: '100%' })
        .markAnchor({ x: 0, y: -2 });
      Column()
        .width(2).height(20)
        .backgroundColor(MINT)
        .position({ x: 24, y: '100%' })
        .markAnchor({ x: 0, y: -20 });
      // 右下
      Column()
        .width(20).height(2)
        .backgroundColor(MINT)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: -20, y: -2 });
      Column()
        .width(2).height(20)
        .backgroundColor(MINT)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: 0, y: -20 });
    }
    .width('100%').height('100%');
  }

  // ========== 预览状态 UI ==========
  @Builder
  PreviewView() {
    Column() {
      // 顶栏(返回 + 标题)
      Row() {
        this.BackBtn();
        Blank();
        Text('确认图片')
          .fontSize(F_MD)
          .fontColor(TEXT)
          .fontWeight(600);
        Blank();
        Column().width(36).height(36);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 });

      // 图片区域
      Stack() {
        if (this.capturedUri.length > 0) {
          // MVP: mock uri,显示占位 + 文字
          Column() {
            Text('🖼')
              .fontSize(80)
              .fontColor(TEXT_3);
            Text(this.capturedSrc === 'camera' ? '已拍摄' : '从相册选择')
              .fontSize(F_SM)
              .fontColor(TEXT_2)
              .margin({ top: 12 });
            Text(this.capturedUri)
              .fontSize(10)
              .fontColor(TEXT_4)
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .padding({ left: 24, right: 24 });
          }
          .alignItems(HorizontalAlign.Center);
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FF1A1A1A');

      // 底部按钮: 重拍 + 确认
      Row() {
        this.RetakeBtn();
        Blank().width(12);
        this.ConfirmBtn();
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 40 })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%').height('100%');
  }

  // ========== 通用按钮 ==========

  // 关闭
  @Builder
  CloseBtn() {
    Stack() {
      Text('✕')
        .fontSize(18)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(36).height(36)
    .borderRadius(18)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  // 返回
  @Builder
  BackBtn() {
    Stack() {
      Text('‹')
        .fontSize(28)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(36).height(36)
    .borderRadius(18)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => {
      this.state = 'camera';
      this.capturedUri = '';
      this.capturedSrc = '';
    });
  }

  // 相册
  @Builder
  AlbumBtn() {
    Stack() {
      Text('🖼')
        .fontSize(22);
    }
    .width(56).height(56)
    .borderRadius(28)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => this.pickAlbum());
  }

  // 快门
  @Builder
  ShutterBtn() {
    Stack() {
      Stack()
        .width(68).height(68)
        .borderRadius(34)
        .backgroundColor('#33FFFFFF');
      Stack()
        .width(56).height(56)
        .borderRadius(28)
        .linearGradient({ angle: 180, colors: [[MINT, 0], [MINT_DARK, 1]] });
    }
    .width(76).height(76)
    .alignContent(Alignment.Center)
    .onClick(() => this.takePhoto());
  }

  // 重拍
  @Builder
  RetakeBtn() {
    Row() {
      Text('重拍')
        .fontSize(F_BASE)
        .fontColor(TEXT)
        .fontWeight(600);
    }
    .layoutWeight(1)
    .height(50)
    .borderRadius(25)
    .backgroundColor('#1AFFFFFF')
    .border({ width: 1, color: BORDER })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.state = 'camera';
      this.capturedUri = '';
      this.capturedSrc = '';
    });
  }

  // 确认
  @Builder
  ConfirmBtn() {
    Row() {
      if (this.busy) {
        LoadingProgress()
          .width(20).height(20)
          .color(BG_DARK);
      } else {
        Text('✓ 使用此图')
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .fontWeight(700);
      }
    }
    .layoutWeight(1)
    .height(50)
    .borderRadius(25)
    .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.busy || this.capturedUri.length === 0) {
        return;
      }
      this.busy = true;
      const uri = this.capturedUri;
      const src = this.capturedSrc === 'camera' ? 'camera' : 'album';
      this.onConfirm(uri, src);
    });
  }

  // ========== 行为(箭头函数,不让成为 struct 方法) ==========
  private takePhoto = (): void => {
    this.capturedUri = mockCaptureUri('camera');
    this.capturedSrc = 'camera';
    this.state = 'preview';
  };

  private pickAlbum = (): void => {
    this.capturedUri = mockCaptureUri('album');
    this.capturedSrc = 'album';
    this.state = 'preview';
  };
}
