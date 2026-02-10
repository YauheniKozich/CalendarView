 import UIKit

/// Абстрактный распознаватель жестов
protocol GestureRecognizer {
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

