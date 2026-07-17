/**
 * NoteDaoMVP.ets — 关系型数据库访问层 (MVP 版)
 *
 * 任务编号: A1
 * 接口约定:
 *   insert(unit: KnowledgeUnitExt): Promise<number>   // 返回 rowId
 *   queryById(id: string): Promise<KnowledgeUnitExt | null>
 *
 * 使用 HarmonyOS RDB（relationalStore）。
 * JSON 数组字段（tags、fields、truthDetails、needsUserInput）序列化为 TEXT。
 */

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { KnowledgeUnitExt, KnowledgeCategory } from 'agents';
import { getRdbStore } from './DatabaseHelperMVP';

export class NoteDaoMVP {

  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 插入一条知识单元到 notes 表。
   *
   * @param unit 知识单元
   * @returns rowId（数字）
   */
  async insert(unit: KnowledgeUnitExt): Promise<number> {
    const store: relationalStore.RdbStore = await getRdbStore(this.context);

    // 生成 ID（如未设置）
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

      // 复习系统字段（默认值）
      'reviewStatus': 'new',
      'nextReviewAt': Date.now() + 24 * 60 * 60 * 1000,
      'intervalDays': 1,
      'easeFactor': 2.5,
      'repetitions': 0,
    };

    const rowId: number = await store.insert('notes', values);
    unit.id = id;
    console.info('[NoteDaoMVP] insert ' + '\u6210\u529F: id=' + id + ', rowId=' + String(rowId));
    return rowId;
  }

  /**
   * 按 id 更新已有知识单元的全部字段（WHERE id = unit.id）
   *
   * 更新范围：title / content / tags / fields / truthFlag / truthDetails
   *           / difficulty / importance / needsUserInput / updatedAt / source / userId
   * 注意：type（最小类）和 createdAt 不更新，因为分类和时间应保持不变
   *
   * @param unit 知识单元（id 字段用于 WHERE 条件，其余字段写入 SET）
   */
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
      // 注意：reviewStatus / nextReviewAt / intervalDays / easeFactor / repetitions
      //       不由 update 修改，由复习系统专用方法管理
    };

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('notes');
    predicates.equalTo('id', unit.id);

    const affectedRows: number = await store.update(values, predicates);
    console.info('[NoteDaoMVP] update ' + '\u6210\u529F: id=' + unit.id + ', rows=' + String(affectedRows));
  }

  /**
   * 按 ID 查询知识单元。
   *
   * @param id 知识单元 ID
   * @returns KnowledgeUnitExt 或 null
   */
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

  /**
   * 将 ResultSet 当前行转换为 KnowledgeUnitExt
   *
   * @param rs ResultSet（已定位到目标行）
   * @returns KnowledgeUnitExt
   */
  private rowToUnit(rs: relationalStore.ResultSet): KnowledgeUnitExt {
    const now: number = Date.now();
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
}
