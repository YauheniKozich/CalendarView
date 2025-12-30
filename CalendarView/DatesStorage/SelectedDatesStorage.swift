//
//  SelectedDatesStorage.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

// MARK: - Logger

internal protocol SelectedDatesStorage {
    func save(_ dates: [Date])
    func load() -> [Date]
}

internal final class UserDefaultsSelectedDatesStorage: SelectedDatesStorage {
    private let key = "selectedDates"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ dates: [Date]) {
        guard !dates.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(dates)
            defaults.set(data, forKey: key)
        } catch {
            Logger.error("Failed to encode dates for saving. Error: \(error.localizedDescription)", category: .storage)
            // В production можно добавить crash reporting или другие механизмы обработки ошибок
        }
    }

    func load() -> [Date] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        do {
            let dates = try JSONDecoder().decode([Date].self, from: data)
            return dates
        } catch {
            Logger.error("Failed to decode dates from storage. Error: \(error.localizedDescription). Returning empty array.", category: .storage)
            // В production можно добавить fallback логику или очистку поврежденных данных
            return []
        }
    }
}
