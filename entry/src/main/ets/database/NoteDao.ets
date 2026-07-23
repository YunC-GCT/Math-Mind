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

const NOTE_METADATA_COLUMNS: string[] = [
  'id', 'title', 'summary', 'tags', 'subject', 'category', 'difficulty', 'source',
  'created_at', 'updated_at', 'review_status', 'next_review_at', 'interval_days',
  'ease_factor', 'repetitions', 'user_id', 'version',
];

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

  // List and grouping pages only need metadata. Full content is loaded by id when a detail opens.
  async queryAllMetadata(): Promise<KnowledgeUnit[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_unit');
    predicates.orderByDesc('created_at');

    return new Promise<KnowledgeUnit[]>((resolve, reject) => {
      this.store.query(predicates, NOTE_METADATA_COLUMNS, (_err, resultSet) => {
        if (_err) {
          reject(new Error('NoteDao.queryAllMetadata failed: ' + _err.message));
          return;
        }
        const units: KnowledgeUnit[] = [];
        if (resultSet.goToFirstRow()) {
          do {
            units.push(NoteDao.rowToMetadataUnit(resultSet));
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
      id: NoteDao.readString(rs, 'id', ''),
      title: NoteDao.readString(rs, 'title', ''),
      content: NoteDao.readString(rs, 'content', ''),
      summary: NoteDao.readString(rs, 'summary', ''),
      tags: NoteDao.parseArray(NoteDao.readString(rs, 'tags', '[]')),
      subject: NoteDao.readString(rs, 'subject', ''),
      category: NoteDao.readString(rs, 'category', ''),
      chapter: NoteDao.readString(rs, 'chapter', ''),
      difficulty: NoteDao.parseDifficulty(NoteDao.readLong(rs, 'difficulty', DifficultyLevel.EASY)),
      source: NoteDao.readString(rs, 'source', ''),
      createdAt: NoteDao.readLong(rs, 'created_at', 0),
      updatedAt: NoteDao.readLong(rs, 'updated_at', 0),
      reviewStatus: NoteDao.parseReviewStatus(NoteDao.readString(rs, 'review_status', ReviewStatus.NEW)),
      nextReviewAt: NoteDao.readLong(rs, 'next_review_at', 0),
      intervalDays: NoteDao.readLong(rs, 'interval_days', 0),
      easeFactor: NoteDao.readDouble(rs, 'ease_factor', 2.5),
      repetitions: NoteDao.readLong(rs, 'repetitions', 0),
      prerequisites: NoteDao.parseArray(NoteDao.readString(rs, 'prerequisites', '[]')),
      related: NoteDao.parseArray(NoteDao.readString(rs, 'related', '[]')),
      embedding: NoteDao.parseNumberArray(NoteDao.readString(rs, 'embedding', '[]')),
      userId: NoteDao.readString(rs, 'user_id', ''),
      version: NoteDao.readLong(rs, 'version', 1),
    };
  }

  private static rowToMetadataUnit(rs: relationalStore.ResultSet): KnowledgeUnit {
    return {
      id: NoteDao.readString(rs, 'id', ''),
      title: NoteDao.readString(rs, 'title', ''),
      content: '',
      summary: NoteDao.readString(rs, 'summary', ''),
      tags: NoteDao.parseArray(NoteDao.readString(rs, 'tags', '[]')),
      subject: NoteDao.readString(rs, 'subject', ''),
      category: NoteDao.readString(rs, 'category', ''),
      difficulty: NoteDao.parseDifficulty(NoteDao.readLong(rs, 'difficulty', DifficultyLevel.EASY)),
      source: NoteDao.readString(rs, 'source', ''),
      createdAt: NoteDao.readLong(rs, 'created_at', 0),
      updatedAt: NoteDao.readLong(rs, 'updated_at', 0),
      reviewStatus: NoteDao.parseReviewStatus(NoteDao.readString(rs, 'review_status', ReviewStatus.NEW)),
      nextReviewAt: NoteDao.readLong(rs, 'next_review_at', 0),
      intervalDays: NoteDao.readLong(rs, 'interval_days', 0),
      easeFactor: NoteDao.readDouble(rs, 'ease_factor', 2.5),
      repetitions: NoteDao.readLong(rs, 'repetitions', 0),
      prerequisites: [],
      related: [],
      embedding: [],
      userId: NoteDao.readString(rs, 'user_id', ''),
      version: NoteDao.readLong(rs, 'version', 1),
    };
  }

  private static toBucket(unit: KnowledgeUnit): relationalStore.ValuesBucket {
    return {
      'id': unit.id,
      'title': unit.title,
      'content': unit.content,
      'summary': unit.summary,
      'tags': NoteDao.stringifyArray(unit.tags),
      'subject': unit.subject,
      'category': unit.category,
      'chapter': unit.chapter,
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

  private static readString(rs: relationalStore.ResultSet, columnName: string, fallback: string): string {
    const index: number = NoteDao.safeColumnIndex(rs, columnName);
    if (index < 0) {
      return fallback;
    }
    return rs.getString(index);
  }

  private static readLong(rs: relationalStore.ResultSet, columnName: string, fallback: number): number {
    const index: number = NoteDao.safeColumnIndex(rs, columnName);
    if (index < 0) {
      return fallback;
    }
    return rs.getLong(index);
  }

  private static readDouble(rs: relationalStore.ResultSet, columnName: string, fallback: number): number {
    const index: number = NoteDao.safeColumnIndex(rs, columnName);
    if (index < 0) {
      return fallback;
    }
    return rs.getDouble(index);
  }

  private static safeColumnIndex(rs: relationalStore.ResultSet, columnName: string): number {
    try {
      return rs.getColumnIndex(columnName);
    } catch (e) {
      console.warn('[NoteDao.rowToUnit] missing column ' + columnName + ': ' + ((e as Error).message ?? String(e)));
      return -1;
    }
  }
}
