// MathMind - 数据库初始化工具
// 责任: Z
// 创建: 2026-07-14 — 精简拍照链 RDB 基础设施
// 更新: 2026-07-15 — 新增 study_plan 表 (学习计划)

import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: "MathMind.db",
  securityLevel: relationalStore.SecurityLevel.S1,
};

const SQL_CREATE_KNOWLEDGE: string = `
CREATE TABLE IF NOT EXISTS knowledge_unit (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT "",
  summary TEXT NOT NULL DEFAULT "",
  tags TEXT NOT NULL DEFAULT "[]",
  difficulty INTEGER NOT NULL DEFAULT 1,
  source TEXT NOT NULL DEFAULT "",
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  review_status TEXT NOT NULL DEFAULT "new",
  next_review_at INTEGER NOT NULL DEFAULT 0,
  interval_days INTEGER NOT NULL DEFAULT 0,
  ease_factor REAL NOT NULL DEFAULT 2.5,
  repetitions INTEGER NOT NULL DEFAULT 0,
  prerequisites TEXT NOT NULL DEFAULT "[]",
  related TEXT NOT NULL DEFAULT "[]",
  embedding TEXT NOT NULL DEFAULT "[]",
  user_id TEXT NOT NULL DEFAULT "",
  version INTEGER NOT NULL DEFAULT 1
)`;

const SQL_CREATE_STUDY_PLAN: string = `
CREATE TABLE IF NOT EXISTS study_plan (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT "",
  is_done INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 2,
  linked_note_id TEXT NOT NULL DEFAULT "",
  created_at INTEGER NOT NULL DEFAULT 0,
  due_date INTEGER NOT NULL DEFAULT 0
)`;

const SQL_INDEX_KNOWLEDGE_CREATED: string =
  "CREATE INDEX IF NOT EXISTS idx_knowledge_unit_created_at ON knowledge_unit(created_at)";
const SQL_INDEX_KNOWLEDGE_REVIEW: string =
  "CREATE INDEX IF NOT EXISTS idx_knowledge_unit_review_status ON knowledge_unit(review_status)";
const SQL_INDEX_STUDY_PLAN_DONE: string =
  "CREATE INDEX IF NOT EXISTS idx_study_plan_is_done ON study_plan(is_done)";

export class DatabaseHelper {
  private static store: relationalStore.RdbStore | null = null;

  static async init(context: Context): Promise<relationalStore.RdbStore> {
    if (DatabaseHelper.store !== null) {
      return DatabaseHelper.store;
    }
    return new Promise<relationalStore.RdbStore>((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err: BusinessError, store: relationalStore.RdbStore) => {
        if (err) {
          reject(new Error("RDB init failed: " + err.message));
          return;
        }
        // 串行建表：先 knowledge_unit，再 study_plan
        store.executeSql(SQL_CREATE_KNOWLEDGE, [], () => {
          store.executeSql(SQL_CREATE_STUDY_PLAN, [], () => {
            store.executeSql(SQL_INDEX_KNOWLEDGE_CREATED, [], () => {
              store.executeSql(SQL_INDEX_KNOWLEDGE_REVIEW, [], () => {
                store.executeSql(SQL_INDEX_STUDY_PLAN_DONE, [], () => {
                  DatabaseHelper.store = store;
                  resolve(store);
                });
              });
            });
          });
        });
      });
    });
  }

  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store;
  }
}
