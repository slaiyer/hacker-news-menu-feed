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
          .underline(isHovering, color: .secondary)
      },
    )
    .onHover{ inside in isHovering = inside }
    .animation(.snappy, value: isHovering)
  }
}
