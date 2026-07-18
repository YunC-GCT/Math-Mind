/**
 * NoteDaoMVP.ets - 关系型数据库访问层 (MVP 版)
 */

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { KnowledgeUnitExt, KnowledgeCategory } from 'agents';
import { getRdbStore } from './DatabaseHelperMVP';

export type ReviewRating = 'forgot' | 'vague' | 'remembered' | 'skilled';
export type ReviewStatus = 'new' | 'learning' | 'reviewing' | 'mastered';

export interface ReviewScheduleItem extends KnowledgeUnitExt {
  reviewStatus: ReviewStatus;
  nextReviewAt: number;
  intervalDays: number;
  easeFactor: number;
  repetitions: number;
}

interface ReviewProgress {
  reviewStatus: ReviewStatus;
  nextReviewAt: number;
  intervalDays: number;
  easeFactor: number;
  repetitions: number;
}

export class NoteDaoMVP {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async insert(unit: KnowledgeUnitExt): Promise<number> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);
    const id: string = unit.id && unit.id.length > 0 ? unit.id : 'km_' + String(Date.now());

    const values: relationalStore.ValuesBucket = {
      'id': id,
      'type': unit.type,
      'title': unit.title,
      'content': unit.content,
      'tags': JSON.stringify(unit.tags),
      'fields': JSON.stringify(unit.fields),
      'truthFlag': unit.truthFlag ? 1 : 0,
      'truthDetails': JSON.stringify(unit.truthDetails),
      'difficulty': unit.difficulty,
      'importance': unit.importance,
      'needsUserInput': JSON.stringify(unit.needsUserInput),
      'createdAt': unit.createdAt,
      'updatedAt': unit.updatedAt,
      'source': unit.source,
      'userId': unit.userId,
      'reviewStatus': 'new',
      'nextReviewAt': Date.now() + 24 * 60 * 60 * 1000,
      'intervalDays': 1,
      'easeFactor': 2.5,
      'repetitions': 0,
    };

    const rowId: number = await store.insert('notes', values);
    unit.id = id;
    console.info('[NoteDaoMVP] insert success: id=' + id + ', rowId=' + String(rowId));
    return rowId;
  }

  async update(unit: KnowledgeUnitExt): Promise<void> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);

    const values: relationalStore.ValuesBucket = {
      'title': unit.title,
      'content': unit.content,
      'tags': JSON.stringify(unit.tags),
      'fields': JSON.stringify(unit.fields),
      'truthFlag': unit.truthFlag ? 1 : 0,
      'truthDetails': JSON.stringify(unit.truthDetails),
      'difficulty': unit.difficulty,
      'importance': unit.importance,
      'needsUserInput': JSON.stringify(unit.needsUserInput),
      'updatedAt': Date.now(),
      'source': unit.source,
      'userId': unit.userId,
    };

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
    predicates.equalTo('id', unit.id);

    const affectedRows: number = await store.update(values, predicates);
    console.info('[NoteDaoMVP] update success: id=' + unit.id + ', rows=' + String(affectedRows));
  }

  async queryById(id: string): Promise<KnowledgeUnitExt | null> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
    predicates.equalTo('id', id);

    const resultSet: relationalStore.ResultSet = await store.query(predicates);

    try {
      if (resultSet.rowCount === 0) {
        return null;
      }
      resultSet.goToFirstRow();
      return this.rowToUnit(resultSet);
    } finally {
      resultSet.close();
    }
  }

  async queryByReviewSchedule(): Promise<ReviewScheduleItem[]> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
    predicates.orderByAsc('nextReviewAt');

    const resultSet: relationalStore.ResultSet = await store.query(predicates);
    const list: ReviewScheduleItem[] = [];

    try {
      if (resultSet.rowCount === 0) {
        return list;
      }

      resultSet.goToFirstRow();
      do {
        list.push(this.rowToReviewItem(resultSet));
      } while (resultSet.goToNextRow());

      return list;
    } finally {
      resultSet.close();
    }
  }

  async updateReview(id: string, rating: ReviewRating): Promise<void> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
    predicates.equalTo('id', id);

    const resultSet: relationalStore.ResultSet = await store.query(predicates);
    try {
      if (resultSet.rowCount === 0) {
        console.warn('[NoteDaoMVP] updateReview failed: missing id=' + id);
        return;
      }

      resultSet.goToFirstRow();
      const current: ReviewScheduleItem = this.rowToReviewItem(resultSet);
      const next: ReviewProgress = this.calculateReviewProgress(current, rating);

      const values: relationalStore.ValuesBucket = {
        'reviewStatus': next.reviewStatus,
        'nextReviewAt': next.nextReviewAt,
        'intervalDays': next.intervalDays,
        'easeFactor': next.easeFactor,
        'repetitions': next.repetitions,
        'updatedAt': Date.now(),
      };

      const updatePredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
      updatePredicates.equalTo('id', id);
      const affectedRows: number = await store.update(values, updatePredicates);
      console.info('[NoteDaoMVP] updateReview success: id=' + id + ', rating=' + rating + ', rows=' + String(affectedRows));
    } finally {
      resultSet.close();
    }
  }

  private rowToUnit(rs: relationalStore.ResultSet): KnowledgeUnitExt {
    return {
      id: rs.getString(rs.getColumnIndex('id')),
      type: rs.getString(rs.getColumnIndex('type')) as KnowledgeCategory,
      title: rs.getString(rs.getColumnIndex('title')),
      content: rs.getString(rs.getColumnIndex('content')),
      tags: JSON.parse(rs.getString(rs.getColumnIndex('tags')) || '[]'),
      fields: JSON.parse(rs.getString(rs.getColumnIndex('fields')) || '[]'),
      truthFlag: rs.getLong(rs.getColumnIndex('truthFlag')) === 1,
      truthDetails: JSON.parse(rs.getString(rs.getColumnIndex('truthDetails')) || '[]'),
      difficulty: rs.getLong(rs.getColumnIndex('difficulty')),
      importance: rs.getLong(rs.getColumnIndex('importance')),
      needsUserInput: JSON.parse(rs.getString(rs.getColumnIndex('needsUserInput')) || '[]'),
      createdAt: rs.getLong(rs.getColumnIndex('createdAt')),
      updatedAt: rs.getLong(rs.getColumnIndex('updatedAt')),
      source: rs.getString(rs.getColumnIndex('source')) || '',
      userId: rs.getString(rs.getColumnIndex('userId')) || '',
    };
  }

  private rowToReviewItem(rs: relationalStore.ResultSet): ReviewScheduleItem {
    const unit: KnowledgeUnitExt = this.rowToUnit(rs);
    return {
      id: unit.id,
      type: unit.type,
      title: unit.title,
      content: unit.content,
      tags: unit.tags,
      fields: unit.fields,
      truthFlag: unit.truthFlag,
      truthDetails: unit.truthDetails,
      difficulty: unit.difficulty,
      importance: unit.importance,
      needsUserInput: unit.needsUserInput,
      createdAt: unit.createdAt,
      updatedAt: unit.updatedAt,
      source: unit.source,
      userId: unit.userId,
      reviewStatus: this.readReviewStatus(rs),
      nextReviewAt: rs.getLong(rs.getColumnIndex('nextReviewAt')),
      intervalDays: rs.getLong(rs.getColumnIndex('intervalDays')),
      easeFactor: rs.getDouble(rs.getColumnIndex('easeFactor')),
      repetitions: rs.getLong(rs.getColumnIndex('repetitions')),
    };
  }

  private readReviewStatus(rs: relationalStore.ResultSet): ReviewStatus {
    const raw: string = rs.getString(rs.getColumnIndex('reviewStatus')) || 'new';
    if (raw === 'learning' || raw === 'reviewing' || raw === 'mastered') {
      return raw;
    }
    return 'new';
  }

  private calculateReviewProgress(item: ReviewScheduleItem, rating: ReviewRating): ReviewProgress {
    const dayMs: number = 24 * 60 * 60 * 1000;
    const now: number = Date.now();
    let status: ReviewStatus = item.reviewStatus;
    let intervalDays: number = Math.max(1, item.intervalDays);
    let easeFactor: number = Math.max(1.3, item.easeFactor);
    let repetitions: number = Math.max(0, item.repetitions);

    if (rating === 'forgot') {
      status = 'learning';
      intervalDays = 1;
      easeFactor = Math.max(1.3, easeFactor - 0.2);
      repetitions = 0;
    } else if (rating === 'vague') {
      status = status === 'new' ? 'learning' : status === 'mastered' ? 'reviewing' : status;
      intervalDays = 1;
      easeFactor = Math.max(1.3, easeFactor - 0.1);
    } else if (rating === 'remembered') {
      status = 'reviewing';
      repetitions += 1;
      intervalDays = repetitions <= 1 ? 2 : Math.max(2, Math.round(intervalDays * easeFactor));
    } else {
      repetitions += 1;
      easeFactor = Math.min(3.0, easeFactor + 0.15);
      intervalDays = repetitions <= 1 ? 3 : Math.max(3, Math.round(intervalDays * easeFactor * 1.3));
      status = repetitions >= 4 || intervalDays >= 21 ? 'mastered' : 'reviewing';
    }

    return {
      reviewStatus: status,
      nextReviewAt: now + intervalDays * dayMs,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      repetitions: repetitions,
    };
  }
}
