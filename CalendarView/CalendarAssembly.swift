//
//  AssemblyCalendar.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import Foundation
import UIKit

enum CalendarAssembly {
    static func makeCalendarViewController(
        viewModel: CalendarViewModel,
        explosionAnimator: CalendarExplosionAnimator,
        gestureCoordinator: GestureCoordinator? = nil
    ) -> CalendarViewController {
        return CalendarViewController(
            viewModel: viewModel,
            explosionAnimator: explosionAnimator,
            gestureCoordinator: gestureCoordinator ?? GestureCoordinator(view: UIView(), gestureView: UIView())
        )
    }
}
