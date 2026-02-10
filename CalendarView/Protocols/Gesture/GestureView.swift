 import Foundation

/// Абстрактный view для жестов
/// Позволяет работать с разными типами view (UIView, NSView, кастомные)
protocol GestureView: AnyObject {
    /// Добавление распознавателя жестов
    func addGestureRecognizer(_ gestureRecognizer: GestureRecognizer)

    /// Удаление распознавателя жестов
    func removeGestureRecognizer(_ gestureRecognizer: GestureRecognizer)
}

