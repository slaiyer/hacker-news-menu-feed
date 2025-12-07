import Foundation
import SwiftUI

@available(macOS 26.0, *)
struct Actions: View {
    let onReload: () -> Void

    @Binding var showHeadline: Bool
    @Binding var sortKey: SortKey
    @Binding var isFetching: Bool

    @State private var isCoolingDown: Bool = false
    @State private var opacity: Double = 0.5
    @State private var blurRadius: Double = 0.5

    @State private var isHoverReload: Bool = false
    @State private var isHoverHeadlineToggle: Bool = false
    @State private var isHoverSortMenu: Bool = false

    enum FocusField: Hashable {
        case reload
    }

    @FocusState private var focusedField: FocusField?

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onReload) {
                Spinner(isSpinning: isFetching)
            }
            .keyboardShortcut("r", modifiers: [])
            .popover(
                isPresented: $isHoverReload,
                arrowEdge: .bottom,
            ) {
                Text("􀂶 Reload feed")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .onHover { inside in isHoverReload = inside }
            .buttonStyle(.accessoryBar)
            .disabled(isFetching || isCoolingDown)
            .focused($focusedField, equals: .reload)
            .focusEffectDisabled()

            Spacer()

            Toggle("ℏ", isOn: $showHeadline)
                .keyboardShortcut("h", modifiers: [])
                .popover(
                    isPresented: $isHoverHeadlineToggle,
                    arrowEdge: .bottom,
                ) {
                    Text("􀂢 Toggle menu bar headline")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .onHover { inside in isHoverHeadlineToggle = inside }
                .toggleStyle(.button)
                .buttonStyle(.accessoryBar)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .clipped(antialiased: true)
                .tint(.gray)
                .focusEffectDisabled()

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
                    .tint(.secondary)
            }
            .popover(
                isPresented: $isHoverSortMenu,
                arrowEdge: .bottom,
            ) {
                Text("􀃊–􀃒 Sort by key")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .onHover { inside in isHoverSortMenu = inside }
            .menuStyle(.borderlessButton)
            .buttonStyle(.accessoryBar)
            .menuIndicator(.hidden)
        }
        .onAppear {
            focusedField = .reload
        }
        .onChange(of: isFetching) { _, isNowFetching in
            if isNowFetching {
                isCoolingDown = false
            } else {
                isCoolingDown = true
                Task {
                    withAnimation {
                        isCoolingDown = false
                        focusedField = .reload
                    }
                }
            }
        }
        .opacity(opacity)
        .blur(radius: blurRadius)
        .onHover { hovering in
            withAnimation {
                if hovering {
                    opacity = 1.0
                    blurRadius = 0.0
                } else {
                    opacity = 0.5
                    blurRadius = 0.5
                }
            }
        }
    }
}

let spinnerAnimationLength = 1.0
let spinnerAnimationDuration = Duration.seconds(spinnerAnimationLength)

@available(macOS 26.0, *)
struct Spinner: View {
    var isSpinning: Bool

    private let reloadSymbol = "arrow.trianglehead.2.clockwise"

    @State private var rotation: Double = 0.0
    @State private var opacity: Double = 0.75
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: reloadSymbol)
            .foregroundStyle(.secondary)
            .opacity(opacity)
            .tint(.secondary)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isSpinning) { _, newValue in
                updateAnimation(shouldSpin: newValue)
            }
            .onAppear {
                updateAnimation(shouldSpin: isSpinning)
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }

    private func updateAnimation(shouldSpin: Bool) {
        if shouldSpin {
            guard animationTask == nil else { return }

            animationTask = Task {
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: spinnerAnimationLength)) {
                        opacity = 0.5
                        rotation += 180
                    }

                    try? await Task.sleep(for: spinnerAnimationDuration)
                }
            }
        } else {
            animationTask?.cancel()
            animationTask = nil

            withAnimation {
                opacity = 0.75
                rotation = 0.0
            }
        }
    }
}
