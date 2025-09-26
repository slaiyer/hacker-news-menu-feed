import Foundation
import SwiftUI

struct CustomLink: View {
  var title: String
  var link: String

  var body: some View {
    Link(
      destination: URL(string: link)!,
      label: {
        HStack {
          Text(title)
            .lineLimit(1)
            .truncationMode(.middle)

          Spacer()
        }
      }
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
