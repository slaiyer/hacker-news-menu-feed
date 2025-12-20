import SwiftUI

struct AppMenu: View {
    @Binding var posts: [StoryFetchResponse]
    @Binding var isFetching: Bool

    var body: some View {
        if !posts.isEmpty {
            LazyVStack(spacing: 0) {
                PostsListing(posts: posts)
            }
            .animation(.default, value: posts)
            .padding(.top, 4)
            .padding(.leading, 1)
            .padding(.trailing, 14)
        } else {
            ZStack {
                Spacer().containerRelativeFrame([.horizontal, .vertical])

                Image(systemName: "ellipsis")
                    .symbolEffect(
                        .variableColor.iterative.dimInactiveLayers.reversing,
                        options: .repeat(.continuous),
                        isActive: isFetching,
                    )
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
