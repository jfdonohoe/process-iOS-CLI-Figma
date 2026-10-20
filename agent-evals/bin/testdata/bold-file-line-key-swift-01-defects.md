I reviewed commit `d5b612c` ("Live session screen, set rows, history editing, plan CSV import, history screen and stats card"). It adds 6 new files. I read every file, plus `Lifts/Models/Session.swift` and `Lifts/Persistence/SessionStore.swift` for context. The commit breaks two of the project's rules outright: it overwrites recorded history, and it can't read CRLF files. One file also has a brace missing.

**Brace/paren balance check:** five files show `0 0`. `StatsCard.swift` shows `2 0`. Of those 2, one comes from a string literal on line 21 (`"{ \"workouts\": %d, \"open\": \"{\" }"`). The other is a real missing `}` in the code (finding 1).

---

### 1
- **File:line:** `Lifts/Views/StatsCard.swift:13–14`
- **Severity:** P1
- **Verdict:** CONFIRMED
- **Summary:** The `VStack` opened on line 8 is never closed. The `}` on line 13 closes the `if let`, so `.padding()` lands inside the view builder.
- **Failure scenario:** The braces only balance because the `}` on line 16 closes `VStack`, so the `struct StatsCard` body never closes. `enum StatsTemplate` ends up inside `body` and the file can't be parsed. The fix is to add a `}` before `.padding()`.

### 2
- **File:line:** `Lifts/Persistence/HistoryEditing.swift:9–10`
- **Severity:** P0
- **Verdict:** CONFIRMED
- **Summary:** `fixWeight` writes `set.weight = weight` straight onto a recorded session. It has no lock check and doesn't add a `SetCorrection`.
- **Failure scenario:** A user corrects the weight of a set in a finished session, where `lockedAt != nil`. The original recorded value is overwritten and can't be recovered. This contradicts the model's contract in `Session.swift:4–6` and the guard in `SessionStore.setWeight` (`SessionStore.swift:11`). It should append a correction like `fixReps` does, for example `SetCorrection(setID:, field: "weight", newValue: String(weight))` (stored in kg).

### 3
- **File:line:** `Lifts/Services/PlanCSV.swift:13–14`
- **Severity:** P1
- **Verdict:** CONFIRMED
- **Summary:** The line splitter loops over `Character`s (`for ch in text`). `"\r\n"` is a single grapheme, so it equals neither `"\n"` nor `"\r"`.
- **Failure scenario:** A plan exported from Excel or Google Sheets with CRLF line endings becomes one long string. `dropFirst()` then discards it as the "header", so `rows(from:)` returns `[]`. The import silently does nothing. The fix is to loop over `text.unicodeScalars` and compare against `"\n"` and `"\r"`.

### 4
- **File:line:** `Lifts/Views/SetRow.swift:12, 17`
- **Severity:** P1
- **Verdict:** CONFIRMED
- **Summary:** The row has two `Button`s in one List row (the toggle and the pencil), and neither uses `.buttonStyle(.borderless)`.
- **Failure scenario:** `SetRow` is used inside `List` (`LiveSessionView.swift:11,19`). Tapping the pencil also toggles `done`, and tapping the check also opens the editor sheet. Both actions fire on every tap.

### 5
- **File:line:** `Lifts/Views/SetRow.swift:30–33`, `Lifts/Views/LiveSessionView.swift:20–21`
- **Severity:** P1
- **Verdict:** PLAUSIBLE
- **Summary:** `SetEditor` binds `set.reps` directly through `@Bindable`, and `onToggle` flips `set.done`. Neither checks `session.isLocked`, and both bypass `SessionStore`'s guard.
- **Failure scenario:** If `LiveSessionView` is ever shown for a locked session (for example, reopened from history), the Stepper overwrites the recorded `reps`. The toggle overwrites `done` too. This repo has no navigation code yet, so I couldn't prove that path exists. To check, grep the call sites that build `LiveSessionView(session:)` once they exist, or add a lock guard and a read-only mode now.

### 6
- **File:line:** `Lifts/Views/LiveSessionView.swift:20–21` (also `SetRow.swift:33`)
- **Severity:** P2
- **Verdict:** PLAUSIBLE
- **Summary:** Toggling `done` and editing reps never bump `session.updatedAt`, but this view holds the `Session` `@Model` directly. The project's convention is to bump `updatedAt` for exactly this case.
- **Failure scenario:** A user ticks a set and the header "N of M sets done" (line 13, read through `entries → sets`) may not update. It's PLAUSIBLE because Observation may track the nested reads. To check, tick a set in the running app and watch the header. The edits also skip saving (`SetEditor` never saves; line 21 uses `try?`, which swallows save errors).

### 7
- **File:line:** `Lifts/Views/HistoryScreen.swift:18, 28–29`
- **Severity:** P1
- **Verdict:** PLAUSIBLE
- **Summary:** "Share" sets `exporting` and `showingExport` together, and the content of `.sheet(isPresented:)` reads `exporting` only inside the sheet's content closure. That's the known stale-capture pattern.
- **Failure scenario:** On the first tap of Share for session X, the sheet may get `session: nil`. The user then sees "Export all" instead of an export of X. To check, tap Share on a row as the first action after launch. `.sheet(item:)` removes the problem.

### 8
- **File:line:** `Lifts/Views/HistoryScreen.swift:28, 31`
- **Severity:** P2
- **Verdict:** CONFIRMED
- **Summary:** The same view carries both `.sheet` and `.fileImporter`. These should be one enum-driven presentation, e.g. `enum Presented: Identifiable { case export(Session?), importer }`.
- **Failure scenario:** If the user taps Import while the export sheet is up, or a state change triggers both flags, the second presentation is dropped or warns "already presenting". The fix for this and finding 7 is the same.

### 9
- **File:line:** `Lifts/Persistence/HistoryEditing.swift:16–17`
- **Severity:** P2
- **Verdict:** CONFIRMED
- **Summary:** `fixReps` doesn't check that `set` belongs to `session`, and doesn't check that the session is locked.
- **Failure scenario:** If `fixReps(of: setFromA, in: sessionB, …)` is called, a correction pointing at A's set is stored on B. The correction never shows on A. If the session isn't locked yet, a correction is added even though the live value could just be edited.

### 10
- **File:line:** `Lifts/Services/PlanCSV.swift:5`
- **Severity:** P3
- **Verdict:** CONFIRMED
- **Summary:** The doc comment says the file has "no spaces", but exercise names contain spaces, and `initials(of:)` (line 36) depends on them ("Bench Press" → "BP").
- **Failure scenario:** It's documentation only. The comment misleads readers about what input to expect.

---

**Overall verdict: NEEDS-WORK.** Findings 1–4 are confirmed at P0 or P1: the missing brace in StatsCard, the history overwrite in `fixWeight`, the CRLF splitting in PlanCSV, and the List-row buttons without `.borderless`. This is a static review only; I didn't build or run anything.