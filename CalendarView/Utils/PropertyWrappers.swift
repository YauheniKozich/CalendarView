 import Foundation

/// Property wrapper для кеширования вычисляемых значений
@propertyWrapper
struct Cached<T> {
    private var cachedValue: T?
    private let compute: () -> T

    init(wrappedValue: @escaping @autoclosure () -> T) {
        self.compute = wrappedValue
    }

    var wrappedValue: T {
        mutating get {
            if let cached = cachedValue {
                return cached
            }
            let value = compute()
            cachedValue = value
            return value
        }
        set {
            cachedValue = newValue
        }
    }

    /// Очищает кеш
    mutating func invalidate() {
        cachedValue = nil
    }
}

/// Property wrapper для валидации значений
@propertyWrapper
struct Validated<T> {
    private var value: T
    private let validator: (T) -> Bool
    private let errorMessage: String

    init(wrappedValue: T, validator: @escaping (T) -> Bool, errorMessage: String = "Invalid value") {
        self.value = wrappedValue
        self.validator = validator
        self.errorMessage = errorMessage
    }

    var wrappedValue: T {
        get { value }
        set {
            guard validator(newValue) else {
                Logger.warning("Validation failed for value: \(errorMessage)", category: .general)
                return
            }
            value = newValue
        }
    }
}

/// Property wrapper для clamped значений (ограничение диапазона)
@propertyWrapper
struct Clamped<T: Comparable> {
    private var value: T
    private let range: ClosedRange<T>

    init(wrappedValue: T, range: ClosedRange<T>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: T {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

/// Property wrapper для логирования изменений
@propertyWrapper
struct Logged<T> {
    private var value: T
    private let label: String

    init(wrappedValue: T, label: String = "") {
        self.value = wrappedValue
        self.label = label
    }

    var wrappedValue: T {
        get { value }
        set {
            Logger.debug("Property '\(label)' changed from '\(value)' to '\(newValue)'", category: .general)
            value = newValue
        }
    }
}

/// Property wrapper для ленивого кеширования вычисляемых значений
@propertyWrapper
struct LazyCached<T> {
    private var cachedValue: T?
    private let compute: () -> T

    init(wrappedValue: @escaping @autoclosure () -> T) {
        self.compute = wrappedValue
    }

    var wrappedValue: T {
        mutating get {
            if let cached = cachedValue {
                return cached
            }
            let value = compute()
            cachedValue = value
            return value
        }
        set {
            cachedValue = newValue
        }
    }

    /// Очищает кеш
    mutating func invalidate() {
        cachedValue = nil
    }
}

/// Структура для кеширования значений по ключу
struct CachedByKey<T, Key: Hashable> {
    private var cache: [Key: T] = [:]
    private let compute: (Key) -> T

    init(compute: @escaping (Key) -> T) {
        self.compute = compute
    }

    /// Получает значение для ключа (с кешированием)
    mutating func value(for key: Key) -> T {
        if let cached = cache[key] {
            return cached
        }
        let value = compute(key)
        cache[key] = value
        return value
    }

    /// Очищает весь кеш
    mutating func clear() {
        cache.removeAll()
    }

    /// Удаляет значение для конкретного ключа
    mutating func remove(_ key: Key) {
        cache.removeValue(forKey: key)
    }

    /// Проверяет, есть ли значение в кеше
    func hasValue(for key: Key) -> Bool {
        cache[key] != nil
    }
}
