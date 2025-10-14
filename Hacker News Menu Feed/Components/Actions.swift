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
      .buttonStyle(.accessoryBar)
      .disabled(isFetching || isCoolingDown)
      .focused($focusedField, equals: .reload)

      Spacer()

      Toggle("Headline", isOn: $showHeadline)
        .toggleStyle(.button)
        .tint(.orange)
        .focusEffectDisabled()

      Spacer()

      Menu {
        ForEach(SortKey.allCases) { key in
          Button {
            sortKey = key
            onSort()
          } label: {
            Label(key.label + "\t", systemImage: sortKey == key ? "checkmark" : "")
          }
          .tint(.orange)
        }
      } label: {
        Image(systemName: "arrow.up.arrow.down")
          .tint(.secondary)
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      .padding(.horizontal, 8)
      .focusEffectDisabled()
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
          try? await Task.sleep(for: spinnerAnimationDuration)

          if !isFetching {
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
    .focusEffectDisabled()
  }
}

@available(macOS 26.0, *)
struct Spinner: View {
  var isSpinning: Bool

  @State private var rotation: Double = 0.0
  @State private var animationTask: Task<Void, Never>?

  var body: some View {
    Image(systemName: reloadSymbol)
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
              rotation += 180
            }
          }

          try? await Task.sleep(for: spinnerAnimationDuration)
        }
      }
    } else {
      animationTask?.cancel()
      animationTask = nil
      rotation = 0.0
    }
  }
}
