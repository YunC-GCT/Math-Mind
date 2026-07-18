// ============================================================================
//  viewmodels/NotesViewModel.ets - notes list data logic
// ============================================================================

import { DatabaseHelper, KnowledgeUnit, NoteItem } from "common"
import { NoteDao } from "../database/NoteDao"
import { unitsToNoteItems } from "../utils/NoteItemMapper"

@Observed
export class NotesViewModel {
  notes: NoteItem[] = []
  units: KnowledgeUnit[] = []

  async loadNotes(context: Context): Promise<boolean> {
    try {
      const store = await DatabaseHelper.init(context)
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.units = units
      this.notes = unitsToNoteItems(units)
      return true
    } catch (_e) {
      this.units = []
      this.notes = []
      return false
    }
  }

  async loadNote(context: Context, id: string): Promise<KnowledgeUnit | null> {
    if (id.length === 0) {
      return null
    }
    try {
      const store = await DatabaseHelper.init(context)
      return await new NoteDao(store).queryById(id)
    } catch (_e) {
      return null
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