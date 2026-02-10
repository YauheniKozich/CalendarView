 import Foundation

/// Абстрактный элемент для анимации
protocol AnimatableItem: AnyObject {
    /// Проверка возможности взаимодействия
    var isUserInteractionEnabled: Bool { get set }
}

