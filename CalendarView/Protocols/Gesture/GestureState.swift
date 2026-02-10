 import Foundation

/// Состояние распознавателя жестов
enum GestureState: Sendable {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed

    var isEnded: Bool {
        self == .ended
    }
}

