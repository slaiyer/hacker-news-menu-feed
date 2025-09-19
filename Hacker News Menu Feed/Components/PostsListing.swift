import Foundation
import SwiftUI
import AppKit

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
            .font(.system(size: 10))
            .frame(maxHeight: .infinity)
        }
        .tint(.orange)
        .onHover { hovering in
          if hovering {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }

        VStack(alignment: .leading) {
          let title = (post.title ?? "􀉣").trimmingCharacters(in: .whitespacesAndNewlines).filter{!$0.isNewline}

          if let url = post.url {
            CustomLink(title: title, link: url)
              .foregroundColor(.primary)
              .help("\(title)\n\n\(url)")
          } else {
            Text(title)
              .foregroundColor(.primary)
              .help(title)
          }

          Link(destination: URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!) {
            HStack {
              Text("􀆇 \(post.score)")
                .frame(minWidth: 50, alignment: .leading)

              Text("􀌲 \(post.comments ?? 0)")
                .frame(minWidth: 50, alignment: .leading)
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
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
