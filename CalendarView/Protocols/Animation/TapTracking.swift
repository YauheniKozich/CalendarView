//
//  TapTracking.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Протокол для отслеживания тапов (опциональная функциональность)
/// Позволяет разделить ответственность отслеживания тапов от анимации
/// Реализации должны работать на MainActor для работы с UIKit
public protocol TapTracking {
    /// Регистрация тапа для активации действия
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    func registerTap(on items: [AnimatableItem], in container: AnimationContainer)
    
    /// Сброс счетчика тапов
    func resetTapCount()
    
    /// Порог тапов для активации действия
    var tapThreshold: Int { get set }
}

