import Foundation
import SwiftUI

struct CustomLink: View {
  var title: String
  var link: String
  
  @State private var isHovering = false

  var body: some View {
    Link(
      destination: URL(string: link)!,
      label: {
        Text(title)
          .lineLimit(1)
          .truncationMode(.middle)
          .shadow(color: .accent.opacity(0.75), radius: isHovering ? 0 : 1)
          .shadow(color: .accent.opacity(0.5), radius: isHovering ? 0 : 2)
      },
    )
    .onHover{ inside in isHovering = inside }
    .animation(.snappy, value: isHovering)
  }
}
