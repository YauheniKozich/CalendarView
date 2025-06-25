//
//  SelectedDatesStorage.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

protocol SelectedDatesStorage {
    func save(_ dates: [Date])
    func load() -> [Date]
}

final class UserDefaultsSelectedDatesStorage: SelectedDatesStorage {
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
            print("Failed to encode dates for saving: \(error)")
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
            print("Failed to decode dates from storage: \(error)")
            return []
        }
    }
}
