//
import Foundation
import UIKit

/// Протокол для анимации "взрыва"
/// Позволяет использовать разные реализации анимации
public protocol ExplosionAnimator {
    /// Запуск анимации взрыва
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    /// - Throws: Ошибки анимации
    func explode(items: [AnimatableItem], in container: AnimationContainer) throws

    /// Безопасная версия запуска анимации (обрабатывает ошибки internally)
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    func explodeSafely(items: [AnimatableItem], in container: AnimationContainer)

    /// Восстановление интерактивности
    /// - Parameters:
    ///   - items: Элементы для восстановления
    ///   - container: Контейнер для обновления
    func restoreUserInteraction(items: [AnimatableItem], in container: AnimationContainer)

    /// Регистрация тапа для взрыва
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    func registerTap(on items: [AnimatableItem], in container: AnimationContainer)

    /// Сброс состояния аниматора
    func reset()

    /// Проверка, выполняется ли анимация
    var isAnimating: Bool { get }

    /// Сброс счетчика тапов
    func resetTapCount()

    /// Порог тапов для активации взрыва
    var tapThreshold: Int { get set }

    /// Callback при завершении анимации
    var onAnimationComplete: (() -> Void)? { get set }

    /// Async версия запуска анимации взрыва
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    /// - Returns: true если анимация запущена успешно
    func explodeAsync(items: [AnimatableItem], in container: AnimationContainer) async -> Bool
}

/// Абстрактный элемент для анимации
public protocol AnimatableItem: AnyObject {
    /// Проверка возможности взаимодействия
    var isUserInteractionEnabled: Bool { get set }
}

/// Контейнер для анимации
public protocol AnimationContainer: AnyObject {
    /// Обновление layout
    func setNeedsLayout()

    /// Принудительное обновление layout
    func layoutIfNeeded()

    /// Видимые элементы
    var visibleItems: [AnimatableItem] { get }
}

// MARK: - Default Implementation for UIView
extension AnimationContainer where Self: UIView {
    public func setNeedsLayout() {
        self.setNeedsLayout()
    }

    public func layoutIfNeeded() {
        self.layoutIfNeeded()
    }
}
