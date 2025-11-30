import Foundation
import SwiftUI

struct CustomLink: View {
  var title: String
  var link: String
  
  @State private var hovering = false
  
  var body: some View {
    Link(
      destination: URL(string: link)!,
      label: {
        Text(title)
          .lineLimit(1)
          .truncationMode(.middle)
          .underline(hovering, color: .secondary)
      },
    )
    .onHover(perform: { inside in
      hovering = inside
      
      if inside {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    })
  }
}
