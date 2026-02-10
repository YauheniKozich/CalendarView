 import Foundation

/// Протокол для предоставления haptic feedback
/// Позволяет использовать разные реализации (UIKit, mock для тестирования и т.д.)
/// Реализации UIKit должны работать на MainActor
protocol HapticFeedbackProvider {
    /// Вызов haptic feedback при выборе элемента
    func selectionChanged()
    
    /// Вызов haptic feedback при успешном действии
    func success()
    
    /// Вызов haptic feedback при ошибке
    func error()
    
    /// Вызов haptic feedback при предупреждении
    func warning()
}

