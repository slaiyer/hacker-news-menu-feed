import SwiftUI

@available(macOS 26.0, *)
struct Actions: View {
    let onReload: () -> Void

    @Binding var showHeadline: Bool
    @Binding var sortKey: SortKey
    @Binding var isFetching: Bool

    @State private var opacity: Double = 0.5
    @State private var blurRadius: Double = 1.0

    @State private var isHoverReload: Bool = false
    @State private var isHoverHeadlineToggle: Bool = false
    @State private var isHoverSortMenu: Bool = false

    var body: some View {
        HStack {
            Button(action: onReload, label: {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .symbolEffect(
                        .rotate.wholeSymbol,
                        options: .repeat(.continuous),
                        isActive: isFetching,
                    )
            })
            .keyboardShortcut("r", modifiers: [])
            .popover(
                isPresented: $isHoverReload,
                arrowEdge: .bottom,
            ) {
                Text("􀂶 Reload")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .onHover { inside in isHoverReload = inside }
            .buttonStyle(.borderless)
            .tint(.secondary)
            .focusable(false)
            .disabled(isFetching)

            Spacer()

            Toggle("ℏ", isOn: $showHeadline)
                .keyboardShortcut("h", modifiers: [])
                .popover(
                    isPresented: $isHoverHeadlineToggle,
                    arrowEdge: .bottom,
                ) {
                    Text("􀂢 Toggle headline")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .onHover { inside in isHoverHeadlineToggle = inside }
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .focusable(false)

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
            .popover(
                isPresented: $isHoverSortMenu,
                arrowEdge: .bottom,
            ) {
                Text("􀃊–􀃒 Sort by")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .onHover { inside in isHoverSortMenu = inside }
            .menuStyle(.borderlessButton)
            .buttonStyle(.borderless)
            .tint(.secondary)
            .menuIndicator(.hidden)
            .focusable(false)
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .focusEffectDisabled()
        .opacity(opacity)
        .blur(radius: blurRadius)
        .onHover { hovering in
            withAnimation {
                if hovering {
                    opacity = 1.0
                    blurRadius = 0.0
                } else {
                    opacity = 0.5
                    blurRadius = 1.0
                }
            }
        }
    }
}
