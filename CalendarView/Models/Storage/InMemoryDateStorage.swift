//
//  InMemoryDateStorage.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

/// Реализация DateStorage для памяти (для тестирования)
/// Thread-safe реализация с использованием NSLock для синхронизации
final class InMemoryDateStorage: DateStorage {
    private var storage: [Date] = []
    private let lock = NSLock()

    public init(initialDates: [Date] = []) {
        self.storage = initialDates
    }

    public func save(_ dates: [Date]) throws {
        lock.lock()
        defer { lock.unlock() }
        storage = dates
    }

    public func load() throws -> [Date] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    public func saveAsync(_ dates: [Date]) async throws {
        try await Task { @MainActor [weak self] in
            guard let self = self else { return }
            try self.save(dates)
        }.value
    }

    public func loadAsync() async throws -> [Date] {
        return try await Task { @MainActor [weak self] in
            guard let self = self else { return [] }
            return try self.load()
        }.value
    }
}

