// ============================================================================
//  viewmodels/NotesViewModel.ets - notes list data logic
// ============================================================================

import { DatabaseHelper, KnowledgeUnit, NoteItem } from "common"
import { NoteDao } from "../database/NoteDao"
import { unitsToNoteItems } from "../utils/NoteItemMapper"

@Observed
export class NotesViewModel {
  notes: NoteItem[] = []

  async loadNotes(context: Context): Promise<boolean> {
    try {
      const store = await DatabaseHelper.init(context)
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = unitsToNoteItems(units)
      return true
    } catch (_e) {
      this.notes = []
      return false
    }
  }

  async deleteNote(context: Context, id: string): Promise<boolean> {
    try {
      const store = await DatabaseHelper.init(context)
      await new NoteDao(store).deleteById(id)
      return await this.loadNotes(context)
    } catch (_e) {
      return false
    }
  }
}
