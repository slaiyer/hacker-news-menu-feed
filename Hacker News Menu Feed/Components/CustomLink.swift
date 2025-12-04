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
          .opacity(isHovering ? 1.0 : 0.8)
          .shadow(color: .accent, radius: isHovering ? 1 : 0)
      },
    )
    .onHover{ inside in isHovering = inside }
    .animation(.snappy, value: isHovering)
  }
}
