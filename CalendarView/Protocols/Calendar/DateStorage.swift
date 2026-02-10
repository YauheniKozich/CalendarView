 import Foundation

/// Протокол для абстракции хранения дат
/// Позволяет использовать разные хранилища (UserDefaults, Keychain, CoreData, сеть и т.д.)
protocol DateStorage {
    /// Сохранить массив дат (синхронно)
    func save(_ dates: [Date]) throws

    /// Загрузить массив дат (синхронно)
    func load() throws -> [Date]

    /// Сохранить массив дат (асинхронно)
    func saveAsync(_ dates: [Date]) async throws

    /// Загрузить массив дат (асинхронно)
    func loadAsync() async throws -> [Date]
}
