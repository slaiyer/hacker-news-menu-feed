import SwiftUI

struct Actions: View {
    let reload: () -> Void
    @Binding var isFetching: Bool
    @Binding var showHeadline: Bool
    @Binding var sortKey: SortKey

    @State private var isHoverRow: Bool = false

    var body: some View {
        ZStack {
            Toggle(isHoverRow ? "ℏ" : "·", isOn: $showHeadline)
                .fontWeight(.thin)
                .keyboardShortcut("h", modifiers: [])
                .help("􀂢 Headline")
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .focusable(false)
                .foregroundStyle(showHeadline ? .accent.mix(with: .primary, by: 0.5) : .secondary)
                .shadow(color: showHeadline ? .accent : .secondary, radius: isHoverRow ? 5 : 0)
                .blur(radius: isHoverRow ? 0 : showHeadline ? 0.5 : 2)
                .animation(.default, value: showHeadline)

            HStack {
                Button(action: reload, label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                        .symbolEffect(
                            .rotate,
                            options: .repeat(.continuous),
                            isActive: isFetching,
                        )
                })
                .keyboardShortcut("r", modifiers: [])
                .help("􀂶 Reload")
                .buttonStyle(.borderless)
                .focusable(false)
                .disabled(isFetching)
                .opacity(isHoverRow || isFetching ? 1 : 0)
                .animation(.default, value: isFetching)

                Spacer()

                Menu {
                    ForEach(SortKey.allCases) { key in
                        Button {
                            sortKey = key
                        } label: {
                            Label(key.label, systemImage: sortKey == key ? "checkmark" : "")
                        }
                        .tint(.accent.mix(with: .primary, by: 0.5))
                        // TODO: maintain sync with ContentView commands; this is here only for the Menu symbols in the UI
                        .keyboardShortcut(KeyEquivalent(key.cut), modifiers: [])
                    }
                } label: {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                }
                .help("􀃊–􀃒 Sort")
                .menuStyle(.borderlessButton)
                .buttonStyle(.borderless)
                .menuIndicator(.hidden)
                .focusable(false)
                .opacity(isHoverRow || sortKey != .original ? 1 : 0)
                .animation(.default, value: sortKey)
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
        }
        .controlSize(.small)
        .tint(.accent.mix(with: .primary, by: 0.5))
        .onHover { hovering in isHoverRow = hovering }
        .shadow(color: .primary, radius: 0)
        .animation(.default, value: isHoverRow)
    }
}
