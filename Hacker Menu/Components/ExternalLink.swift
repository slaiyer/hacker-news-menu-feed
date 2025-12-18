import SwiftUI

struct ExternalLink: View {
    let title: String
    let link: URL

    @State private var isHovering = false

    var body: some View {
        Button { NSWorkspace.shared.open(link) }
        label: {
            Text(title)
                .lineLimit(1)
                .truncationMode(.middle)
                .opacity(isHovering ? 1.0 : 0.8)
                .shadow(color: .accent, radius: isHovering ? 0.5 : 0)
        }
        .buttonStyle(.borderless)
        .onHover{ inside in isHovering = inside }
        .animation(.default, value: isHovering)
        .focusable(false)
    }
}
