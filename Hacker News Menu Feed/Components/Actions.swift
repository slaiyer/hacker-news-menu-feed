import Foundation
import SwiftUI

let reloadSymbol = "arrow.trianglehead.2.clockwise"
let spinnerAnimationLength = 1.0
let spinnerAnimationDuration = Duration.seconds(1.0)

@available(macOS 26.0, *)
struct Actions: View {
  var onReload: () -> Void
  var onQuit: () -> Void

  @Binding var showHeadline: Bool
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
      .buttonStyle(.glass)
      .disabled(isFetching || isCoolingDown)
      .focused($focusedField, equals: .reload)

      Spacer()

      Toggle("Headline", isOn: $showHeadline)
        .toggleStyle(.button)
        .tint(.orange)

      Spacer()

      Button(action: onQuit) {
        Image(systemName: "power")
          .foregroundStyle(.tertiary)
      }
      .buttonStyle(.glass)
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
              isCoolingDown = false
              focusedField = .reload
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
      .foregroundStyle(.tertiary)
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
