 import Foundation

/// Реализация HapticFeedbackProvider для тестирования (no-op)
/// Не выполняет никаких действий, используется в тестах
final class NoOpHapticFeedbackProvider: HapticFeedbackProvider {
    init() {}
    
    func selectionChanged() {
        // No-op для тестирования
    }
    
    func success() {
        // No-op для тестирования
    }
    
    func error() {
        // No-op для тестирования
    }
    
    func warning() {
        // No-op для тестирования
    }
}

