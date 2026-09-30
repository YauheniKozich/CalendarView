 import Foundation

/// Протокол для абстракции хранения дат
/// Позволяет использовать разные хранилища (UserDefaults, Keychain, CoreData, сеть и т.д.)
protocol DateStorage {
    func save(_ dates: [Date]) throws
    func load() throws -> [Date]
}
