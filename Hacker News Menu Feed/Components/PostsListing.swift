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
    
    var body: some View {
        ForEach(
            Array(posts.enumerated()),
            id: \.element.id
        ) {
            idx,
            post in
            HStack(alignment: .center) {
                let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(post.id)")!
                
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
                .onHover { hovering in isHoveringButton[idx] = hovering }
                .foregroundStyle(isHoveringButton[idx] ?? false ? .accent : .secondary)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .opacity(isHoveringButton[idx] ?? false ? 1.0 : 0.5)
                .blur(radius: isHoveringButton[idx] ?? false ? 0.0 : 0.5)
                .animation(.snappy, value: isHoveringButton)
                
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
                                .foregroundStyle(.secondary)
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
                        .help(hnURL.absoluteString)
                        
                        Spacer()
                        
                        let postTime = Date(timeIntervalSince1970: TimeInterval(post.time))
                        Link(destination: hnURL) {
                            Text("\(dateTimeFormatter.localizedString(for: postTime, relativeTo: now))")
                                .help("\(postTime)")
                                .frame(minWidth: 100, alignment: .trailing)
                        }
                    }
                    .font(.subheadline)
                    .onAppear { isHoveringHnUrl[idx] = false }
                    .onHover { hovering in isHoveringHnUrl[idx] = hovering }
                    .foregroundStyle(.secondary)
                    .opacity(isHoveringHnUrl[idx] ?? false ? 1.0 : 0.5)
                    .shadow(color: .accent, radius: isHoveringHnUrl[idx] ?? false ? 1 : 2)
                    .animation(.snappy, value: isHoveringHnUrl)
                    .padding(.leading)
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
