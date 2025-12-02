import Foundation
import SwiftUI
import AppKit

@available(macOS 26.0, *)
struct PostsListing: View {
  var posts: [StoryFetchResponse]
  
  private let now = Date()
  private let dateTimeFormatter = RelativeDateTimeFormatter()

  @State var isHovering: [Int: Bool] = [:]

  var body: some View {
    ForEach(
      Array(posts.enumerated()),
      id: \.element.id
    ) { idx, post in
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
        .foregroundStyle(isHovering[idx] ?? false ? .accent : .secondary)
        .contentShape(.containerRelative)
        .clipShape(.capsule)
        .clipped(antialiased: true)
        .onHover { hovering in isHovering[idx] = hovering }
        .opacity(isHovering[idx] ?? false ? 1.0 : 0.5)
        .blur(radius: isHovering[idx] ?? false ? 0.0 : 1.0)
        .animation(.easeInOut, value: isHovering)

        VStack(alignment: .leading) {
          HStack {
            let title = post.title ?? "􀉣"

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
          }
          
          HStack {
            Link(destination: hnURL) {
              Text("􀆇 \(abbreviateNumber(post.score))")
                .frame(minWidth: 50, alignment: .leading)
              
              Text("􀌲 \(abbreviateNumber(post.comments))")
                .frame(minWidth: 50, alignment: .leading)
              
              if (post.type != "story") {
                Text("􀈕 \(post.type.uppercased())")
                  .frame(minWidth: 50, alignment: .leading)
              }
            }

            Spacer()

            let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))
            Link(destination: hnURL) {
              Text("\(dateTimeFormatter.localizedString(for: postTime, relativeTo: now))")
                .help("\(postTime)")
                .frame(minWidth: 100, alignment: .trailing)
            }
          }
          .font(.subheadline)
          .foregroundStyle(Color(.secondaryLabelColor))
          .padding(.leading)
          .onHover { hovering in
            if hovering {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }
        }
        .padding(.trailing, 10)
      }
    }
  }
}

func abbreviateNumber(_ number: Int?) -> String {
  guard let number = number else {
    return "—"
  }
  
  return number.formatted(.number.notation(.compactName))
}
