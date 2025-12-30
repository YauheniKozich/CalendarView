//
//  UserDefaultsDateStorage.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

/// Реализация DateStorage для UserDefaults
internal final class UserDefaultsDateStorage: DateStorage {
    private let key: String
    private let defaults: UserDefaults
    
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    public init(key: String = "selectedDates", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    public func save(_ dates: [Date]) throws {
        guard !dates.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        let data = try Self.encoder.encode(dates)
        defaults.set(data, forKey: key)
    }

    public func load() throws -> [Date] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        return try Self.decoder.decode([Date].self, from: data)
    }

    public func saveAsync(_ dates: [Date]) async throws {
        try await Task.detached { [key, defaults] in
            guard !dates.isEmpty else {
                defaults.removeObject(forKey: key)
                return
            }
            let data = try Self.encoder.encode(dates)
            defaults.set(data, forKey: key)
        }.value
    }

    public func loadAsync() async throws -> [Date] {
        return try await Task.detached { [key, defaults] in
            guard let data = defaults.data(forKey: key) else {
                return []
            }
            return try Self.decoder.decode([Date].self, from: data)
        }.value
    }
}

