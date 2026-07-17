/**
 * DatabaseHelperMVP.ets — RDB 数据库初始化与管理 (MVP 版)
 *
 * 管理 notes 表的创建和数据库实例。
 * 使用 HarmonyOS 原生 RDB（relationalStore）。
 * 表结构兼容 KnowledgeUnitExt 的所有字段。
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/** 数据库文件名 */
const DB_NAME: string = 'mathmind.db';

/** 数据库版本 */
const DB_VERSION: number = 1;

/** notes 表建表 SQL（兼容 KnowledgeUnitExt 所有字段 + 复习系统字段） */
const CREATE_NOTES_TABLE: string =
  'CREATE TABLE IF NOT EXISTS notes (' +
  'id TEXT PRIMARY KEY,' +
  'type TEXT NOT NULL,' +
  'title TEXT NOT NULL,' +
  'content TEXT NOT NULL,' +
  'tags TEXT,' +
  'fields TEXT,' +
  'truthFlag INTEGER DEFAULT 1,' +
  'truthDetails TEXT,' +
  'difficulty INTEGER DEFAULT 3,' +
  'importance INTEGER DEFAULT 3,' +
  'needsUserInput TEXT,' +
  'createdAt INTEGER NOT NULL,' +
  'updatedAt INTEGER NOT NULL,' +
  'source TEXT,' +
  'userId TEXT,' +

  // ── 复习系统字段（间隔重复） ──
  'reviewStatus TEXT DEFAULT \'new\',' +
  'nextReviewAt INTEGER DEFAULT 0,' +
  'intervalDays INTEGER DEFAULT 1,' +
  'easeFactor REAL DEFAULT 2.5,' +
  'repetitions INTEGER DEFAULT 0' +
  ')';

/** 单例 RdbStore */
let rdbStoreInstance: relationalStore.RdbStore | null = null;

/**
 * 获取 RdbStore 实例（单例，懒加载）
 *
 * @param context UIAbilityContext
 * @returns RdbStore 实例
 */
export async function getRdbStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
  if (rdbStoreInstance !== null) {
    return rdbStoreInstance;
  }

  const config: relationalStore.StoreConfig = {
    name: DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1,
  };

  rdbStoreInstance = await relationalStore.getRdbStore(context, config);
  await rdbStoreInstance.executeSql(CREATE_NOTES_TABLE);

  console.info('[DatabaseHelperMVP] RDB ' + '\u521D\u59CB\u5316\u5B8C\u6210: ' + DB_NAME);
  return rdbStoreInstance;
}
