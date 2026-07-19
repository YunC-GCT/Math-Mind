export type ChatRole = 'system' | 'user' | 'assistant';

export type AgentMemoryType = 'pending_note' | 'summary' | 'ocr_result';

export interface ChatMessageRecord {
  id: string;
  sessionId: string;
  role: ChatRole;
  content: string;
  createdAt: number;
}

export interface AgentMemoryRecord {
  id: string;
  sessionId: string;
  type: AgentMemoryType;
  content: string;
  source: string;
  used: number;
  createdAt: number;
  updatedAt: number;
}

export interface AgentMemoryContext {
  summary: string;
  pendingNotes: AgentMemoryRecord[];
  recentMessages: ChatMessageRecord[];
  text: string;
}
