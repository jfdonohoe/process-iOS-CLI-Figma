#!/usr/bin/env python3
"""Generate the accessibility-reviewer benchmark. Each case is a small SwiftUI app (Puffin, a reading
tracker) with colour tokens in Theme.swift and an asset catalog. Line numbers in expected.json are computed
from the fixture text, and every contrast pair the key relies on is computed here and asserted, so the key
can't drift from the files."""
import json, shutil, textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parent  # agent-evals/accessibility-reviewer


def d(s):
    return textwrap.dedent(s).lstrip("\n")


def line_of(text, needle, nth=1):
    hits = [i + 1 for i, l in enumerate(text.splitlines()) if needle in l]
    assert len(hits) >= nth, (needle, hits)
    return hits[nth - 1]


def rng(text, start_needle, end_needle=None, pad=0):
    a = line_of(text, start_needle)
    b = line_of(text, end_needle) if end_needle else a
    assert b >= a, (start_needle, end_needle)
    return [max(1, a - pad), b + pad]


def loc(file, lines):
    return {"file": file, "lines": lines}


def write_case(name, repo, expected):
    case = ROOT / "cases" / name
    if case.exists():
        shutil.rmtree(case)
    for rel, txt in repo.items():
        p = case / "repo" / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(txt if isinstance(txt, str) else json.dumps(txt, indent=2) + "\n")
    (case / "expected.json").write_text(json.dumps({"case": name, **expected}, indent=2, ensure_ascii=False) + "\n")


# ------------------------------------------------------------------ contrast (same maths as tools/contrast-ratio.sh)
def _lin(v):
    v /= 255
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def ratio(fg, bg):
    lum = lambda c: 0.2126 * _lin(c[0]) + 0.7152 * _lin(c[1]) + 0.0722 * _lin(c[2])
    a, b = sorted((lum(fg), lum(bg)), reverse=True)
    return (a + 0.05) / (b + 0.05)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


WHITE, BLACK = hexrgb("#FFFFFF"), hexrgb("#000000")


def colorset(light, dark=None):
    def entry(h, appearance=None):
        r, g, b = hexrgb(h)
        e = {}
        if appearance:
            e["appearances"] = [{"appearance": "luminosity", "value": appearance}]
        e["color"] = {"color-space": "srgb", "components": {
            "alpha": "1.000", "blue": f"{b / 255:.3f}", "green": f"{g / 255:.3f}", "red": f"{r / 255:.3f}"}}
        e["idiom"] = "universal"
        return e
    colors = [entry(light)] + ([entry(dark, "dark")] if dark else [])
    return {"colors": colors, "info": {"author": "xcode", "version": 1}}


ASSETS = "Puffin/Assets.xcassets"
# Ink: body text, passes both ways. Apricot: button fill with white label, fails. Moss: link text, one value for
# both appearances, so it passes on white and fails on black. Heather: a text accent that passes both ways; Plum: its fill.
INK = ("#1F2A37", "#E5E7EB")
APRICOT = "#F4A259"
MOSS = "#2F6B3A"
HEATHER = ("#5B3E8C", "#C9B6EC")
PLUM = "#5B3E8C"  # button fill, one value: white labels pass on it in both appearances
MIST = (0.62, 0.65, 0.69)  # Theme literal, used for small secondary text: fails on white
SLATE = (0.50, 0.50, 0.50)  # Theme literal, used only for a 28 pt title: passes the 3:1 large-text bar both ways

assert ratio(hexrgb(INK[0]), WHITE) >= 4.5 and ratio(hexrgb(INK[1]), BLACK) >= 4.5
assert ratio(WHITE, hexrgb(APRICOT)) < 3
assert ratio(hexrgb(MOSS), WHITE) >= 4.5 and ratio(hexrgb(MOSS), BLACK) < 4.5
assert ratio(hexrgb(HEATHER[0]), WHITE) >= 4.5 and ratio(hexrgb(HEATHER[1]), BLACK) >= 4.5
assert ratio(WHITE, hexrgb(PLUM)) >= 4.5
_m = tuple(round(c * 255) for c in MIST)
assert ratio(_m, WHITE) < 4.5 and ratio(_m, BLACK) >= 4.5
_s = tuple(round(c * 255) for c in SLATE)
assert 3 <= ratio(_s, WHITE) < 4.5 and ratio(_s, BLACK) >= 3


