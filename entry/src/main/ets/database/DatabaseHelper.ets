/**
 * DatabaseHelper.ets — RDB 数据库初始化与管理
 *
 * 任务编号: A1 配套
 * 依赖: 无
 *
 * 管理 notes 表的创建和数据库实例。
 * 使用 HarmonyOS 原生 RDB（relationalStore）。
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/** 数据库文件名 */
const DB_NAME: string = 'mathmind.db';

/** 数据库版本 */
const DB_VERSION: number = 1;

/** notes 表建表 SQL */
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
  'userId TEXT' +
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

  console.info('[DatabaseHelper] RDB 初始化完成: ' + DB_NAME);
  return rdbStoreInstance;
}
