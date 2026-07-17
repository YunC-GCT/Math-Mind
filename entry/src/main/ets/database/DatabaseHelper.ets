/**
 * DatabaseHelper.ets — RDB 数据库初始化与管理
 *
 * 路径: entry/src/main/ets/database/DatabaseHelper.ets
 * 职责: 管理 notes 表的创建和数据库实例（懒加载单例）。
 * 依赖: @kit.ArkData (relationalStore)、@kit.AbilityKit (common)
 *
 * 数据流:
 *   任意调用方 → getRdbStore(context) → 懒加载 RdbStore → executeSql(CREATE_NOTES_TABLE)
 *   → 返回 RdbStore 实例供 NoteDao/StudyPlanDao 使用
 *
 * ArkTS 1.1 strict 适配:
 *   - 模块级单例变量显式类型 (relationalStore.RdbStore | null)
 *   - 异步函数返回类型显式标注 Promise<...>
 *   - config 对象用 StoreConfig 接口显式声明字段
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