def assets():
    return {
        f"{ASSETS}/Contents.json": {"info": {"author": "xcode", "version": 1}},
        f"{ASSETS}/Ink.colorset/Contents.json": colorset(*INK),
        f"{ASSETS}/Apricot.colorset/Contents.json": colorset(APRICOT),
        f"{ASSETS}/Moss.colorset/Contents.json": colorset(MOSS),
        f"{ASSETS}/Heather.colorset/Contents.json": colorset(*HEATHER),
        f"{ASSETS}/Plum.colorset/Contents.json": colorset(PLUM),
    }


THEME = d(f"""
    import SwiftUI

    extension Color {{
        static let ink = Color("Ink")
        static let apricot = Color("Apricot")
        static let moss = Color("Moss")
        static let heather = Color("Heather")
        static let plum = Color("Plum")
        static let mist = Color(red: {MIST[0]}, green: {MIST[1]}, blue: {MIST[2]})
        static let slate = Color(red: {SLATE[0]}, green: {SLATE[1]}, blue: {SLATE[2]})
    }}
    """)

README = d("""
    # Puffin

    A reading tracker: the books you're reading, your shelf, and reading goals. iOS 17+, SwiftUI + SwiftData,
    local only. Colours live in `Theme.swift` and `Assets.xcassets`.
    """)

CLAUDE_MD = d("""
    # Puffin — project notes

    - Colours come from `Theme.swift` and the asset catalog; no literals in views.
    - Primary actions use a filled capsule button.
    - Build with XcodeBuildMCP on the iPhone 16 simulator.
    """)

BOOK = d("""
    import Foundation
    import SwiftData

    @Model
    final class Book {
        var title: String
        var author: String
        var pagesRead: Int
        var pageCount: Int
        var rating: Int = 0
        var dueBack: Date?
        var finished: Bool = false

        init(title: String, author: String, pagesRead: Int = 0, pageCount: Int) {
            self.title = title
            self.author = author
            self.pagesRead = pagesRead
            self.pageCount = pageCount
        }

        var progress: Double { pageCount == 0 ? 0 : Double(pagesRead) / Double(pageCount) }
        var isOverdue: Bool { (dueBack ?? .distantFuture) < .now }
    }
    """)


def app(tabs):
    items = "\n".join(
        f"                {view}()\n                    .tabItem {{ Label(\"{title}\", systemImage: \"{icon}\") }}"
        for view, title, icon in tabs)
    return d("""
        import SwiftUI
        import SwiftData

        @main
        struct PuffinApp: App {
            var body: some Scene {
                WindowGroup {
                    TabView {
        %s
                    }
                }
                .modelContainer(for: Book.self)
            }
        }
        """) % items


def base_repo(tabs):
    return {"README.md": README, "CLAUDE.md": CLAUDE_MD, "Puffin/PuffinApp.swift": app(tabs),
            "Puffin/Models/Book.swift": BOOK, "Puffin/Theme.swift": THEME} | assets()


def prompt_all():
    return "Do the accessibility pass on this app's screens and report your findings."


