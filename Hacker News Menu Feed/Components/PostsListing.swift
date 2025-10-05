import Foundation
import SwiftUI
import AppKit

@available(macOS 26.0, *)
struct PostsListing: View {
  var posts: [StoryFetchResponse]

  var body: some View {
    ForEach(
      Array(posts.enumerated()),
      id: \.element.id
    ) { _, post in
      Divider()

      HStack(alignment: .center) {
        Button {
          if let raw = post.url, let extURL = URL(string: raw) {
            NSWorkspace.shared.open(extURL)
          }
          let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!
          NSWorkspace.shared.open(hnURL)
        } label: {
          Text("􀉣")
            .font(.subheadline)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .foregroundStyle(.orange)
        .onHover { hovering in
          if hovering {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }
        .focusEffectDisabled()

        VStack(alignment: .leading) {
          let title = post.title ?? "􀉣"

          HStack { // unreliable workaround for leading space
            if let url = post.url {
              CustomLink(title: title, link: url)
                .foregroundStyle(.primary)
                .help("\(title)\n\n\(url)")
            } else {
              Text(title)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.primary)
                .help(title)
            }

            Spacer()
          }

          Link(destination: URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!) {
            HStack {
              Text("􀆇 \(abbreviatedNumberString(number: post.score))")
                .frame(minWidth: 50, alignment: .leading)

              Text("􀌲 \(abbreviatedNumberString(number: post.comments))")
                .frame(minWidth: 50, alignment: .leading)
            }
            .font(.subheadline)
            .foregroundStyle(Color(.secondaryLabelColor))
          }
          .onHover { hovering in
            if hovering {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }
        }
      }
    }
  }
}

func abbreviatedNumberString(number: Int?) -> String {
  guard let number = number else {
    return "—"
  }

  switch number {
    case 0...999:
      return String(number)
    case 1_000..<1_000_000:
      let value = Double(number) / 1_000
      return String(format: "%.1fK", value)
    case 1_000_000..<1_000_000_000:
      let value = Double(number) / 1_000_000
      return String(format: "%.1fM", value)
    case 1_000_000_000..<1_000_000_000_000:
      let value = Double(number) / 1_000_000_000
      return String(format: "%.1fB", value)
    case 1_000_000_000_000..<1_000_000_000_000_000:
      let value = Double(number) / 1_000_000_000_000
      return String(format: "%.1fT", value)
    default:
      return "!"
  }
}
