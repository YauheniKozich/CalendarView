//
//  CalendarViewModelAdapter.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import SwiftUI
import Combine

// MARK: - Адаптер для ViewModel для использования ее на SwiftUI

final class CalendarViewModelAdapter: ObservableObject {
    @Published var calendarDays: [CalendarDay] = []

    private let viewModel: CalendarViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel

        viewModel.$calendarDays
            .receive(on: DispatchQueue.main)
            .assign(to: &$calendarDays)

        viewModel.load()
    }

    func select(_ date: Date) {
        viewModel.select(date)
    }

    func clear() {
        viewModel.clear()
    }

    func changeMonth(by delta: Int) {
        viewModel.changeMonth(by: delta)
    }

    func isDateSelected(_ date: Date) -> Bool {
        viewModel.isDateSelected(date)
    }

    func isDateInRange(_ date: Date) -> Bool {
        viewModel.isDateInRange(date)
    }

    var currentMonth: String {
        viewModel.monthFormatter.string(from: viewModel.currentMonth)
    }
}