# ================================================================== 01 VoiceOver labels and elements
def case01():
    lst = d("""
        import SwiftUI
        import SwiftData

        struct ReadingListView: View {
            @Query private var books: [Book]
            @State private var showAdd = false
            @State private var scanning = false
            @State private var selected: Book?

            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            Image(decorative: "shelf-banner")
                                .resizable()
                                .scaledToFit()
                        }
                        ForEach(books) { book in
                            BookRow(book: book) { selected = book }
                        }
                    }
                    .navigationTitle("Reading")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                scanning = true
                            } label: {
                                Image("barcode-scan")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showAdd = true
                            } label: {
                                Label("Add Book", systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                    .sheet(item: $selected) { BookDetailView(book: $0) }
                    .sheet(isPresented: $showAdd) { Text("Add") }
                }
            }
        }
        """)
    row = d("""
        import SwiftUI

        struct BookRow: View {
            let book: Book
            let onOpen: () -> Void

            var body: some View {
                HStack(spacing: 12) {
                    ProgressRing(progress: book.progress)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.headline)
                            .foregroundStyle(Color.ink)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { onOpen() }
            }
        }
        """)
    ring = d("""
        import SwiftUI

        struct ProgressRing: View {
            let progress: Double

            var body: some View {
                ZStack {
                    Circle()
                        .stroke(Color.ink.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.heather, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        """)
    detail = d("""
        import SwiftUI

        struct BookDetailView: View {
            @Bindable var book: Book
            @Environment(\\.dismiss) private var dismiss

            var body: some View {
                NavigationStack {
                    Form {
                        Section("Rating") {
                            HStack {
                                ForEach(1...5, id: \\.self) { star in
                                    Image(systemName: star <= book.rating ? "star.fill" : "star")
                                        .foregroundStyle(Color.heather)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                        .onTapGesture { book.rating = star }
                                }
                            }
                        }
                        Section {
                            Button {
                                share()
                            } label: {
                                Label("Share Progress", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                book.pagesRead = 0
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Start Over")
                                }
                            }
                            Button(role: .destructive) {
                                dismiss()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel("Remove from Reading")
                        }
                    }
                    .navigationTitle(book.title)
                    .toolbar {
                        Button("Done") { dismiss() }
                    }
                }
            }

            private func share() {}
        }
        """)
    L, R, G, D = ("Puffin/Views/ReadingListView.swift", "Puffin/Views/BookRow.swift",
                  "Puffin/Views/ProgressRing.swift", "Puffin/Views/BookDetailView.swift")
    repo = base_repo([("ReadingListView", "Reading", "book")]) | {L: lst, R: row, G: ring, D: detail}
    write_case("01-voiceover", repo, {
        "description": "VoiceOver: an asset-image-only toolbar button with no label; a row opened by onTapGesture with no button trait; a progress ring with no spoken value; a star rating built from tap gestures (no value, no adjustable action). Decoys: an iconOnly Label (still spoken), a decorative image, Label and Image+Text buttons, an image-only button that has .accessibilityLabel, Button(\"Done\").",
        "prompt": prompt_all(),
        "exhaustive": False,
        "read_only": True,
        "must_find": [
            {"id": "scan-button-unlabelled", "locations": [loc(L, rng(lst, "scanning = true", 'Image("barcode-scan")', pad=2))],
             "categories": ["voiceover-label"], "expected_verdict": "CONFIRMED",
             "why": "Toolbar button whose label is only Image(\"barcode-scan\"): VoiceOver reads the asset name."},
            {"id": "row-tap-no-trait", "locations": [loc(R, rng(row, "HStack(spacing: 12)", ".onTapGesture { onOpen() }"))],
             "categories": ["voiceover-element"], "expected_verdict": "CONFIRMED",
             "why": "The row opens the book via onTapGesture on an HStack with no .isButton trait."},
            {"id": "ring-no-value", "locations": [loc(G, rng(ring, "ZStack {", ".rotationEffect")), loc(R, rng(row, "ProgressRing(progress:", ".frame(width: 44, height: 44)"))],
             "categories": ["voiceover-element"], "expected_verdict": "CONFIRMED",
             "why": "Custom progress ring with no accessibilityValue; VoiceOver users can't hear progress."},
            {"id": "rating-custom-control", "locations": [loc(D, rng(detail, "ForEach(1...5", ".onTapGesture { book.rating = star }", pad=1))],
             "categories": ["voiceover-element"], "expected_verdict": "CONFIRMED",
             "why": "Star rating from tap gestures on images: no button trait, no value, no adjustable action."},
        ],
        "must_not_flag": [
            {"id": "iconOnly-label", "file": L, "lines": rng(lst, 'Label("Add Book"', ".labelStyle(.iconOnly)"), "categories": ["voiceover-label"],
             "why": "Label with .iconOnly still speaks its title."},
            {"id": "decorative-banner", "file": L, "lines": rng(lst, 'Image(decorative: "shelf-banner")'), "categories": [],
             "why": "Image(decorative:) is hidden from VoiceOver."},
            {"id": "labelled-trash", "file": D, "lines": rng(detail, 'Image(systemName: "trash")', '.accessibilityLabel("Remove from Reading")'), "categories": ["voiceover-label"],
             "why": "Image-only button with an explicit accessibilityLabel."},
            {"id": "image-plus-text", "file": D, "lines": rng(detail, 'Image(systemName: "arrow.counterclockwise")', 'Text("Start Over")'), "categories": ["voiceover-label"],
             "why": "The Text is the label."},
            {"id": "share-label", "file": D, "lines": rng(detail, 'Label("Share Progress"'), "categories": ["voiceover-label"],
             "why": "Label speaks its title."},
        ],
        "forbidden_strings": [],
        "expected_overall": "NEEDS-WORK",
    })


