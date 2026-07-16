// ============================================================================
//  database/NoteDao.ets — 知识单元数据访问层
//  ----------------------------------------------------------------------------
//  职责: RDB CRUD 操作，KnowledgeUnit 与 ValuesBucket 互转。
//  接口:
//    insert(unit): Promise<number>        — 插入，返回 rowId
//    queryById(id): Promise<KnowledgeUnit | null> — 按 id 查询
//    rowToUnit(rs): KnowledgeUnit         — ResultSet → KnowledgeUnit
//  验证方式: insert → 检查 rowId → queryById 验证
//  ============================================================================

import { relationalStore } from '@kit.ArkData';
import { KnowledgeUnit, DifficultyLevel, ReviewStatus } from 'common';

export class NoteDao {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  // 插入知识单元, 返回 rowId
  async insert(unit: KnowledgeUnit): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = NoteDao.toBucket(unit);

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

  // 更新知识单元
  async update(unit: KnowledgeUnit): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.equalTo('id', unit.id);
    const valueBucket: relationalStore.ValuesBucket = NoteDao.toBucket(unit);

    return new Promise<void>((resolve, reject) => {
      this.store.update(valueBucket, predicates, (err, _rows) => {
        if (err) {
          reject(new Error('NoteDao.update failed: ' + err.message));
          return;
        }
        resolve();
      });
    });
  }

  // 删除知识单元
  async deleteById(id: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.equalTo('id', id);

    return new Promise<void>((resolve, reject) => {
      this.store.delete(predicates, (err, _rows) => {
        if (err) {
          reject(new Error('NoteDao.deleteById failed: ' + err.message));
          return;
        }
        resolve();
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

  // 查询全部
  async queryAll(): Promise<KnowledgeUnit[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.orderByDesc('created_at');

    return new Promise<KnowledgeUnit[]>((resolve, reject) => {
      this.store.query(predicates, ['*'], (_err, resultSet) => {
        if (_err) {
          reject(new Error('NoteDao.queryAll failed: ' + _err.message));
          return;
        }
        const units: KnowledgeUnit[] = [];
        if (resultSet.goToFirstRow()) {
          do {
            units.push(NoteDao.rowToUnit(resultSet));
          } while (resultSet.goToNextRow());
        }
        resultSet.close();
        resolve(units);
      });
    });
  }

  // 按复习状态查询
  async queryByReviewStatus(status: ReviewStatus): Promise<KnowledgeUnit[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.equalTo('review_status', status.valueOf());
    predicates.orderByAsc('next_review_at');

    return new Promise<KnowledgeUnit[]>((resolve, reject) => {
      this.store.query(predicates, ['*'], (_err, resultSet) => {
        if (_err) {
          reject(new Error('NoteDao.queryByReviewStatus failed: ' + _err.message));
          return;
        }
        const units: KnowledgeUnit[] = [];
        if (resultSet.goToFirstRow()) {
          do {
            units.push(NoteDao.rowToUnit(resultSet));
          } while (resultSet.goToNextRow());
        }
        resultSet.close();
        resolve(units);
      });
    });
  }

  // ResultSet 转为 KnowledgeUnit
  static rowToUnit(rs: relationalStore.ResultSet): KnowledgeUnit {
    return {
      id: rs.getString(rs.getColumnIndex('id')),
      title: rs.getString(rs.getColumnIndex('title')),
      content: rs.getString(rs.getColumnIndex('content')),
      summary: rs.getString(rs.getColumnIndex('summary')),
      tags: NoteDao.parseArray(rs.getString(rs.getColumnIndex('tags'))),
      difficulty: NoteDao.parseDifficulty(rs.getLong(rs.getColumnIndex('difficulty'))),
      source: rs.getString(rs.getColumnIndex('source')),
      createdAt: rs.getLong(rs.getColumnIndex('created_at')),
      updatedAt: rs.getLong(rs.getColumnIndex('updated_at')),
      reviewStatus: NoteDao.parseReviewStatus(rs.getString(rs.getColumnIndex('review_status'))),
      nextReviewAt: rs.getLong(rs.getColumnIndex('next_review_at')),
      intervalDays: rs.getLong(rs.getColumnIndex('interval_days')),
      easeFactor: rs.getDouble(rs.getColumnIndex('ease_factor')),
      repetitions: rs.getLong(rs.getColumnIndex('repetitions')),
      prerequisites: NoteDao.parseArray(rs.getString(rs.getColumnIndex('prerequisites'))),
      related: NoteDao.parseArray(rs.getString(rs.getColumnIndex('related'))),
      embedding: NoteDao.parseNumberArray(rs.getString(rs.getColumnIndex('embedding'))),
      userId: rs.getString(rs.getColumnIndex('user_id')),
      version: rs.getLong(rs.getColumnIndex('version')),
    };
  }

  private static toBucket(unit: KnowledgeUnit): relationalStore.ValuesBucket {
    return {
      'id': unit.id,
      'title': unit.title,
      'content': unit.content,
      'summary': unit.summary,
      'tags': NoteDao.stringifyArray(unit.tags),
      'difficulty': unit.difficulty.valueOf(),
      'source': unit.source,
      'created_at': unit.createdAt,
      'updated_at': unit.updatedAt,
      'review_status': unit.reviewStatus.valueOf(),
      'next_review_at': unit.nextReviewAt,
      'interval_days': unit.intervalDays,
      'ease_factor': unit.easeFactor,
      'repetitions': unit.repetitions,
      'prerequisites': NoteDao.stringifyArray(unit.prerequisites),
      'related': NoteDao.stringifyArray(unit.related),
      'embedding': NoteDao.stringifyNumberArray(unit.embedding),
      'user_id': unit.userId,
      'version': unit.version,
    };
  }

  private static stringifyArray(value: string[]): string {
    try { return JSON.stringify(value); } catch (e) { return '[]'; }
  }

  private static stringifyNumberArray(value: number[]): string {
    try { return JSON.stringify(value); } catch (e) { return '[]'; }
  }

  private static parseArray(json: string): string[] {
    try { return JSON.parse(json) as string[]; } catch (e) { return []; }
  }

  private static parseNumberArray(json: string): number[] {
    try { return JSON.parse(json) as number[]; } catch (e) { return []; }
  }

  private static parseDifficulty(value: number): DifficultyLevel {
    if (value === DifficultyLevel.EASY) { return DifficultyLevel.EASY; }
    if (value === DifficultyLevel.MEDIUM) { return DifficultyLevel.MEDIUM; }
    if (value === DifficultyLevel.HARD) { return DifficultyLevel.HARD; }
    if (value === DifficultyLevel.EXPERT) { return DifficultyLevel.EXPERT; }
    return DifficultyLevel.EASY;
  }

  private static parseReviewStatus(value: string): ReviewStatus {
    if (value === ReviewStatus.LEARNING) { return ReviewStatus.LEARNING; }
    if (value === ReviewStatus.REVIEW) { return ReviewStatus.REVIEW; }
    if (value === ReviewStatus.GRADUATED) { return ReviewStatus.GRADUATED; }
    if (value === ReviewStatus.LAPSED) { return ReviewStatus.LAPSED; }
    return ReviewStatus.NEW;
  }
}
