//
//  TapTracker.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Класс для отслеживания тапов
/// Отвечает только за подсчет тапов и проверку порога
public final class TapTracker: TapTracking {
    private var tapCount = 0
    public var tapThreshold: Int = 5
    
    public init(tapThreshold: Int = 5) {
        self.tapThreshold = tapThreshold
    }
    
    /// Регистрация тапа
    /// - Returns: true если достигнут порог тапов
    public func registerTap() -> Bool {
        tapCount += 1
        Logger.debug("Tap registered: \(tapCount)/\(tapThreshold)", category: .gesture)
        return tapCount >= tapThreshold
    }
    
    public func registerTap(on items: [AnimatableItem], in container: AnimationContainer) {
        // Этот метод оставлен для совместимости с протоколом
        // Реальная логика в registerTap()
        _ = registerTap()
    }
    
    public func resetTapCount() {
        tapCount = 0
        Logger.debug("Tap count reset", category: .gesture)
    }
}

