import Foundation
import CoreText
// cpexport <font> <outdir> <weight> HEX=outname ...
let a = CommandLine.arguments
let url = URL(fileURLWithPath: a[1]) as CFURL; let outDir = a[2]; let weight = Double(a[3])!
let d = (CTFontManagerCreateFontDescriptorsFromURL(url) as! [CTFontDescriptor]).first!
let base = CTFontCreateWithFontDescriptor(d, 17, nil)
let wid = (CTFontCopyVariationAxes(base) as! [[String: Any]])[0][kCTFontVariationAxisIdentifierKey as String] as! NSNumber
let font = CTFontCreateCopyWithAttributes(base, 17, nil, CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: [wid: weight]] as CFDictionary))
func f(_ v: CGFloat) -> String { String(format: "%.3f", v) }
for arg in a.dropFirst(4) {
  let p = arg.split(separator: "=").map(String.init); let cp = Int(p[0], radix: 16)!
  var u = Array(String(UnicodeScalar(cp)!).utf16); var g = [CGGlyph](repeating: 0, count: 2)
  guard CTFontGetGlyphsForCharacters(font, &u, &g, u.count), let path = CTFontCreatePathForGlyph(font, g[0], nil) else { print("\(p[1]) missing"); continue }
  let bb = path.boundingBoxOfPath; var s = ""
  path.applyWithBlock { el in let e = el.pointee; let q = e.points
    switch e.type { case .moveToPoint: s += "M\(f(q[0].x)) \(f(-q[0].y)) "; case .addLineToPoint: s += "L\(f(q[0].x)) \(f(-q[0].y)) "
    case .addQuadCurveToPoint: s += "Q\(f(q[0].x)) \(f(-q[0].y)) \(f(q[1].x)) \(f(-q[1].y)) "
    case .addCurveToPoint: s += "C\(f(q[0].x)) \(f(-q[0].y)) \(f(q[1].x)) \(f(-q[1].y)) \(f(q[2].x)) \(f(-q[2].y)) "
    case .closeSubpath: s += "Z "; @unknown default: break } }
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(f(bb.width))\" height=\"\(f(bb.height))\" viewBox=\"\(f(bb.minX)) \(f(-bb.maxY)) \(f(bb.width)) \(f(bb.height))\"><path fill=\"#000000\" d=\"\(s)\"/></svg>"
  try! svg.write(toFile: "\(outDir)/\(p[1]).svg", atomically: true, encoding: .utf8); print("\(p[1]): \(f(bb.width))x\(f(bb.height))")
}
