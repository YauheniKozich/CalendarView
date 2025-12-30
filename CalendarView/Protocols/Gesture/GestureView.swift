//
//  GestureView.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Foundation

/// Абстрактный view для жестов
/// Позволяет работать с разными типами view (UIView, NSView, кастомные)
public protocol GestureView: AnyObject {
    /// Добавление распознавателя жестов
    func addGestureRecognizer(_ gestureRecognizer: GestureRecognizer)

    /// Удаление распознавателя жестов
    func removeGestureRecognizer(_ gestureRecognizer: GestureRecognizer)
}

