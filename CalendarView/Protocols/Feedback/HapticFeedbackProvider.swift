//
//  HapticFeedbackProvider.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Протокол для предоставления haptic feedback
/// Позволяет использовать разные реализации (UIKit, mock для тестирования и т.д.)
@MainActor
public protocol HapticFeedbackProvider {
    /// Вызов haptic feedback при выборе элемента
    func selectionChanged()
    
    /// Вызов haptic feedback при успешном действии
    func success()
    
    /// Вызов haptic feedback при ошибке
    func error()
    
    /// Вызов haptic feedback при предупреждении
    func warning()
}