# ================================================================== 02 Dynamic Type and hit targets
def case02():
    detail = d("""
        import SwiftUI

        struct BookNotesView: View {
            let book: Book
            @Environment(\\.dismiss) private var dismiss
            @ScaledMetric(relativeTo: .body) private var noteSize = 16

            var body: some View {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.heather)
                            .accessibilityHidden(true)
                        Text(book.title)
                            .font(.system(.title2, design: .serif))
                        Text("Notes and highlights you've saved while reading this book.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        Text("“A reader lives a thousand lives before he dies.”")
                            .font(.custom("Georgia", fixedSize: 18))
                        Text("Your notes")
                            .font(.custom("Georgia", size: 17))
                        Text("Tap a highlight to add a note.")
                            .font(.system(size: noteSize))
                    }
                    .padding()
                }
                .dynamicTypeSize(...DynamicTypeSize.large)
                .overlay(alignment: .topTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(.thinMaterial))
                    }
                    .accessibilityLabel("Close")
                    .padding(8)
                }
            }
        }
        """)
    shelf = d("""
        import SwiftUI
        import SwiftData

        struct ShelfView: View {
            @Query private var books: [Book]

            var body: some View {
                NavigationStack {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))]) {
                            ForEach(books) { book in
                                VStack(alignment: .leading) {
                                    NavigationLink {
                                        BookNotesView(book: book)
                                    } label: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.heather.opacity(0.2))
                                            .frame(height: 180)
                                    }
                                    .accessibilityLabel("Notes for \\(book.title)")
                                    HStack {
                                        Text(book.title)
                                            .font(.subheadline)
                                        Spacer()
                                        Button {
                                            book.finished.toggle()
                                        } label: {
                                            Image(systemName: book.finished ? "checkmark.circle.fill" : "circle")
                                                .frame(width: 36, height: 36)
                                        }
                                        .accessibilityLabel(book.finished ? "Mark unread" : "Mark finished")
                                        Button {
                                            book.rating = 0
                                        } label: {
                                            Image(systemName: "star.slash")
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .accessibilityLabel("Clear rating")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Shelf")
                }
            }
        }
        """)
    N, S = "Puffin/Views/BookNotesView.swift", "Puffin/Views/ShelfView.swift"
    repo = base_repo([("ShelfView", "Shelf", "books.vertical")]) | {N: detail, S: shelf}
    write_case("02-type-targets", repo, {
        "description": "Dynamic Type and targets: body text with .system(size: 15); a quote with .custom(fixedSize:); the screen capped with .dynamicTypeSize(...large); a 24×24 close button (P1); a 36×36 shelf toggle (P2). Decoys: .custom(size:) and .system(.title2, design:) scale; a @ScaledMetric size; a fixed-size decorative symbol; a 44×44 button with contentShape.",
        "prompt": prompt_all(),
        "exhaustive": False,
        "read_only": True,
        "must_find": [
            {"id": "fixed-system-size", "locations": [loc(N, rng(detail, ".font(.system(size: 15))"))], "categories": ["dynamic-type"],
             "expected_verdict": "CONFIRMED", "why": "Body text at .system(size: 15) doesn't scale."},
            {"id": "custom-fixed-size", "locations": [loc(N, rng(detail, 'fixedSize: 18'))], "categories": ["dynamic-type"],
             "expected_verdict": "CONFIRMED", "why": ".custom(_:fixedSize:) on reading text doesn't scale."},
            {"id": "type-size-cap", "locations": [loc(N, rng(detail, ".dynamicTypeSize(...DynamicTypeSize.large)"))], "categories": ["dynamic-type"],
             "expected_verdict": "CONFIRMED", "why": "The notes screen caps text at .large, below the accessibility sizes."},
            {"id": "close-24pt", "locations": [loc(N, rng(detail, 'Image(systemName: "xmark")', ".frame(width: 24, height: 24)", pad=3))],
             "categories": ["hit-target"], "expected_verdict": "CONFIRMED", "why": "The close button is 24×24 pt with no larger content shape (P1, under 30)."},
            {"id": "toggle-36pt", "locations": [loc(S, rng(shelf, "book.finished.toggle()", ".frame(width: 36, height: 36)", pad=2))],
             "categories": ["hit-target"], "expected_verdict": "CONFIRMED", "why": "The finished toggle is 36×36 pt (P2)."},
        ],
        "must_not_flag": [
            {"id": "custom-size-scales", "file": N, "lines": rng(detail, '.font(.custom("Georgia", size: 17))'), "categories": ["dynamic-type"],
             "why": ".custom(_:size:) scales relative to .body."},
            {"id": "title2-serif", "file": N, "lines": rng(detail, ".font(.system(.title2, design: .serif))"), "categories": ["dynamic-type"],
             "why": "A text style with a design scales."},
            {"id": "scaled-metric", "file": N, "lines": rng(detail, ".font(.system(size: noteSize))"), "categories": ["dynamic-type"],
             "why": "The size comes from @ScaledMetric."},
            {"id": "hero-symbol", "file": N, "lines": rng(detail, 'Image(systemName: "books.vertical")', ".accessibilityHidden(true)"), "categories": ["dynamic-type"],
             "why": "Fixed size on a decorative symbol, hidden from VoiceOver."},
            {"id": "clear-44", "file": S, "lines": rng(shelf, 'Image(systemName: "star.slash")', ".contentShape(Rectangle())"), "categories": ["hit-target"],
             "why": "44×44 with a content shape."},
        ],
        "forbidden_strings": [],
        "expected_overall": "NEEDS-WORK",
    })


