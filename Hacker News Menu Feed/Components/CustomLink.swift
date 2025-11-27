import Foundation
import SwiftUI

struct CustomLink: View {
  var title: String
  var link: String
  
  var body: some View {
    Link(
      destination: URL(string: link)!,
      label: {
        Text(title)
          .lineLimit(1)
          .truncationMode(.middle)
      },
    )
    .onHover(perform: { hovering in
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    })
  }
}
