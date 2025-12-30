//
//  DateFormatterProviderImpl.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

/// Реализация DateFormatterProvider на основе DateFormatter
/// Thread-safe реализация с использованием NSLock, так как DateFormatter не thread-safe
public final class DateFormatterProviderImpl: DateFormatterProvider {
    private let formatter: DateFormatter
    private let lock = NSLock()

    public init(locale: Locale = .current, dateFormat: String? = nil) {
        self.formatter = DateFormatter()
        self.formatter.locale = locale
        self.formatter.dateFormat = dateFormat
    }

    public func string(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return formatter.string(from: date)
    }

    public func string(from date: Date, format: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let originalFormat = formatter.dateFormat
        defer { formatter.dateFormat = originalFormat }

        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    public var locale: Locale? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return formatter.locale
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            formatter.locale = newValue
        }
    }

    public var dateFormat: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return formatter.dateFormat
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            formatter.dateFormat = newValue
        }
    }
}

