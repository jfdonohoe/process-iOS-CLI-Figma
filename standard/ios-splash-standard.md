# iOS splash screen standard

**Applies to:** every iOS app John vibe codes where a splash/launch image is supplied.
**Established:** 2026-09-08, from the WorkoutApp ("Sets") build.
**Status:** default approach — follow it unless John says otherwise for a specific app.

---

## The rule

**The launch storyboard is a solid brand colour with no image. The artwork is drawn by the app.**

Never put the splash artwork in the launch storyboard or in `UILaunchScreen`'s `UIImageName`.

### Why (this is not a preference — it cost an afternoon)

iOS caches the *rendered* launch screen per app, on the device. Once a stale render is cached, updated artwork silently never appears. On a real iPhone 14 Pro Max, every one of these failed to clear it:

- `xcrun devicectl device uninstall app`
- deleting the app from the Home screen
- restarting the device
- bumping `CFBundleVersion`
- renaming the launch storyboard
- renaming the image asset in the catalog

Meanwhile the simulator rendered the new artwork correctly every time. That combination — simulator right, device wrong, bundle verifiably correct — reads exactly like a build failure and will burn hours. A launch screen containing nothing but a colour has nothing that can go stale, and an in-app view uses ordinary image loading, which is not subject to that cache.

---

## Implementation

Four pieces. Copy them.

### 1. `LaunchBackdrop.storyboard` — solid colour, no subviews

A launch storyboard whose root view has only a `backgroundColor`. No image view, no labels, no constraints. Name it something other than `LaunchScreen` so it is obvious it is not the branding.

Set `INFOPLIST_KEY_UILaunchStoryboardName = LaunchBackdrop` in all build configurations (and in `project.yml` if XcodeGen is used as a fallback — keep them in step).

### 2. `Theme.launchBackground`

```swift
/// Launch brand colour. MUST match LaunchBackdrop.storyboard's background,
/// or the hand-off from launch screen to SplashView flashes.
static let launchBackground = Color(red: 0x6E/255, green: 0x7A/255, blue: 0x3F/255)
```

The storyboard stores colour as 0–1 components; the code stores hex. They drift silently. Comment both sides pointing at each other, and set the colour from the artwork's own corner pixel so they cannot disagree with the art.

### 3. `Views/SplashView.swift`

```swift
struct SplashView: View {
    var body: some View {
        Theme.launchBackground
            .overlay(
                Image("LaunchImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .clipped()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

enum SplashTiming {
    static let hold: Duration = .milliseconds(900)
    static let fade: TimeInterval = 0.35
}
```

**Two layout traps, both hit in the real build:**

- `.aspectRatio(contentMode: .fill)` without a clipping parent overflows and drags the artwork **off-centre** (observed: logo centred at 61.9% instead of 50%). The `Color` + `.overlay` + `.clipped()` form is what works.
- "Fixing" that with a `GeometryReader` + explicit `.frame(width:height:)` starved the frame and the image vanished entirely. Do not reach for `GeometryReader` here.

### 4. Wire into the App

```swift
@State private var showSplash = true

ZStack {
    RootView()…
    if showSplash { SplashView().transition(.opacity) }
}
.task {
    try? await Task.sleep(for: SplashTiming.hold)
    withAnimation(.easeOut(duration: SplashTiming.fade)) { showSplash = false }
}
```

The app is fully built underneath while the splash is up, so the hold costs only the hold.

---

## Composition rules for the supplied artwork

### Canvas

- **Square, 2208 × 2208 px.** Square survives every device aspect with `.fill` and needs no per-device variants.
- **Flatten to RGB** (no alpha channel) before installing into the asset catalog.
- Asset catalog: one `LaunchImage.imageset`. A 3x-only slot works; a single-scale universal entry also works.
- The background colour must extend to all four edges — the crop removes the sides.

### The safe zone — the one rule that actually matters

`.fill` scales by height, so the **sides get cropped**. Visible horizontal window by device:

| device | aspect (w/h) | visible x window |
|---|---|---|
| iPhone SE | 0.562 | 21.9% – 78.1% |
| iPhone 15 | 0.461 | 26.9% – 73.1% |
| 16 Pro / 17 Pro Max | 0.460 | **27.0% – 73.0%** |

**Keep all content within x 30% – 70% of canvas width.** That is the 27–73% worst case plus a 3% margin each side. Anything wider gets clipped on tall phones.

