import AppKit
import CoreText
// symmatch <font> name...   → prints name<TAB>codepoint<TAB>score
let a = CommandLine.arguments
let url = URL(fileURLWithPath: a[1]) as CFURL
let d = (CTFontManagerCreateFontDescriptorsFromURL(url) as! [CTFontDescriptor]).first!
let base = CTFontCreateWithFontDescriptor(d, 100, nil)
let axes = CTFontCopyVariationAxes(base) as! [[String: Any]]
let wid = axes[0][kCTFontVariationAxisIdentifierKey as String] as! NSNumber
let font = CTFontCreateCopyWithAttributes(base, 100, nil, CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: [wid: 400]] as CFDictionary))
let N = 40
func raster(_ draw: (CGContext, CGRect) -> Void, bbox: CGRect) -> [Float] {
  let cs = CGColorSpaceCreateDeviceGray(); let ctx = CGContext(data: nil, width: N, height: N, bitsPerComponent: 8, bytesPerRow: N, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
  ctx.setFillColor(gray: 0, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: N, height: N))
  let s = CGFloat(N - 2) / max(bbox.width, bbox.height); ctx.translateBy(x: 1 + (CGFloat(N - 2) - bbox.width * s) / 2, y: 1 + (CGFloat(N - 2) - bbox.height * s) / 2); ctx.scaleBy(x: s, y: s); ctx.translateBy(x: -bbox.minX, y: -bbox.minY)
  draw(ctx, bbox)
  let p = ctx.data!.bindMemory(to: UInt8.self, capacity: N * N); return (0..<N*N).map { Float(p[$0]) / 255 }
}
// candidate glyphs: every PUA code point the font maps
var cands: [(Int, CGPath, [Float], CGFloat)] = []
for cp in 0x100000...0x10FFFD {
  var u = Array(String(UnicodeScalar(cp)!).utf16); var g = [CGGlyph](repeating: 0, count: 2)
  guard CTFontGetGlyphsForCharacters(font, &u, &g, u.count), g[0] != 0, let path = CTFontCreatePathForGlyph(font, g[0], nil) else { continue }
  let bb = path.boundingBoxOfPath; guard bb.width > 1, bb.height > 1 else { continue }
  let r = raster({ c, _ in c.setFillColor(gray: 1, alpha: 1); c.addPath(path); c.fillPath() }, bbox: bb)
  cands.append((cp, path, r, bb.width / bb.height))
}
FileHandle.standardError.write("candidates: \(cands.count)\n".data(using: .utf8)!)
for name in a.dropFirst(2) {
  guard let img0 = NSImage(systemSymbolName: name, accessibilityDescription: nil), let img = img0.withSymbolConfiguration(.init(pointSize: 100, weight: .regular)) else { print("\(name)\tNOTFOUND\t0"); continue }
  var rect = CGRect(origin: .zero, size: img.size); guard let cg = img.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { continue }
  // bbox of ink
  let w = cg.width, h = cg.height; let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)); let px = ctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)
  var minX = w, minY = h, maxX = 0, maxY = 0
  for y in 0..<h { for x in 0..<w where px[(y * w + x) * 4 + 3] > 40 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) } }
  let bb = CGRect(x: minX, y: h - 1 - maxY, width: maxX - minX + 1, height: maxY - minY + 1)
  let mask = cg
  let r = raster({ c, _ in c.clip(to: CGRect(x: 0, y: 0, width: w, height: h), mask: mask); c.setFillColor(gray: 1, alpha: 1); c.fill(CGRect(x: 0, y: 0, width: w, height: h)) }, bbox: bb)
  let aspect = bb.width / bb.height
  var best = (0, Float.infinity)
  for c in cands where abs(c.3 - aspect) < 0.12 { var s: Float = 0; for k in 0..<(N*N) { s += abs(c.2[k] - r[k]) }; if s < best.1 { best = (c.0, s) } }
  print("\(name)\t\(String(format: "%X", best.0))\t\(Int(best.1))")
}
