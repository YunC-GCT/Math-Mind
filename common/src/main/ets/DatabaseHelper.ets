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

const DB_SCHEMA_VERSION: number = 3;

const SQL_CREATE_KNOWLEDGE: string = `
CREATE TABLE IF NOT EXISTS knowledge_unit (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT "",
  summary TEXT NOT NULL DEFAULT "",
  tags TEXT NOT NULL DEFAULT "[]",
  subject TEXT NOT NULL DEFAULT "",
  category TEXT NOT NULL DEFAULT "",
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

const SQL_CREATE_CHAT_MESSAGE: string = `
CREATE TABLE IF NOT EXISTS chat_message (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT "",
  created_at INTEGER NOT NULL
)`;

const SQL_CREATE_AGENT_MEMORY: string = `
CREATE TABLE IF NOT EXISTS agent_memory (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT "",
  source TEXT NOT NULL DEFAULT "",
  used INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)`;

const SQL_INDEX_KNOWLEDGE_CREATED: string =
  "CREATE INDEX IF NOT EXISTS idx_knowledge_unit_created_at ON knowledge_unit(created_at)";
const SQL_INDEX_KNOWLEDGE_REVIEW: string =
  "CREATE INDEX IF NOT EXISTS idx_knowledge_unit_review_status ON knowledge_unit(review_status)";
const SQL_INDEX_STUDY_PLAN_DONE: string =
  "CREATE INDEX IF NOT EXISTS idx_study_plan_is_done ON study_plan(is_done)";
const SQL_INDEX_CHAT_MESSAGE_SESSION_CREATED: string =
  "CREATE INDEX IF NOT EXISTS idx_chat_message_session_created ON chat_message(session_id, created_at)";
const SQL_INDEX_AGENT_MEMORY_PENDING: string =
  "CREATE INDEX IF NOT EXISTS idx_agent_memory_pending ON agent_memory(session_id, type, used, created_at)";
const SQL_INDEX_AGENT_MEMORY_SUMMARY: string =
  "CREATE INDEX IF NOT EXISTS idx_agent_memory_summary ON agent_memory(session_id, type, created_at)";

const SQL_MIGRATE_KNOWLEDGE_SUBJECT: string =
  "ALTER TABLE knowledge_unit ADD COLUMN subject TEXT NOT NULL DEFAULT \"\"";
const SQL_MIGRATE_KNOWLEDGE_CATEGORY: string =
  "ALTER TABLE knowledge_unit ADD COLUMN category TEXT NOT NULL DEFAULT \"\"";

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
        DatabaseHelper.ensureSchema(store).then(() => {
          DatabaseHelper.store = store;
          resolve(store);
        }).catch((schemaErr: Error) => {
          reject(schemaErr);
        });
      });
    });
  }

  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store;
  }

  private static async ensureSchema(store: relationalStore.RdbStore): Promise<void> {
    const statements: string[] = [
      SQL_CREATE_KNOWLEDGE,
      SQL_CREATE_STUDY_PLAN,
      SQL_CREATE_CHAT_MESSAGE,
      SQL_CREATE_AGENT_MEMORY,
      SQL_INDEX_KNOWLEDGE_CREATED,
      SQL_INDEX_KNOWLEDGE_REVIEW,
      SQL_INDEX_STUDY_PLAN_DONE,
      SQL_INDEX_CHAT_MESSAGE_SESSION_CREATED,
      SQL_INDEX_AGENT_MEMORY_PENDING,
      SQL_INDEX_AGENT_MEMORY_SUMMARY,
    ];

    for (const sql of statements) {
      await DatabaseHelper.executeSql(store, sql);
    }

    const hasSubject: boolean = await DatabaseHelper.hasColumn(store, "knowledge_unit", "subject");
    if (!hasSubject) {
      await DatabaseHelper.executeAddColumn(store, SQL_MIGRATE_KNOWLEDGE_SUBJECT);
    }
    const hasCategory: boolean = await DatabaseHelper.hasColumn(store, "knowledge_unit", "category");
    if (!hasCategory) {
      await DatabaseHelper.executeAddColumn(store, SQL_MIGRATE_KNOWLEDGE_CATEGORY);
    }

    if (store.version < DB_SCHEMA_VERSION) {
      store.version = DB_SCHEMA_VERSION;
    }
  }

  private static async executeSql(store: relationalStore.RdbStore, sql: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      store.executeSql(sql, [], (err: BusinessError) => {
        if (err) {
          reject(new Error("DatabaseHelper.executeSql failed: " + err.message));
          return;
        }
        resolve();
      });
    });
  }

  private static async hasColumn(
    store: relationalStore.RdbStore,
    tableName: string,
    columnName: string,
  ): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      store.querySql("PRAGMA table_info(" + tableName + ")", [], (err: BusinessError, rs: relationalStore.ResultSet) => {
        if (err) {
          reject(new Error("DatabaseHelper.hasColumn failed: " + err.message));
          return;
        }
        let found: boolean = false;
        if (rs.goToFirstRow()) {
          do {
            const name: string = rs.getString(rs.getColumnIndex("name"));
            if (name === columnName) {
              found = true;
              break;
            }
          } while (rs.goToNextRow());
        }
        rs.close();
        resolve(found);
      });
    });
  }

  private static async executeAddColumn(store: relationalStore.RdbStore, sql: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      store.executeSql(sql, [], (err: BusinessError) => {
        if (err) {
          if (DatabaseHelper.isDuplicateColumnError(err.message)) {
            resolve();
            return;
          }
          reject(new Error("DatabaseHelper.executeAddColumn failed: " + err.message));
          return;
        }
        resolve();
      });
    });
  }

  private static isDuplicateColumnError(message: string): boolean {
    const normalized: string = message.toLowerCase();
    return normalized.includes("duplicate column")
      || normalized.includes("already exists")
      || normalized.includes("duplicate")
      || normalized.includes("exists")
      || normalized.includes("重复")
      || normalized.includes("已存在")
      || normalized.includes("已经存在");
  }
}
