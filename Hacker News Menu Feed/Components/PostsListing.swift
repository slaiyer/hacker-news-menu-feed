import Foundation
import SwiftUI
import AppKit

@available(macOS 26.0, *)
struct PostsListing: View {
  var posts: [StoryFetchResponse]

  private let now = Date()
  private let relativeTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
  }()

  var body: some View {
    ForEach(
      Array(posts.enumerated()),
      id: \.element.id
    ) { _, post in
      let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))

      HStack(alignment: .center) {
        let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!

        Button {
          NSWorkspace.shared.open(hnURL)

          if let raw = post.url, let extURL = URL(string: raw) {
            NSWorkspace.shared.open(extURL)
          }
        } label: {
          Text("􀉣")
            .font(.subheadline)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .foregroundStyle(.orange)
        .contentShape(.circle)
        .clipShape(.circle)
        .clipped(antialiased: true)
        .onHover { hovering in
          if hovering {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }

        VStack(alignment: .leading) {
          let title = post.title ?? "􀉣"

          HStack { // unreliable workaround for leading space
            if let extURL = post.url {
              CustomLink(title: title, link: extURL)
                .foregroundStyle(.primary)
                .help("\(title)\n⸻\n\(extURL)")
            } else {
              Text(title)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.primary)
                .help(title)
            }

            Spacer()
          }

          Link(destination: hnURL) {
            HStack {
              Text("􀆇 \(abbreviatedNumberString(number: post.score))")
                .frame(minWidth: 50, alignment: .leading)

              Text("􀌲 \(abbreviatedNumberString(number: post.comments))")
                .frame(minWidth: 50, alignment: .leading)

              if (post.type != "story") {
                Text("􀈕 \(post.type.uppercased())")
                  .frame(minWidth: 50, alignment: .leading)
              }

              Spacer()

              Text("\(relativeTimeFormatter.localizedString(for: postTime, relativeTo: now))")
                .help("\(postTime)")
                .frame(minWidth: 50, alignment: .trailing)
                .padding(.trailing, 12)
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
