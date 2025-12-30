//
//  CalendarViewModelAdapter.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import SwiftUI
import Combine

// MARK: - Адаптер для ViewModel для использования ее на SwiftUI

@MainActor
public final class CalendarViewModelAdapter: ObservableObject {
    @Published var calendarDays: [CalendarDay] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let viewModel: any CalendarViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Caching

    private var _cachedCurrentMonth: String?
    private var _cachedCurrentYear: Int?
    private var _cachedHasSelectedDates: Bool?
    private var _lastCalendarDaysCount: Int = 0

    @MainActor
    init(viewModel: any CalendarViewModelProtocol, autoLoad: Bool = false) {
        self.viewModel = viewModel
        setupBindings()
        if autoLoad {
            viewModel.load()
        }
    }
    
    private func setupBindings() {
        viewModel.calendarDaysPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] days in
                self?.calendarDays = days
                self?.isLoading = false
                // Инвалидируем кеш при изменении данных
                self?.invalidateCaches()
            }
            .store(in: &cancellables)
    }

    /// Инвалидирует все кеши
    private func invalidateCaches() {
        _cachedCurrentMonth = nil
        _cachedCurrentYear = nil
        _cachedHasSelectedDates = nil
        _lastCalendarDaysCount = calendarDays.count
    }

    // MARK: - Computed Properties для производительности

    /// Сегодняшняя дата (кешируется на уровне адаптера)
    private var today: Date {
        viewModel.today
    }

    /// Текущий месяц в формате даты
    private var currentMonthDate: Date {
        viewModel.currentMonth
    }
    
    deinit {
        cancellables.removeAll()
    }

    // MARK: - Public Methods
    
    /// Выбирает указанную дату в календаре
    /// - Parameter date: Дата для выбора
    func select(_ date: Date) {
        viewModel.select(date)
    }

    /// Очищает все выбранные даты
    func clear() {
        viewModel.clear()
    }

    /// Изменяет текущий месяц на указанное количество месяцев
    /// - Parameter delta: Количество месяцев для изменения (положительное - вперед, отрицательное - назад)
    func changeMonth(by delta: Int) {
        isLoading = true
        viewModel.changeMonth(by: delta)
    }

    /// Проверяет, выбрана ли указанная дата
    /// - Parameter date: Дата для проверки
    /// - Returns: true, если дата выбрана
    func isDateSelected(_ date: Date) -> Bool {
        viewModel.isDateSelected(date)
    }

    /// Проверяет, находится ли дата в выбранном диапазоне
    /// - Parameter date: Дата для проверки
    /// - Returns: true, если дата в диапазоне
    func isDateInRange(_ date: Date) -> Bool {
        viewModel.isDateInRange(date)
    }
    
    /// Обновляет данные календаря
    func refresh() {
        isLoading = true
        viewModel.load()
        // isLoading будет сброшен в false через binding в setupBindings()
    }

    /// Асинхронно обновляет данные календаря
    /// - Throws: Ошибки загрузки данных
    @MainActor
    func refreshAsync() async throws {
        isLoading = true
        try await viewModel.loadAsync()
        // isLoading будет сброшен в false через binding в setupBindings()
    }

    // MARK: - Computed Properties

    /// Текущий месяц в формате строки
    var currentMonth: String {
        if let cached = _cachedCurrentMonth {
            return cached
        }
        let result = viewModel.monthFormatter.string(from: currentMonthDate)
        _cachedCurrentMonth = result
        return result
    }

    /// Текущий год
    var currentYear: Int {
        if let cached = _cachedCurrentYear {
            return cached
        }
        let result = viewModel.calendar.component(.year, from: currentMonthDate)
        _cachedCurrentYear = result
        return result
    }

    /// Есть ли выбранные даты (оптимизированная версия)
    var hasSelectedDates: Bool {
        if let cached = _cachedHasSelectedDates, _lastCalendarDaysCount == calendarDays.count {
            return cached
        }
        // Используем hasSelectedDates из ViewModel вместо фильтрации массива
        let result = viewModel.hasSelectedDates
        _cachedHasSelectedDates = result
        return result
    }
}