# ================================================================== 03 contrast, colour alone, motion
def case03():
    now = d("""
        import SwiftUI
        import SwiftData

        struct NowReadingView: View {
            @Query private var books: [Book]
            @State private var pulse = false

            var body: some View {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("This week")
                                .font(.title)
                                .foregroundStyle(Color.slate)
                            HStack {
                                Circle()
                                    .fill(Color.heather)
                                    .frame(width: 10, height: 10)
                                    .scaleEffect(pulse ? 1.6 : 1)
                                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                                Text("Reading now")
                                    .font(.headline)
                                    .foregroundStyle(Color.ink)
                            }
                            .onAppear { pulse = true }
                            ForEach(books) { book in
                                HStack {
                                    Circle()
                                        .fill(book.isOverdue ? Color.red : Color.green)
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.body)
                                            .foregroundStyle(Color.ink)
                                        Text("\\(book.pagesRead) of \\(book.pageCount) pages")
                                            .font(.footnote)
                                            .foregroundStyle(Color.mist)
                                    }
                                    Spacer()
                                    if book.finished {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.green)
                                        Text("Finished")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Link("Find your local library", destination: URL(string: "https://example.org")!)
                                .font(.subheadline)
                                .foregroundStyle(Color.moss)
                            Button {
                                logSession()
                            } label: {
                                Text("Log Reading")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(Capsule().fill(Color.apricot))
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Now")
                }
            }

            private func logSession() {}
        }
        """)
    goal = d("""
        import SwiftUI

        struct GoalCelebration: View {
            @Environment(\\.accessibilityReduceMotion) private var reduceMotion
            @State private var spin = false
            @State private var shown = false

            var body: some View {
                VStack(spacing: 12) {
                    Image(systemName: "rosette")
                        .font(.largeTitle)
                        .foregroundStyle(Color.heather)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(reduceMotion ? nil : .linear(duration: 4).repeatForever(autoreverses: false), value: spin)
                        .accessibilityHidden(true)
                    Text("Goal reached")
                        .font(.title3.bold())
                        .foregroundStyle(Color.ink)
                    Button("Keep Going") {
                        withAnimation(.spring) { shown.toggle() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.plum)
                }
                .onAppear { spin = true }
            }
        }
        """)
    N, G = "Puffin/Views/NowReadingView.swift", "Puffin/Views/GoalCelebration.swift"
    repo = base_repo([("NowReadingView", "Now", "book"), ("GoalCelebration", "Goals", "flag")]) | {N: now, G: goal,
            "CLAUDE.md": CLAUDE_MD + "- The app supports light and dark appearance; check both.\n"}
    r = lambda a, b: round(ratio(a, b), 2)
    write_case("03-contrast-motion", repo, {
        "description": (
            f"Contrast and motion (CLAUDE.md states dark-mode support): Color.mist footnote on white {r(_m, WHITE)}:1; Moss link (no dark variant) on black {r(hexrgb(MOSS), BLACK)}:1 in dark mode; "
            f"white label on the Apricot fill {r(WHITE, hexrgb(APRICOT))}:1; an overdue/on-time dot shown only by colour; a repeatForever pulse with no Reduce Motion check. "
            f"Decoys: a 28 pt title in Color.slate ({r(_s, WHITE)}:1 white, {r(_s, BLACK)}:1 black, passes the large-text bar); Ink text both ways; a seal icon with a Finished label; "
            f"a repeating spin gated on accessibilityReduceMotion; a one-shot spring on tap; a Plum-tinted borderedProminent button."),
        "prompt": prompt_all(),
        "exhaustive": False,
        "read_only": True,
        "must_find": [
            {"id": "mist-footnote", "locations": [loc(N, rng(now, '.font(.footnote)', ".foregroundStyle(Color.mist)")), loc("Puffin/Theme.swift", rng(THEME, "static let mist"))],
             "categories": ["contrast"], "expected_verdict": "CONFIRMED", "why": f"Color.mist on white is {r(_m, WHITE)}:1, below 4.5:1 for footnote text."},
            {"id": "moss-dark", "locations": [loc(N, rng(now, 'Link("Find your local library"', ".foregroundStyle(Color.moss)")), loc("Puffin/Theme.swift", rng(THEME, "static let moss"))],
             "categories": ["contrast"], "expected_verdict": "CONFIRMED", "why": f"Moss has no dark value; on the dark background it is {r(hexrgb(MOSS), BLACK)}:1."},
            {"id": "apricot-button", "locations": [loc(N, rng(now, 'Text("Log Reading")', ".background(Capsule().fill(Color.apricot))"))],
             "categories": ["contrast"], "expected_verdict": "CONFIRMED", "why": f"White 17 pt Semibold on Apricot is {r(WHITE, hexrgb(APRICOT))}:1."},
            {"id": "overdue-dot", "locations": [loc(N, rng(now, ".fill(book.isOverdue ? Color.red : Color.green)", pad=1))],
             "categories": ["color-only"], "expected_verdict": "CONFIRMED", "why": "Overdue vs on time is shown only by the dot's colour."},
            {"id": "pulse-motion", "locations": [loc(N, rng(now, ".scaleEffect(pulse ? 1.6 : 1)", ".onAppear { pulse = true }"))],
             "categories": ["reduce-motion"], "expected_verdict": "CONFIRMED", "why": "repeatForever pulse with no accessibilityReduceMotion check."},
        ],
        "must_not_flag": [
            {"id": "slate-title-large", "file": N, "lines": rng(now, 'Text("This week")', ".foregroundStyle(Color.slate)"), "categories": ["contrast"],
             "why": "28 pt .title passes 3:1 in both appearances."},
            {"id": "ink-body", "file": N, "lines": [line_of(now, "Text(book.title)"), line_of(now, "Text(book.title)") + 2], "categories": ["contrast"],
             "why": "Ink passes in light and dark."},
            {"id": "finished-seal", "file": N, "lines": rng(now, 'Image(systemName: "checkmark.seal.fill")', 'Text("Finished")'), "categories": ["color-only"],
             "why": "The state has a text label."},
            {"id": "gated-spin", "file": G, "lines": rng(goal, ".rotationEffect(.degrees(spin ? 360 : 0))", ".animation(reduceMotion ? nil"), "categories": ["reduce-motion"],
             "why": "The repeating spin is removed under Reduce Motion."},
            {"id": "spring-on-tap", "file": G, "lines": rng(goal, "withAnimation(.spring)"), "categories": ["reduce-motion"],
             "why": "One-shot animation in response to a tap."},
        ],
        "forbidden_strings": [],
        "expected_overall": "NEEDS-WORK",
    })


