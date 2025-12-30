//
import Foundation
import Combine

/// Типы жестов
public enum GestureKind: Sendable {
    case singleTap
    case doubleTap
    case swipeLeft
    case swipeRight
}

/// Событие жеста
public struct GestureEvent: Sendable {
    public let kind: GestureKind
    public let location: CGPoint?
}

/// Протокол для абстракции обработки жестов
/// Позволяет использовать разные реализации обработки жестов
public protocol GestureHandler: AnyObject {
    /// Publisher для событий жестов
    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> { get }

    /// Настройка жестов на view
    func setupGestures(on view: GestureView)

    /// Удаление всех жестов
    func removeGestures()

    /// Проверка, активен ли обработчик
    var isActive: Bool { get }
}

/// Абстрактный view для жестов
/// Позволяет работать с разными типами view (UIView, NSView, кастомные)
public protocol GestureView: AnyObject {
    /// Добавление распознавателя жестов
    func addGestureRecognizer(_ gestureRecognizer: GestureRecognizer)

    /// Удаление распознавателя жестов
    func removeGestureRecognizer(_ gestureRecognizer: GestureRecognizer)
}

/// Абстрактный распознаватель жестов
public protocol GestureRecognizer {
    /// View, к которому привязан жест
    var view: GestureView? { get }

    /// Состояние жеста
    var state: GestureState { get }

    /// Цель жеста
    func location(in view: GestureView?) -> CGPoint

    /// Добавление цели для обработки
    func addTarget(_ target: Any, action: Selector)

    /// Удаление цели
    func removeTarget(_ target: Any?, action: Selector?)
}

/// Состояние распознавателя жестов
public enum GestureState: Sendable {
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
