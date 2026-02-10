 import Foundation

/// Протокол для абстракции обработки жестов
/// Позволяет использовать разные реализации обработки жестов
protocol GestureHandler: AnyObject {
    /// Callback для обработки событий жестов
    var onGestureEvent: ((GestureEvent) -> Void)? { get set }

    /// Настройка жестов на view
    func setupGestures(on view: GestureView)

    /// Удаление всех жестов
    func removeGestures()

    /// Проверка, активен ли обработчик
    var isActive: Bool { get }
}