# ================================================================== 04 clean
def case04():
    lst = d("""
        import SwiftUI
        import SwiftData

        struct LibraryView: View {
            @Query private var books: [Book]
            @Environment(\\.accessibilityReduceMotion) private var reduceMotion
            @State private var glow = false
            @State private var showAdd = false

            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            Image(decorative: "library-header")
                                .resizable()
                                .scaledToFit()
                        }
                        ForEach(books) { book in
                            NavigationLink(value: book.title) {
                                HStack(spacing: 12) {
                                    ProgressDial(progress: book.progress)
                                        .frame(width: 44, height: 44)
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.custom("Georgia", size: 17))
                                            .foregroundStyle(Color.ink)
                                        Text("\\(book.pagesRead) of \\(book.pageCount) pages")
                                            .font(.footnote)
                                            .foregroundStyle(Color.heather)
                                    }
                                    if book.isOverdue {
                                        Label("Overdue", systemImage: "exclamationmark.circle")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .navigationTitle("Library")
                    .toolbar {
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add Book", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            Circle()
                                .fill(Color.heather)
                                .frame(width: 8, height: 8)
                                .opacity(glow ? 0.4 : 1)
                                .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(), value: glow)
                                .accessibilityHidden(true)
                            Text("Syncing your shelf")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .onAppear { glow = true }
                    }
                }
            }
        }
        """)
    dial = d("""
        import SwiftUI

        struct ProgressDial: View {
            let progress: Double

            var body: some View {
                ZStack {
                    Circle()
                        .stroke(Color.ink.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.heather, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .accessibilityElement()
                .accessibilityLabel("Progress")
                .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
            }
        }
        """)
    detail = d("""
        import SwiftUI

        struct LibraryBookView: View {
            @Bindable var book: Book
            @Environment(\\.dismiss) private var dismiss
            @ScaledMetric(relativeTo: .title) private var heroSize = 56

            var body: some View {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: heroSize))
                            .foregroundStyle(Color.heather)
                            .accessibilityHidden(true)
                        Text(book.title)
                            .font(.system(.title2, design: .serif))
                            .foregroundStyle(Color.ink)
                        Stepper("Pages read: \\(book.pagesRead)", value: $book.pagesRead, in: 0...book.pageCount)
                        Button {
                            dismiss()
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Capsule().fill(Color.plum))
                        }
                    }
                    .padding()
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.thinMaterial))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        """)
    L, P, B = "Puffin/Views/LibraryView.swift", "Puffin/Views/ProgressDial.swift", "Puffin/Views/LibraryBookView.swift"
    assert ratio(hexrgb(HEATHER[0]), WHITE) >= 4.5 and ratio(hexrgb(HEATHER[1]), hexrgb("#1C1C1E")) >= 4.5
    repo = base_repo([("LibraryView", "Library", "books.vertical")]) | {L: lst, P: dial, B: detail}
    write_case("04-clean", repo, {
        "description": "Clean: every rule followed, including the tricky-but-correct shapes (iconOnly Label, decorative image, a combined row, a dial with label and value, .custom(size:), @ScaledMetric hero, a 30 pt glyph inside a 44 pt content shape, Heather text and a Plum fill passing in both appearances, a status shown by label + icon, a repeating glow gated on Reduce Motion). Exhaustive; PASS.",
        "prompt": prompt_all(),
        "exhaustive": True,
        "read_only": True,
        "must_find": [],
        "must_not_flag": [],
        "forbidden_strings": [],
        "expected_overall": "PASS",
    })


