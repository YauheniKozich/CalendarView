//
import Foundation
import UIKit

/// Протокол для анимации "взрыва"
/// Позволяет использовать разные реализации анимации
/// Все реализации должны работать на MainActor, так как работают с UIKit компонентами
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

    /// Сброс состояния аниматора
    func reset()

    /// Проверка, выполняется ли анимация
    var isAnimating: Bool { get }

    /// Callback при завершении анимации
    var onAnimationComplete: (() -> Void)? { get set }

    /// Async версия запуска анимации взрыва
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    /// - Returns: true если анимация запущена успешно
    func explodeAsync(items: [AnimatableItem], in container: AnimationContainer) async -> Bool
}

