import Foundation
import SwiftUI

let reloadSymbol = "arrow.trianglehead.2.clockwise"
let spinnerAnimationLength = 1.0
let spinnerAnimationDuration = Duration.seconds(spinnerAnimationLength)

@available(macOS 26.0, *)
struct Actions: View {
  var onReload: () -> Void
  var onSort: () -> Void

  @Binding var showHeadline: Bool
  @Binding var sortKey: SortKey
  @Binding var isFetching: Bool

  @State private var isCoolingDown: Bool = false

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
      .help("Reload feed (R)")
      .buttonStyle(.accessoryBar)
      .disabled(isFetching || isCoolingDown)
      .focused($focusedField, equals: .reload)
      .focusEffectDisabled()

      Spacer()

      Toggle("ℏ", isOn: $showHeadline)
        .keyboardShortcut("h", modifiers: [])
        .help("Toggle headline in menu bar (H)")
        .toggleStyle(.button)
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
            onSort()
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
      .help("Sort key")
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      .padding(.trailing, 6)
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
          await MainActor.run {
            withAnimation {
              isCoolingDown = false
              focusedField = .reload
            }
          }
        }
      }
    }
  }
}

@available(macOS 26.0, *)
struct Spinner: View {
  var isSpinning: Bool

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
          await MainActor.run {
            withAnimation(.easeInOut(duration: spinnerAnimationLength)) {
              opacity = 0.5
              rotation += 180
            }
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