Vertical is never cropped with `.fill` on a portrait device, so vertical placement maps 1:1 from canvas to screen.

### Reference layout (measured from the approved "Sets" artwork)

Percentages of the 2208 px canvas.

| element | top | bottom | height | left | right | width |
|---|---|---|---|---|---|---|
| logo mark | 17.7% | 30.7% | 13.0% | 43.5% | 56.5% | 13.0% |
| wordmark | 39.8% | 49.0% | 9.2% | 37.6% | 62.5% | 24.9% |
| tagline | 56.1% | 57.2% | 1.1% | 38.1% | 61.7% | 23.6% |
| divider rule | 74.9% | 75.1% | 0.2% | 43.1% | 56.9% | 13.8% |
| attribution | 80.3% | 81.7% | 1.4% | 42.7% | 57.3% | 14.6% |

Content spans 17.7% – 81.7% vertically. Widest element 24.9% — comfortably inside the 30–70% safe zone.

### Positions

- **Logo mark** — top edge ~18%, height ~13% of canvas, horizontally centred.
- **Wordmark** — occupies 40–49%, i.e. straddling the optical centre and sitting slightly above true centre. Do not centre on 50% exactly; it reads low.
- **Tagline** — ~7% below the wordmark's baseline.
- **Divider + attribution** — bottom third, 75% and 80%. Leaves ~18% of empty ground below, which is correct; do not fill it.
- Everything is **centred on x = 50%**. No asymmetric layouts — the crop is symmetric, so off-centre content loses its margin on one side first.

### Type sizes

Expressed as cap height in % of canvas width, so they scale with any canvas.

| role | cap height | tracking | case |
|---|---|---|---|
| wordmark | 9.2% | normal | title |
| tagline | 1.1% | ~0.25em | UPPERCASE |
| attribution | 1.4% | ~0.4em | UPPERCASE |

**Minimum legible size: 1.0% of canvas width.** Below that the glyphs mush after the downscale to screen. On a 2208 canvas that is ~22 px cap height.

Do not use italics for the wordmark unless deliberate — the earlier "Sets" artwork was italic and it was the single visual cue that distinguished stale from fresh during debugging. Upright reads better at splash scale.

### Contrast

Splash text over the brand colour must clear **4.5:1**. The Sets palette (`#F2EEE4` on `#6E7A3F`) is ~5.6:1.

---

## Verification — always do this, never eyeball it

Two artworks that differ only slightly are indistinguishable by eye, and a description like "still the old one" is not actionable. Measure.

1. **Freeze the launch screen** so it can actually be seen:
   - device: `xcrun devicectl device process launch --device "<name>" --start-stopped --terminate-existing <bundle-id>`
   - simulator: `xcrun simctl launch --wait-for-debugger <udid> <bundle-id>`
   For an in-app splash, temporarily raise `SplashTiming.hold` instead, and mark it `// TEMPORARY`.

2. **Measure content blocks** in a screenshot — threshold against the background colour, group rows into blocks, and report each block's x extent as a % of width. Compare against the source artwork mapped through the `.fill` transform. Agreement to <1% means it is the right artwork; anything else is not.

3. **Verify the bundle, not the build products.** Build products on the Mac tell you nothing about what is on the phone. Have the app report its own bundle:

```swift
NSLog("[DIAG] %@", Bundle.main.bundlePath)
if let img = UIImage(named: "LaunchImage") {
    NSLog("[DIAG] px=%.0fx%.0f", img.size.width * img.scale, img.size.height * img.scale)
}
```

Read it with `xcrun devicectl device process launch --console`. When two artworks share pixel dimensions, fingerprint `Assets.car` (FNV over its bytes) instead — size alone will not distinguish them.

Remove the diagnostic when done.

---

## Checklist

- [ ] Launch storyboard contains a colour and nothing else
- [ ] `INFOPLIST_KEY_UILaunchStoryboardName` points at it, in every configuration and in `project.yml`
- [ ] Storyboard colour == `Theme.launchBackground` == artwork corner pixel
- [ ] Artwork square, RGB, no alpha
- [ ] All content within x 30–70% of canvas
- [ ] Nothing smaller than 1.0% cap height
- [ ] `SplashView` uses `Color` + `.overlay` + `.clipped()` — no `GeometryReader`
- [ ] `SplashTiming.hold` back to production value after any review
- [ ] Verified by measurement on the simulator, not by eye
