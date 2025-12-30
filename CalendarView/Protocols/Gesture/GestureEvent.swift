//
//  GestureEvent.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Foundation
import UIKit

/// Событие жеста
public struct GestureEvent: Sendable {
    public let kind: GestureKind
    public let location: CGPoint?
}

