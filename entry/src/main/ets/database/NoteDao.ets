// MathMind - NoteDao (知识单元数据访问层)
// 任务编号: A1
// 责任: Z
// 状态: 实现完成(2026-07-14) — 精简拍照链
//
// 接口:
//   insert(unit: KnowledgeUnit): Promise<number>        // 返回 rowId
//   queryById(id: string): Promise<KnowledgeUnit | null> // 按主键查询
//
// 验证方式: insert → 返回 rowId → queryById 查回

import { relationalStore } from '@kit.ArkData';
import { KnowledgeUnit, DifficultyLevel, ReviewStatus } from 'common';

export class NoteDao {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  // 插入知识单元, 返回 rowId
  async insert(unit: KnowledgeUnit): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'id': unit.id,
      'title': unit.title,
      'content': unit.content,
      'summary': unit.summary,
      'tags': JSON.stringify(unit.tags),
      'difficulty': unit.difficulty.valueOf(),
      'source': unit.source,
      'created_at': unit.createdAt,
      'updated_at': unit.updatedAt,
      'review_status': unit.reviewStatus.valueOf(),
      'next_review_at': unit.nextReviewAt,
      'interval_days': unit.intervalDays,
      'ease_factor': unit.easeFactor,
      'repetitions': unit.repetitions,
      'prerequisites': JSON.stringify(unit.prerequisites),
      'related': JSON.stringify(unit.related),
      'embedding': JSON.stringify(unit.embedding),
      'user_id': unit.userId,
      'version': unit.version,
    };

    return new Promise<number>((resolve, reject) => {
      this.store.insert('knowledge_unit', valueBucket, (err, rowId) => {
        if (err) {
          reject(new Error('NoteDao.insert failed: ' + err.message));
          return;
        }
        resolve(rowId);
      });
    });
  }

  // 按 id 查询
  async queryById(id: string): Promise<KnowledgeUnit | null> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.equalTo('id', id);

    return new Promise<KnowledgeUnit | null>((resolve, reject) => {
      this.store.query(predicates, ['*'], (_err, resultSet) => {
        if (_err) {
          reject(new Error('NoteDao.queryById failed: ' + _err.message));
          return;
        }
        if (resultSet.goToFirstRow()) {
          const unit: KnowledgeUnit = NoteDao.rowToUnit(resultSet);
          resultSet.close();
          resolve(unit);
        } else {
          resultSet.close();
          resolve(null);
        }
      });
    });
  }

  // 将 RDB 行转为 KnowledgeUnit
  static rowToUnit(rs: relationalStore.ResultSet): KnowledgeUnit {
    return {
      id: rs.getString(rs.getColumnIndex('id')),
      title: rs.getString(rs.getColumnIndex('title')),
      content: rs.getString(rs.getColumnIndex('content')),
      summary: rs.getString(rs.getColumnIndex('summary')),
      tags: NoteDao.parseArray(rs.getString(rs.getColumnIndex('tags'))),
      difficulty: rs.getLong(rs.getColumnIndex('difficulty')) as number,
      source: rs.getString(rs.getColumnIndex('source')),
      createdAt: rs.getLong(rs.getColumnIndex('created_at')) as number,
      updatedAt: rs.getLong(rs.getColumnIndex('updated_at')) as number,
      reviewStatus: rs.getString(rs.getColumnIndex('review_status')) as ReviewStatus,
      nextReviewAt: rs.getLong(rs.getColumnIndex('next_review_at')) as number,
      intervalDays: rs.getLong(rs.getColumnIndex('interval_days')) as number,
      easeFactor: rs.getDouble(rs.getColumnIndex('ease_factor')),
      repetitions: rs.getLong(rs.getColumnIndex('repetitions')) as number,
      prerequisites: NoteDao.parseArray(rs.getString(rs.getColumnIndex('prerequisites'))),
      related: NoteDao.parseArray(rs.getString(rs.getColumnIndex('related'))),
      embedding: NoteDao.parseNumberArray(rs.getString(rs.getColumnIndex('embedding'))),
      userId: rs.getString(rs.getColumnIndex('user_id')),
      version: rs.getLong(rs.getColumnIndex('version')) as number,
    };
  }

  private static parseArray(json: string): string[] {
    try {
      return JSON.parse(json) as string[];
    } catch (e) {
      return [];
    }
  }

  private static parseNumberArray(json: string): number[] {
    try {
      return JSON.parse(json) as number[];
    } catch (e) {
      return [];
    }
  }
}