# ================================================================== 05 scoped to one new screen
def case05():
    goals = d("""
        import SwiftUI

        struct GoalsView: View {
            @AppStorage("yearlyGoal") private var yearlyGoal = 24
            @State private var editing = false

            var body: some View {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\\(yearlyGoal) books this year")
                            .font(.title2.bold())
                            .foregroundStyle(Color.ink)
                        Text("Pick a number you can keep. You can change it at any time.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Goals")
                    .toolbar {
                        Button {
                            editing = true
                        } label: {
                            Image("goal-edit")
                        }
                    }
                }
            }
        }
        """)
    settings = d("""
        import SwiftUI

        struct SettingsView: View {
            @AppStorage("reminders") private var reminders = true

            var body: some View {
                NavigationStack {
                    Form {
                        Toggle("Daily reminder", isOn: $reminders)
                        Text("Puffin keeps everything on this iPhone.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mist)
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        Button {
                        } label: {
                            Image("help-bubble")
                        }
                    }
                }
            }
        }
        """)
    G, S = "Puffin/Views/GoalsView.swift", "Puffin/Views/SettingsView.swift"
    repo = base_repo([("GoalsView", "Goals", "flag"), ("SettingsView", "Settings", "gear")]) | {G: goals, S: settings}
    write_case("05-scoped", repo, {
        "description": "Scope: the prompt names only the new Goals screen. Goals has a fixed .system(size: 14) explanation and an asset-only edit button. Settings has its own defects (fixed size, Mist on a white row, an unlabelled help button) and must not be reported.",
        "prompt": "I've just built the new Goals screen (GoalsView). Check it for accessibility problems before I move on.",
        "exhaustive": False,
        "read_only": True,
        "must_find": [
            {"id": "goals-fixed-size", "locations": [loc(G, rng(goals, ".font(.system(size: 14))"))], "categories": ["dynamic-type"],
             "expected_verdict": "CONFIRMED", "why": "Explanation text at a fixed 14 pt."},
            {"id": "goals-edit-unlabelled", "locations": [loc(G, rng(goals, "editing = true", 'Image("goal-edit")', pad=2))], "categories": ["voiceover-label"],
             "expected_verdict": "CONFIRMED", "why": "Toolbar button whose label is only an asset image."},
        ],
        "must_not_flag": [
            {"id": "settings-out-of-scope", "file": S, "lines": None, "categories": [],
             "why": "Settings isn't the screen under review."},
            {"id": "theme-mist-out-of-scope", "file": "Puffin/Theme.swift", "lines": rng(THEME, "static let mist"), "categories": [],
             "why": "Mist is only used on the out-of-scope Settings screen."},
        ],
        "forbidden_strings": [],
        "expected_overall": "NEEDS-WORK",
    })


