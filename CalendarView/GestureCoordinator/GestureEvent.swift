//
//  GestureEvent.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Foundation

struct GestureEvent {
    enum Kind {
        case singleTap
        case doubleTap
        case swipeLeft
        case swipeRight
    }
    let kind: Kind
    let location: CGPoint?
}
