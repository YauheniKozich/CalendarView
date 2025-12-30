//
//  NoOpHapticFeedbackProvider.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Реализация HapticFeedbackProvider для тестирования (no-op)
/// Не выполняет никаких действий, используется в тестах
@MainActor
public final class NoOpHapticFeedbackProvider: HapticFeedbackProvider {
    public init() {}
    
    public func selectionChanged() {
        // No-op для тестирования
    }
    
    public func success() {
        // No-op для тестирования
    }
    
    public func error() {
        // No-op для тестирования
    }
    
    public func warning() {
        // No-op для тестирования
    }
}

