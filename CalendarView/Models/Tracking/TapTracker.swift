 import Foundation

/// Класс для отслеживания тапов
/// Отвечает только за подсчет тапов и проверку порога
final class TapTracker: TapTracking {
    private var tapCount = 0
    var tapThreshold: Int = 5
    
    init(tapThreshold: Int = 5) {
        self.tapThreshold = tapThreshold
    }
    
    /// Регистрация тапа
    /// - Returns: true если достигнут порог тапов
    func registerTap() -> Bool {
        tapCount += 1
        Logger.debug("Tap registered: \(tapCount)/\(tapThreshold)", category: .gesture)
        return tapCount >= tapThreshold
    }
    
    func registerTap(on items: [AnimatableItem], in container: AnimationContainer) {
        _ = registerTap()
    }
    
    func resetTapCount() {
        tapCount = 0
        Logger.debug("Tap count reset", category: .gesture)
    }
}
