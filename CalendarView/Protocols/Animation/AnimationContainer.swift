 import UIKit

/// Контейнер для анимации
protocol AnimationContainer: AnyObject {
    /// Обновление layout
    func setNeedsLayout()

    /// Принудительное обновление layout
    func layoutIfNeeded()

    /// Видимые элементы
    var visibleItems: [AnimatableItem] { get }
}
extension AnimationContainer where Self: UIView {
    func setNeedsLayout() {
        self.setNeedsLayout()
    }

    func layoutIfNeeded() {
        self.layoutIfNeeded()
    }
}

