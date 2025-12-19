import SwiftUI

struct PostsListing: View {
    let posts: [StoryFetchResponse]

    private let dateTimeFormatter = RelativeDateTimeFormatter()

    var body: some View {
        ForEach(posts) { post in
            let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))

            PostRow(
                post: post,
                postTime: postTime,
                timestamp: dateTimeFormatter.localizedString(for: postTime, relativeTo: .now),
            )
        }
    }
}

struct PostRow: View {
    let post: StoryFetchResponse
    let postTime: Date
    let timestamp: String

    @State private var isHoveringRow: Bool = false
    @State private var showTipRow: Bool = false

    var body: some View {
        let extURL: URL? = if let url = post.url, let extURL = URL(string: url) {
            extURL
        } else {
            nil
        }
        let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!

        HStack {
            TwinLink(extURL: extURL, hnURL: hnURL)
                .padding(.leading, 2)
                .shadow(color: isHoveringRow ? .accent : .clear, radius: 2)
                .highPriorityGesture(LongPressGesture().onEnded { _ in showTipRow = true })
                .onHover { hovering in
                    if !hovering {
                        showTipRow = false
                    }
                }

            VStack(alignment: .leading) {
                let title = post.title ?? "􀉣"

                if let extURL {
                    ExternalLink(title: title, link: extURL)
                        .foregroundStyle(.primary)
                        .shadow(color: .accent, radius: isHoveringRow ? 0.75 : 0)
                } else {
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .shadow(color: .accent, radius: isHoveringRow ? 0.5 : 0)
                }

                PostInfo(
                    post: post,
                    hnURL: hnURL,
                    timestamp: timestamp,
                )
            }
            .onHover { hovering in
                if !hovering {
                    showTipRow = false
                }
            }
        }
        .contentShape(.rect)
        .onHover { hovering in isHoveringRow = hovering }
        .gesture(LongPressGesture().onEnded { _ in showTipRow = true })
        .animation(.easeIn, value: isHoveringRow)
        .popover(isPresented: $showTipRow, arrowEdge: .leading) {
            VStack(alignment: .leading) {
                if let title = post.title {
                    Text(title)
                }

                if let extURL {
                    Spacer()

                    Text(extURL.standardized.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text(post.type)
                        .textCase(.uppercase)

                    Divider()

                    Text(hnURL.standardized.absoluteString)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("\(postTime)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 350, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: .accent, radius: 0)
            .padding()
        }
    }
}

struct TwinLink: View {
    let extURL: URL?
    let hnURL: URL

    @State private var isHovering: Bool = false

    var body: some View {
        Button {
            if let extURL {
                NSWorkspace.shared.open(extURL)
            }

            NSWorkspace.shared.open(hnURL)
        } label: {
            Text("􀉣")
                .font(.subheadline)
                .shadow(color: .accent, radius: 0)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .focusable(false)
        .onHover { inside in isHovering = inside }
        .foregroundStyle(isHovering ? .accent : .secondary.opacity(0.5))
        .contentShape(.circle)
        .clipShape(.circle)
        .clipped(antialiased: true)
        .blur(radius: isHovering ? 0.0 : 0.5)
        .animation(.default, value: isHovering)
    }
}

struct PostInfo: View {
    let post: StoryFetchResponse
    let hnURL: URL
    let timestamp: String

    @State private var isHoveringHnUrl: Bool = false

    var body: some View {
        HStack {
            Link(destination: hnURL) {
                Text("􀆇 \(abbreviateNumber(post.score))")
                    .frame(minWidth: 50, alignment: .leading)

                Text("􀌲 \(abbreviateNumber(post.comments))")
                    .frame(minWidth: 50, alignment: .leading)

                if post.type != "story" {
                    Text("􀈕 \(post.type)")
                        .textCase(.uppercase)
                        .frame(alignment: .leading)
                }
            }
            .padding(.leading)
            .focusable(false)

            Spacer()

            Link(destination: hnURL) {
                Text(timestamp)
                    .frame(alignment: .trailing)
            }
            .focusable(false)
        }
        .padding(.leading)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .onHover { hovering in isHoveringHnUrl = hovering }
        .opacity(isHoveringHnUrl ? 1.0 : 0.5)
        .shadow(color: .accent, radius: isHoveringHnUrl ? 1 : 2)
        .animation(.default, value: isHoveringHnUrl)
    }

    private func abbreviateNumber(_ number: Int?) -> String {
        guard let number = number else {
            return "—"
        }

        return number.formatted(.number.notation(.compactName))
    }
}
