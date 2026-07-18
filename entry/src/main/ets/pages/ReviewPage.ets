/**
 * MathMind 复习计划页 - 本地间隔复习闭环
 */

import {
  MINT,
  MINT_DARK,
  MINT_LIGHT,
  PURPLE,
  AMBER,
  BG_DARK,
  BG_CARD,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  R_MD,
  R_FULL,
  F_XS,
  F_SM,
  F_BASE,
  F_LG,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NoteDaoMVP, ReviewRating, ReviewScheduleItem, ReviewStatus } from '../database/NoteDaoMVP';

interface ReviewFilterItem {
  idx: number;
  label: string;
}

interface RatingOption {
  value: ReviewRating;
  label: string;
  color: string;
}

const REVIEW_FILTERS: ReviewFilterItem[] = [
  { idx: 0, label: '今日' },
  { idx: 1, label: '本周' },
  { idx: 2, label: '已掌握' },
];

const RATING_OPTIONS: RatingOption[] = [
  { value: 'forgot', label: '忘了', color: '#FFFF6B6B' },
  { value: 'vague', label: '模糊', color: AMBER },
  { value: 'remembered', label: '记住', color: MINT },
  { value: 'skilled', label: '熟练', color: PURPLE },
];

@Component
export struct ReviewPage {
  onGoAI: () => void = () => {};

  @State items: ReviewScheduleItem[] = [];
  @State filterIdx: number = 0;
  @State selectedId: string = '';
  @State selectedRating: ReviewRating = 'remembered';
  @State reviewedTodayCount: number = 0;
  @State loading: boolean = false;

  private dao: NoteDaoMVP | null = null;

  aboutToAppear(): void {
    this.refreshReviewItems();
  }

  private refreshReviewItems(): void {
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return;
    }

    if (this.dao === null) {
      this.dao = new NoteDaoMVP(hostContext as common.UIAbilityContext);
    }

