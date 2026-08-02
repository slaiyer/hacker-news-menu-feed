import SwiftUI

struct PostsListing: View {
    let posts: [StoryFetchResponse]
    @FocusState.Binding var focus: Int?

    static let openConfig = {
        let conf = NSWorkspace.OpenConfiguration()
        conf.activates = false
        return conf
    }()

    private static let dateTimeFormatter = RelativeDateTimeFormatter()

    var body: some View {
        ForEach(posts) { post in
            let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))

            PostRow(
                post: post,
                postTime: postTime,
                timestamp: PostsListing.dateTimeFormatter.localizedString(for: postTime, relativeTo: .now),
                openConfig: PostsListing.openConfig,
            )
            .onHover { hovering in
                if hovering {
                    NSApp.activate()
                    focus = post.id
                }
            }
            .focused($focus, equals: post.id)
        }
    }
}

struct PostRow: View {
    let post: StoryFetchResponse
    let postTime: Date
    let timestamp: String
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHoverRow: Bool = false
    @State private var showTipRow: Bool = false

    var body: some View {
        let extURL: URL? = if let url = post.url, let extURL = URL(string: url) { extURL } else { nil }
        let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!

        VStack {
            HStack {
                TwinLink(extURL: extURL, hnURL: hnURL, openConfig: openConfig)
                    .padding(.leading, 2)
                    .shadow(color: isHoverRow ? .accent.mix(with: .primary, by: 0.5) : .clear, radius: 2)
                    .blur(radius: isHoverRow ? 0 : 0.5)

                VStack(alignment: .leading) {
                    let title = post.title ?? "􀉣"

                    if let extURL {
                        ExternalLink(title: title, link: extURL, openConfig: openConfig)
                            .foregroundStyle(.primary)
                            .shadow(color: .accent, radius: isHoverRow ? 0.5 : 0)
                    } else {
                        Text(title)
                            .foregroundStyle(.accent.mix(with: .primary, by: 0.5))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .shadow(color: .accent, radius: 0)
                    }

                    PostInfo(
                        post: post,
                        hnURL: hnURL,
                        timestamp: timestamp,
                        openConfig: openConfig,
                    )
                }
                .onHover { hovering in
                    if !hovering {
                        showTipRow = false
                    }
                }
            }
            .popover(isPresented: $showTipRow, arrowEdge: .leading) {
                VStack(alignment: .leading) {
                    if let title = post.title {
                        Text(title)
                            .font(.callout)
                    }

                    if let extURL {
                        Spacer()

                        Text(extURL.standardized.absoluteString)
                            .font(.subheadline)
                            .fontWeight(.thin)
                    }

                    Divider()

                    HStack {
                        Text(post.type)
                            .textCase(.uppercase)

                        Divider()

                        Text(hnURL.standardized.absoluteString)
                    }
                    .font(.subheadline)
                    .fontWeight(.thin)

                    Divider()

                    Text("\(postTime)")
                        .font(.subheadline)
                        .fontWeight(.thin)
                }
                .fontWidth(.standard)
                .frame(maxWidth: 350, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .accent, radius: 0)
                .padding()
            }

            Spacer()
        }
        .contentShape(.rect)
        .animation(.easeIn, value: isHoverRow)
        .onHover { hovering in
            isHoverRow = hovering

            if !hovering {
                showTipRow = false
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.3,
            perform: { showTipRow = true },
        )
        .focusable()
        .onKeyPress(.space, phases: .all) { keyPress in
            if !isHoverRow {
                return .handled
            }

            if keyPress.phase == .up {
                showTipRow.toggle()
            }

            return .handled
        }
        .onKeyPress(.return, phases: .all) { keyPress in
            if !isHoverRow {
                return .handled
            }

            if keyPress.phase == .up {
                if let extURL {
                    NSWorkspace.shared.open(extURL, configuration: openConfig)
                }

                NSWorkspace.shared.open(hnURL, configuration: openConfig)
            }

            return .handled
        }
    }
}

struct TwinLink: View {
    let extURL: URL?
    let hnURL: URL
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHovering: Bool = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(hnURL, configuration: openConfig)

            if let extURL {
                NSWorkspace.shared.open(extURL, configuration: openConfig)
            }
        } label: {
            Text("􀉣")
                .font(.footnote)
                .shadow(color: .accent, radius: 0)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .focusable(false)
        .onHover { inside in
            isHovering = inside

            DispatchQueue.main.async {
                if (isHovering) {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .foregroundStyle(isHovering ? .accent.mix(with: .primary, by: 0.5) : .secondary.opacity(0.5))
        .contentShape(.circle)
        .clipShape(.circle)
        .clipped(antialiased: true)
        .animation(.default, value: isHovering)
    }
}

struct PostInfo: View {
    let post: StoryFetchResponse
    let hnURL: URL
    let timestamp: String
    let openConfig: NSWorkspace.OpenConfiguration

    @State private var isHoveringHnUrl: Bool = false

    var body: some View {
        HStack {
            Button(
                action: { NSWorkspace.shared.open(hnURL, configuration: openConfig) },
                label: {
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
            )
            .buttonStyle(.borderless)
            .focusable(false)
            .padding(.leading)
            .onHover { hovering in
                DispatchQueue.main.async {
                    if (hovering) {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }

            Spacer()

            Button(
                action: { NSWorkspace.shared.open(hnURL, configuration: openConfig) },
                label: {
                    Text(timestamp)
                        .frame(alignment: .trailing)
                }
            )
            .buttonStyle(.borderless)
            .focusable(false)
            .onHover { hovering in
                DispatchQueue.main.async {
                    if (hovering) {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .font(.subheadline)
        .fontWeight(.thin)
        .padding(.leading)
        .foregroundStyle(isHoveringHnUrl ? .accent.mix(with: .primary, by: 0.5) : .secondary)
        .onHover { hovering in isHoveringHnUrl = hovering }
        .opacity(isHoveringHnUrl ? 1.0 : 0.5)
        .shadow(color: .accent, radius: isHoveringHnUrl ? 0 : 0.5)
        .animation(.default, value: isHoveringHnUrl)
    }

    private func abbreviateNumber(_ number: Int?) -> String {
        guard let number = number else {
            return "—"
        }

        return number.formatted(.number.notation(.compactName))
    }
}
