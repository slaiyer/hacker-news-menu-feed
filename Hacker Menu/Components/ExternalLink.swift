import SwiftUI

struct ExternalLink: View {
    let title: String
    let link: URL
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHoverRow = false

    var body: some View {
        HStack {
            Button(
                action: { NSWorkspace.shared.open(link, configuration: openConfig) },
                label: {
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            )
            .buttonStyle(.borderless)
            .focusable(false)
            .onHover { isHovering in
                DispatchQueue.main.async {
                    if (isHovering) {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }

            Spacer()
        }
        .onHover { inside in isHoverRow = inside }
        .opacity(isHoverRow ? 1.0 : 0.75)
        .shadow(color: .accent, radius: isHoverRow ? 5 : 0)
        .animation(.default, value: isHoverRow)
    }
}