    this.loading = true;
    const dao: NoteDaoMVP = this.dao as NoteDaoMVP;
    dao.queryByReviewSchedule()
      .then((list: ReviewScheduleItem[]) => {
        this.items = list;
        this.loading = false;
      })
      .catch(() => {
        this.loading = false;
        promptAction.showToast({ message: '复习计划加载失败', duration: 1500 });
      });
  }

  private submitReview(item: ReviewScheduleItem): void {
    if (this.dao === null) {
      return;
    }

    const dao: NoteDaoMVP = this.dao as NoteDaoMVP;
    dao.updateReview(item.id, this.selectedRating)
      .then(() => {
        if (this.isDueToday(item)) {
          this.reviewedTodayCount += 1;
        }
        this.selectedId = '';
        this.refreshReviewItems();
      })
      .catch(() => {
        promptAction.showToast({ message: '复习反馈保存失败', duration: 1500 });
      });
  }

  private visibleItems(): ReviewScheduleItem[] {
    if (this.filterIdx === 0) {
      return this.items.filter((item: ReviewScheduleItem) => this.isDueToday(item));
    }
    if (this.filterIdx === 1) {
      return this.items.filter((item: ReviewScheduleItem) => this.isDueThisWeek(item));
    }
    return this.items.filter((item: ReviewScheduleItem) => item.reviewStatus === 'mastered');
  }

  private todayCount(): number {
    return this.items.filter((item: ReviewScheduleItem) => this.isDueToday(item)).length;
  }

  private weekCount(): number {
    return this.items.filter((item: ReviewScheduleItem) => this.isDueThisWeek(item)).length;
  }

  private progressText(): string {
    const remaining: number = this.todayCount();
    const total: number = remaining + this.reviewedTodayCount;
    if (total === 0) {
      return '100%';
    }
    return String(Math.round(this.reviewedTodayCount / total * 100)) + '%';
  }

  private estimateText(): string {
    const minutes: number = this.todayCount() * 3;
    return minutes === 0 ? '0 分钟' : String(minutes) + ' 分钟';
  }

  private isDueToday(item: ReviewScheduleItem): boolean {
    if (item.reviewStatus === 'mastered') {
      return false;
    }
    const now: Date = new Date();
    const end: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0);
    return item.nextReviewAt < end.getTime();
  }

  private isDueThisWeek(item: ReviewScheduleItem): boolean {
    if (item.reviewStatus === 'mastered') {
      return false;
    }
    const now: Date = new Date();
    const start: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    const end: number = start.getTime() + 7 * 24 * 60 * 60 * 1000;
    return item.nextReviewAt < end;
  }

  private statusText(status: ReviewStatus): string {
    if (status === 'new') {
      return '新内容';
    }
    if (status === 'learning') {
      return '学习中';
    }
    if (status === 'reviewing') {
      return '复习中';
    }
    return '已掌握';
  }

  private statusColor(status: ReviewStatus): string {
    if (status === 'new') {
      return TEXT_2;
    }
    if (status === 'learning') {
      return AMBER;
    }
    if (status === 'reviewing') {
      return MINT;
    }
    return PURPLE;
  }

  private dueText(ts: number): string {
    const now: Date = new Date();
    const target: Date = new Date(ts);
    const todayStart: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    const dayIndex: number = Math.floor((ts - todayStart.getTime()) / (24 * 60 * 60 * 1000));
    const hour: string = target.getHours() < 10 ? '0' + String(target.getHours()) : String(target.getHours());
    const minute: string = target.getMinutes() < 10 ? '0' + String(target.getMinutes()) : String(target.getMinutes());

    if (dayIndex <= 0) {
      return '今天 ' + hour + ':' + minute;
    }
    if (dayIndex === 1) {
      return '明天 ' + hour + ':' + minute;
    }
    if (dayIndex < 7) {
      return String(dayIndex) + ' 天后';
    }
    return String(target.getMonth() + 1) + '月' + String(target.getDate()) + '日';
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text('复习计划')
              .fontSize(F_LG)
              .fontWeight(700)
              .fontColor(TEXT);
            Text('按记忆反馈自动安排下一次复习')
              .fontSize(F_SM)
              .fontColor(TEXT_3)
              .margin({ top: 3 });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          Button('AI')
            .fontSize(F_SM)
            .fontWeight(700)
            .fontColor(BG_DARK)
            .width(48)
            .height(34)
            .borderRadius(R_FULL)
            .linearGradient({
              angle: 135,
              colors: [[MINT, 0], [MINT_DARK, 1]],
            })
            .onClick(() => {
              this.onGoAI();
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })
        .alignItems(VerticalAlign.Center);

        Row() {
          this.StatBox('今日', String(this.todayCount()));
          this.StatBox('本周', String(this.weekCount()));
          this.StatBox('耗时', this.estimateText());
          this.StatBox('进度', this.progressText());
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .justifyContent(FlexAlign.SpaceBetween);

        Row() {
          ForEach(REVIEW_FILTERS, (item: ReviewFilterItem) => {
            this.FilterButton(item);
          }, (item: ReviewFilterItem) => item.idx.toString());
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 4 });

        if (this.loading) {
          Text('加载中...')
            .fontSize(F_SM)
            .fontColor(TEXT_3)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 56 });
        } else if (this.visibleItems().length === 0) {
          this.EmptyState();
        } else {
          ForEach(this.visibleItems(), (item: ReviewScheduleItem, idx: number) => {
            this.ReviewCard(item, idx === this.visibleItems().length - 1);
          }, (item: ReviewScheduleItem) => item.id);
        }

        Blank().height(92);
      }
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_DARK)
    .scrollable(ScrollDirection.Vertical);
  }

  @Builder
  StatBox(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(F_BASE)
        .fontWeight(700)
        .fontColor(TEXT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: 3 });
    }
    .width('23%')
    .height(58)
    .borderRadius(R_MD)
    .backgroundColor(BG_CARD)
    .border({ width: 1, color: BORDER })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  FilterButton(item: ReviewFilterItem) {
    Button(item.label)
      .fontSize(F_SM)
      .fontWeight(600)
      .fontColor(this.filterIdx === item.idx ? BG_DARK : TEXT_2)
      .height(34)
      .layoutWeight(1)
      .margin({ right: item.idx === 2 ? 0 : 8 })
      .borderRadius(R_FULL)
      .backgroundColor(this.filterIdx === item.idx ? MINT : '#1410131A')
      .border({ width: 1, color: this.filterIdx === item.idx ? MINT : BORDER })
      .onClick(() => {
        this.filterIdx = item.idx;
        this.selectedId = '';
      });
  }

  @Builder
  EmptyState() {
    Column() {
      Text(this.filterIdx === 2 ? '暂无已掌握内容' : '当前没有待复习内容')
        .fontSize(F_BASE)
        .fontWeight(600)
        .fontColor(TEXT)
        .margin({ bottom: 8 });
      Text(this.filterIdx === 2 ? '继续完成复习后会自动归档到这里' : '可以去 AI 对话继续整理新笔记')
        .fontSize(F_SM)
        .fontColor(TEXT_3)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 });
      Button('去 AI 对话')
        .fontSize(F_SM)
        .fontWeight(700)
        .fontColor(BG_DARK)
        .width(132)
        .height(38)
        .borderRadius(R_FULL)
        .linearGradient({
          angle: 135,
          colors: [[MINT, 0], [MINT_DARK, 1]],
        })
        .onClick(() => {
          this.onGoAI();
        });
    }
    .width('100%')
    .padding({ top: 64, left: 32, right: 32 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  ReviewCard(item: ReviewScheduleItem, isLast: boolean) {
    Column() {
      Row() {
        Column() {
          Text(item.title)
            .fontSize(F_BASE)
            .fontWeight(700)
            .fontColor(TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%');

          Row() {
            this.MetaText(item.type as string, MINT);
            this.Dot();
            this.MetaText('难度 ' + String(item.difficulty) + '/5', AMBER);
            this.Dot();
            this.MetaText('重要 ' + String(item.importance) + '/5', PURPLE);
          }
          .width('100%')
          .margin({ top: 7 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Text(this.statusText(item.reviewStatus))
          .fontSize(F_XS)
          .fontWeight(700)
          .fontColor(this.statusColor(item.reviewStatus))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(R_FULL)
          .backgroundColor(MINT_LIGHT);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      Row() {
        Text('下次 ' + this.dueText(item.nextReviewAt))
          .fontSize(F_XS)
          .fontColor(TEXT_3);
        Blank();
        Text('间隔 ' + String(item.intervalDays) + ' 天')
          .fontSize(F_XS)
          .fontColor(TEXT_4);
      }
      .width('100%')
      .margin({ top: 10 });

      if (item.reviewStatus !== 'mastered') {
        Row() {
          ForEach(RATING_OPTIONS, (rating: RatingOption) => {
            this.RatingButton(item, rating);
          }, (rating: RatingOption) => rating.value);
        }
        .width('100%')
        .margin({ top: 14 });

        if (this.selectedId === item.id) {
          Button('提交反馈')
            .fontSize(F_SM)
            .fontWeight(700)
            .fontColor(BG_DARK)
            .height(34)
            .width('100%')
            .margin({ top: 10 })
            .borderRadius(R_FULL)
            .backgroundColor(MINT)
            .onClick(() => {
              this.submitReview(item);
            });
        }
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .border({ width: { bottom: isLast ? 0 : 1 }, color: BORDER });
  }

  @Builder
  RatingButton(item: ReviewScheduleItem, rating: RatingOption) {
    Button(rating.label)
      .fontSize(F_XS)
      .fontWeight(700)
      .fontColor(this.selectedId === item.id && this.selectedRating === rating.value ? BG_DARK : rating.color)
      .height(32)
      .layoutWeight(1)
      .margin({ right: rating.value === 'skilled' ? 0 : 8 })
      .borderRadius(R_FULL)
      .backgroundColor(this.selectedId === item.id && this.selectedRating === rating.value ? rating.color : '#1410131A')
      .border({ width: 1, color: rating.color })
      .onClick(() => {
        this.selectedId = item.id;
        this.selectedRating = rating.value;
      });
  }

  @Builder
  MetaText(text: string, color: string) {
    Text(text)
      .fontSize(F_XS)
      .fontColor(color)
      .fontWeight(600)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis });
  }

  @Builder
  Dot() {
    Text(' · ')
      .fontSize(F_XS)
      .fontColor(TEXT_4);
  }
}
