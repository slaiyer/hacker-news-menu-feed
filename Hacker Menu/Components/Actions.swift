import SwiftUI

@available(macOS 26.0, *)
struct Actions: View {
    let reload: () -> Void
    @Binding var isFetching: Bool
    @Binding var showHeadline: Bool
    @Binding var sortKey: SortKey

    @State private var isHoverRow: Bool = false

    var body: some View {
        ZStack {
            Toggle("ℏ", isOn: $showHeadline)
                .keyboardShortcut("h", modifiers: [])
                .help("􀂢 Toggle headline")
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .focusable(false)

            HStack {
                Button(action: reload, label: {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .symbolEffect(
                            .rotate,
                            options: .repeat(.periodic(delay: 0)),
                            isActive: isFetching,
                        )
                })
                .keyboardShortcut("r", modifiers: [])
                .help("􀂶 Reload")
                .buttonStyle(.borderless)
                .tint(.secondary)
                .focusable(false)
                .disabled(isFetching)
                .animation(.default, value: isFetching)

                Spacer()

                Menu {
                    ForEach(SortKey.allCases) { key in
                        Button {
                            sortKey = key
                        } label: {
                            Label(key.label, systemImage: sortKey == key ? "checkmark" : "")
                        }
                        // TODO: maintain sync with ContentView commands; this is here only for the Menu symbols in the UI
                        .keyboardShortcut(KeyEquivalent(key.cut), modifiers: [])
                    }
                } label: {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                }
                .help("􀃊–􀃒 Sort by")
                .menuStyle(.borderlessButton)
                .buttonStyle(.borderless)
                .tint(.secondary)
                .menuIndicator(.hidden)
                .focusable(false)
            }
            .padding(.leading, 13)
            .padding(.trailing, 10)
        }
        .focusEffectDisabled()
        .opacity(isHoverRow ? 1.0 : 0.5)
        .blur(radius: isHoverRow ? 0.0: 1.0)
        .onHover { hovering in isHoverRow = hovering }
        .animation(.default, value: isHoverRow)
    }
}
