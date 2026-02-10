 import UIKit

/// Событие жеста
struct GestureEvent: Sendable {
    let kind: GestureKind
    let location: CGPoint?
}

