 import UIKit

/// Реализация HapticFeedbackProvider на основе UIKit
final class UIKitHapticFeedbackProvider: HapticFeedbackProvider {
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator
    
    init() {
        self.selectionGenerator = UISelectionFeedbackGenerator()
        self.notificationGenerator = UINotificationFeedbackGenerator()
        // Подготавливаем генераторы для лучшей производительности
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Подготавливаем для следующего использования
    }
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
}

