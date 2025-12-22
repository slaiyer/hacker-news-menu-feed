import SwiftUI

struct ExternalLink: View {
    let title: String
    let link: URL
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHovering = false

    var body: some View {
        Button(
            action: { NSWorkspace.shared.open(link, configuration: openConfig) },
            label: {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .opacity(isHovering ? 1.0 : 0.8)
            }
        )
        .buttonStyle(.borderless)
        .onHover{ inside in isHovering = inside }
        .animation(.default, value: isHovering)
        .focusable(false)
    }
}
