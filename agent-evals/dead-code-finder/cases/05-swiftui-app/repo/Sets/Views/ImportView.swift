import SwiftUI

struct ImportView: View {
    let url: URL
    var body: some View {
        Text("Import \(url.lastPathComponent)")
    }
}
