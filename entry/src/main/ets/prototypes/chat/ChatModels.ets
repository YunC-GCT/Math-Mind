export interface ChatMsg {
  id: number
  role: string
  content: string
  ts: number
}

export interface ChatSession {
  id: string
  name: string
  messages: ChatMsg[]
}
