import SwiftUI

struct CustomLink: View {
    let title: String
    let link: URL

    @State private var isHovering = false

    var body: some View {
        Link(
            destination: link,
            label: {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .opacity(isHovering ? 1.0 : 0.8)
                    .shadow(color: .accent, radius: isHovering ? 1 : 0)
            },
        )
        .onHover{ inside in isHovering = inside }
        .animation(.default, value: isHovering)
        .focusable(false)
    }
}
