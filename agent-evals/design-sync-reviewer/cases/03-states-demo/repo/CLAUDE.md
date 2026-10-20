# Larkspur

## Figma
Screens are approved in Figma and built from the Approved page. Frame specs exported with
figma-frame-spec.js live in `_reports/design-sync/`.

## UI rules
- Green (`Color.leaf`) means actionable; it also marks a completed state. Destructive actions use the system red, never green.
- In iOS lists, put the section header outside the list rows (a `Section` header), never as the first row.
- Overdue plants are marked with `Color.thirsty`.
## Simulator demo state
`Larkspur/Debug/SampleDataSeeder.swift`: launch with `-larkspurSampleData` for sample plants, or
`-larkspurSampleFlow=<phase>` to render one watering phase. Production frames are captured from these.
