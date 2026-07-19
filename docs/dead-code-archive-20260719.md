# Dead Code Archive - 2026-07-19

## Scope

This archive records files confirmed as unused by active business code on 2026-07-19.

Checked active paths:

- `entry/src/main/ets`
- `common/src/main/ets`
- `agents/src/main/ets`
- `skill/src/main/ets`
- `cardservice/src/main/ets`
- `entry/src/main/resources`
- `entry/src/main/module.json5`

Excluded from reachability decisions:

- `docs`
- `README.md`
- `AGENTS.md`
- `archive`

## Confirmed Unused Files

These files are not imported, routed, exported through active module entrypoints, or referenced by active configuration.

| File | Status | Note |
| --- | --- | --- |
| `entry/src/main/ets/pages/Notes/NotesList.ets` | Unused | Old flat notes list. `NotesPage` now uses `SubjectGrid` and routes into `SubjectDetailPage`. |
| `entry/src/main/ets/overlays/CameraOverlay/CameraTypes.ets` | Unused | `CameraOverlay.ets` defines local `CameraState` and `CaptureSource` types. |
| `entry/src/main/ets/pages/AiSettings/SectionHeader.ets` | Unused | AI settings page renders section headings inline. |
| `entry/src/main/ets/overlays/NoteDetailOverlay/ConfDot.ets` | Unused | Note detail metadata no longer renders the confidence dot component. |
| `common/src/main/ets/utils/timeWindow.ets` | Unused | Utility is not imported and not exported from `common/src/main/ets/Index.ets`. |
| `common/src/main/ets/utils/confidenceSort.ets` | Unused | Utility is not imported and not exported from `common/src/main/ets/Index.ets`. |
| `agents/src/main/ets/models/NoteDaoInterface.ets` | Unused | Active agent code no longer imports it; references only exist in archived MVP experiments. |

## Not Dead Code

- `entry/src/main/ets/entryability/EntryAbility.ets`: registered in `entry/src/main/module.json5`.
- `entry/src/main/ets/entrybackupability/EntryBackupAbility.ets`: registered in `entry/src/main/module.json5`.
- `entry/src/main/ets/pages/Notes/SubjectDetailPage.ets`: registered in `main_pages.json` and opened by `NotesPage`.
- `entry/src/main/ets/utils/MathTextParser.ets`: used by `MathTextRenderer.ets`.

## Recommended Cleanup Order

1. Remove the four unused UI/local-type files first:
   `NotesList.ets`, `CameraTypes.ets`, `SectionHeader.ets`, `ConfDot.ets`.
2. Decide separately whether to delete or revive the three utility/interface files:
   `timeWindow.ets`, `confidenceSort.ets`, `NoteDaoInterface.ets`.
3. Update stale README/docs references after deletion, especially `NotesList` and `SectionHeader`.
