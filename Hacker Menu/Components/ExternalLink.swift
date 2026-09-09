import SwiftUI

struct ExternalLink: View {
    let title: String
    let link: URL
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHover: Bool = false

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
            .onHover { hovering in isHover = hovering}
            .shadow(color: .accent, radius: isHover ? 5 : 0)
            .animation(.default, value: isHover)

            Spacer()
        }
    }
}
