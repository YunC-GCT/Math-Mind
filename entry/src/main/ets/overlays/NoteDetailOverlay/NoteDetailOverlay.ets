/**
 * overlays/NoteDetailOverlay/NoteDetailOverlay.ets — 笔记详情浮层装配层
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailOverlay.ets
 * 职责: 全屏笔记详情浮层的装配 + 回调处理
 *
 * 触发: HomePage / NotesPage 点笔记卡片
 *
 * 子组件:
 *   NoteDetailHeader  — drag bar + 学科 chip + 关闭
 *   NoteDetailMeta    — 章节 / 日期 / 置信度
 *   NoteDetailBody    — 标题 + 标签 + 章节 + AI 卡
 *   NoteActionBar     — 底栏删除/编辑/分享
 *
 * 依赖: common, overlays/NoteDetailOverlay/*
 */

import {
  BG_DARK,
  OVERLAY_MASK_SOLID,
  NoteItem,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import { NoteDetailHeader } from './NoteDetailHeader';
import { NoteDetailMeta } from './NoteDetailMeta';
import { NoteDetailBody } from './NoteDetailBody';
import { NoteActionBar } from './NoteActionBar';

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');
  onClose: () => void = (): void => {};
  onAskAi: (note: NoteItem) => void = (_note: NoteItem): void => {};
  onEdit: (id: number) => void = (_id: number): void => {};
  onDelete: (id: string) => void = (_id: string): void => {};

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%').height('100%')
        .backgroundColor(OVERLAY_MASK_SOLID)
        .onClick((): void => this.onClose());

      // 浮层主体
      Column() {
        // 顶栏 (drag bar + 学科 chip + 关闭)
        NoteDetailHeader({
          note: this.note,
          onClose: (): void => this.onClose(),
        });

        // 内容 Scroll 区
        Scroll() {
          Column() {
            // meta 行 (章节/日期/置信度)
            NoteDetailMeta({ note: this.note });

            // 正文区 (标题 + 标签 + 章节 + AI卡)
            NoteDetailBody({
              note: this.note,
              onAskAi: (): void => this.handleAskAi(),
            });
          }
          .width('100%');
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // 底部操作栏
        NoteActionBar({
          onDelete: (): void => this.confirmDelete(),
          onEdit: (): void => this.mockEdit(),
          onShare: (): void => this.mockShare(),
        });
      }
      .width('100%').height('100%')
      .backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  // ===== 回调 =====

  private handleAskAi = (): void => {
    promptAction.showToast({ message: '正在呼叫 AI...', duration: 1500 });
    this.onAskAi(this.note);
  };

  private mockEdit = (): void => {
    promptAction.showToast({ message: '编辑功能 W2 上线', duration: 1500 });
    this.onEdit(this.note.id);
  };

  private mockShare = (): void => {
    promptAction.showToast({ message: '已复制笔记到剪贴板', duration: 1500 });
  };

  private confirmDelete = (): void => {
    this.onDelete(this.note.rawId.length > 0 ? this.note.rawId : this.note.id.toString());
    this.onClose();
  };
}
