import SwiftUI

/// Figma: Primary Button. `fill: false` is Width = Hug, `fill: true` is Width = Fill.
struct PrimaryButton: View {
    let title: String
    let fill: Bool
    let action: () -> Void

    init(_ title: String, fill: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.fill = fill
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: fill ? .infinity : nil)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.leaf, in: Capsule())
        }
    }
}