# ================================================================== 06 P2 only: PASS with findings
def case06():
    stats = d("""
        import SwiftUI
        import SwiftData

        struct StatsView: View {
            @Query private var books: [Book]
            @State private var showInfo = false

            var body: some View {
                NavigationStack {
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\\(books.filter(\\.finished).count)")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.ink)
                            Text("books finished")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        Link("How stats are counted", destination: URL(string: "https://example.org/stats")!)
                            .font(.subheadline)
                            .foregroundStyle(Color.moss)
                        List {
                            Section {
                                HStack {
                                    Text("Pages this month")
                                    Spacer()
                                    Button {
                                        showInfo = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .frame(width: 34, height: 34)
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("About this number")
                                }
                            }
                        }
                    }
                    .navigationTitle("Stats")
                }
            }
        }
        """)
    S = "Puffin/Views/StatsView.swift"
    repo = base_repo([("StatsView", "Stats", "chart.bar")]) | {S: stats}
    write_case("06-p2-only", repo, {
        "description": "Only P2 problems, light appearance only (no dark-mode support stated): a 34×34 info button (P2 band 30–43) and a count and its unit read as two elements. Overall must be PASS (NEEDS-WORK only on P1).",
        "prompt": prompt_all(),
        "exhaustive": False,
        "read_only": True,
        "must_find": [
            {"id": "info-34pt", "locations": [loc(S, rng(stats, "showInfo = true", ".frame(width: 34, height: 34)", pad=2))], "categories": ["hit-target"],
             "expected_verdict": "CONFIRMED", "why": "34×34 pt info button (P2)."},
            {"id": "count-unit-split", "locations": [loc(S, rng(stats, "HStack(alignment: .firstTextBaseline)", 'Text("books finished")'))], "categories": ["voiceover-element"],
             "why": "The count and 'books finished' are separate elements (P2)."},
        ],
        "must_not_flag": [
            {"id": "list-row-text", "file": S, "lines": rng(stats, 'Text("Pages this month")'), "categories": [],
             "why": "Plain list row text."},
            {"id": "moss-dark-unsupported", "file": S, "lines": rng(stats, 'Link("How stats are counted"', ".foregroundStyle(Color.moss)"), "categories": ["contrast"],
             "why": f"Moss passes on white ({round(ratio(hexrgb(MOSS), WHITE), 2)}:1) and fails only on black; the project doesn't state dark-mode support, so dark isn't checked."},
        ],
        "forbidden_strings": [],
        "expected_overall": "PASS",
    })


if __name__ == "__main__":
    for c in (case01, case02, case03, case04, case05, case06):
        c()
    print("wrote", sorted(p.name for p in (ROOT / "cases").iterdir()))
