//
//  SelectedDatesStorage.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

// SelectedDatesStorage.swift
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
        let intervals = dates.map { $0.timeIntervalSince1970 }
        defaults.set(intervals, forKey: key)
    }

    func load() -> [Date] {
        guard let intervals = defaults.array(forKey: key) as? [Double] else {
            return []
        }
        return intervals.map { Date(timeIntervalSince1970: $0) }
    }
}
