import Foundation
import SwiftUI

@available(macOS 26.0, *)
struct Actions: View {
  var onReload: () -> Void
  var onQuit: () -> Void

  @Binding var showHeadline: Bool

  enum FocusField: Hashable {
    case reload
    case quit
    case headline
  }

  @FocusState private var focusedField: FocusField?

  var body: some View {
    HStack(alignment: .top) {
      Button(action: onReload) {
        Image(systemName: "arrow.clockwise")
          .foregroundStyle(.tertiary)
      }
      .buttonStyle(.glass)
      .focused($focusedField, equals: .reload)

      Spacer()

      Toggle("Headline", isOn: $showHeadline)
        .toggleStyle(.button)
        .tint(.orange)
        .focused($focusedField, equals: .headline)

      Spacer()

      Button(action: onQuit) {
        Image(systemName: "power")
          .foregroundStyle(.tertiary)
      }
      .buttonStyle(.glass)
      .focused($focusedField, equals: .quit)
    }
    .onAppear {
      focusedField = .reload
    }
    .focusEffectDisabled()
  }
}
