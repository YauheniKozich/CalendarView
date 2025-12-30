//
//  GestureState.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Foundation

/// Состояние распознавателя жестов
public enum GestureState: Sendable {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed

    var isEnded: Bool {
        self == .ended
    }
}

