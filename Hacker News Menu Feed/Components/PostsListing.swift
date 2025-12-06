import Foundation
import SwiftUI
import AppKit

@available(macOS 26.0, *)
struct PostsListing: View {
    var posts: [StoryFetchResponse]

    private let now = Date()
    private let dateTimeFormatter = RelativeDateTimeFormatter()

    @State var isHoveringButton: [Int: Bool] = [:]
    @State var isHoveringHnUrl: [Int: Bool] = [:]

    private let popoverMaxWidth = 350.0
    private let popoverDelay = 0.5

    @State var isHoveringRow: [Int: Bool] = [:]
    @State var showTipRow: [Int: Bool] = [:]

    var body: some View {
        ForEach(
            Array(posts.enumerated()),
            id: \.element.id
        ) {
            idx,
            post in

            let title = post.title ?? "􀉣"
            let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!
            let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))

            HStack(alignment: .center) {
                Button {
                    NSWorkspace.shared.open(hnURL)

                    if let raw = post.url,
                       let extURL = URL(string: raw) {
                        NSWorkspace.shared.open(extURL)
                    }
                } label: {
                    Text("􀉣")
                        .font(.subheadline)
                        .frame(maxHeight: .infinity)
                        .shadow(color: .accent, radius: isHoveringButton[idx] ?? false ? 1 : 0)
                }
                .buttonStyle(.glass)
                .onAppear { isHoveringButton[idx] = false }
                .onHover { inside in isHoveringButton[idx] = inside }
                .foregroundStyle(isHoveringButton[idx] ?? false ? .accent : .secondary)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .opacity(isHoveringButton[idx] ?? false ? 1.0 : 0.5)
                .blur(radius: isHoveringButton[idx] ?? false ? 0.0 : 0.5)
                .animation(.default, value: isHoveringButton[idx])

                VStack(alignment: .leading) {
                    if let extURL = post.url {
                        CustomLink(title: title, link: extURL)
                            .foregroundStyle(.primary)
                    } else {
                        Text(title)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Link(destination: hnURL) {
                            Text("􀆇 \(abbreviateNumber(post.score))")
                                .frame(minWidth: 50, alignment: .leading)

                            Text("􀌲 \(abbreviateNumber(post.comments))")
                                .frame(minWidth: 50, alignment: .leading)

                            if (post.type != "story") {
                                Text("􀈕 \(post.type)")
                                    .textCase(.uppercase)
                                    .frame(alignment: .leading)
                            }
                        }

                        Spacer()

                        Link(destination: hnURL) {
                            Text("\(dateTimeFormatter.localizedString(for: postTime, relativeTo: now))")
                                .frame(alignment: .trailing)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .onAppear { isHoveringHnUrl[idx] = false }
                    .onHover { hovering in isHoveringHnUrl[idx] = hovering }
                    .opacity(isHoveringHnUrl[idx] ?? false ? 1.0 : 0.5)
                    .shadow(color: .accent, radius: isHoveringHnUrl[idx] ?? false ? 1 : 2)
                    .animation(.default, value: isHoveringHnUrl[idx])
                    .padding(.leading)
                }
                .contentShape(.rect)
                .onHover { inside in
                    isHoveringRow[idx] = inside

                    if inside {
                        DispatchQueue.main.asyncAfter(deadline: .now() + popoverDelay) {
                            if isHoveringRow[idx] ?? false {
                                showTipRow[idx] = true
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + popoverDelay / 2) {
                            if !(isHoveringRow[idx] ?? false) {
                                showTipRow[idx] = false
                            }
                        }
                    }
                }
            }
            .popover(
                isPresented: Binding(
                    get: { showTipRow[idx] ?? false },
                    set: { showTipRow[idx] = $0 },
                ),
                arrowEdge: .leading,
            ) {
                VStack(alignment: .leading) {
                    if let title = post.title {
                        Text(title)
                    }

                    if let extURL = post.url {
                        Spacer()

                        Text(extURL)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack {
                        Text(post.type)
                            .textCase(.uppercase)

                        Divider()

                        Text(hnURL.absoluteString)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                    Divider()

                    Text("\(postTime)")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: popoverMaxWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
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
