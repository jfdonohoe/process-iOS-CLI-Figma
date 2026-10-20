import SwiftUI

struct SettingsView: View {
    @State private var showingAbout = false

    var body: some View {
        Form {
            AboutButton(isPresented: $showingAbout)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct AboutButton: View {
    @Binding var isPresented: Bool
    var body: some View {
        Button("About Sets") { isPresented = true }
    }
}

struct AboutView: View {
    var body: some View { Text("Sets 1.0") }
}
