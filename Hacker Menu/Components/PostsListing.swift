import SwiftUI

struct PostsListing: View {
    let posts: [StoryFetchResponse]

    var body: some View {
        ForEach(posts) { post in
            PostRow(post: post)
        }
    }
}

struct PostRow: View {
    let post: StoryFetchResponse

    @State private var isHoveringRow: Bool = false
    @State private var showTipRow: Bool = false

    var body: some View {
        let extURL: URL? = if let url = post.url, let extURL = URL(string: url) {
            extURL
        } else {
            nil
        }
        let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!
        let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))

        HStack {
            TwinLink(extURL: extURL, hnURL: hnURL)
                .padding([.leading, .top, .bottom], 2)
                .shadow(color: isHoveringRow ? .accent : .clear, radius: 1)
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
                } else {
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }

                PostInfo(post: post, hnURL: hnURL, postTime: postTime)
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
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .focusable(false)
        .onHover { inside in isHovering = inside }
        .foregroundStyle(isHovering ? .accent : .secondary.opacity(0.5))
        .contentShape(.capsule)
        .clipShape(.capsule)
        .clipped(antialiased: true)
        .blur(radius: isHovering ? 0.0 : 0.5)
        .animation(.default, value: isHovering)
    }
}

struct PostInfo: View {
    let post: StoryFetchResponse
    let hnURL: URL
    let postTime: Date

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
                Text("\(RelativeDateTimeFormatter().localizedString(for: postTime, relativeTo: .now))")
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
