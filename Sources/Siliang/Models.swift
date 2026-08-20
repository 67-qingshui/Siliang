import Foundation

// MARK: - Common record contract
// Every persisted entity implements Record so it can be stored with
// last-write-wins (LWW) conflict resolution plus tombstones for deletions.

protocol Record: Identifiable, Codable {
    var id: UUID { get set }
    var updatedAt: Date { get set }
    var deleted: Bool { get set }
}

// MARK: - Shared enums

enum Direction: String, Codable, CaseIterable, Identifiable {
    case income, expense
    var id: String { rawValue }
}

enum SplitMode: String, Codable, CaseIterable, Identifiable {
    case equal, custom
    var id: String { rawValue }
}

enum PointsKind: String, Codable, CaseIterable, Identifiable {
    case earned, spent
    var id: String { rawValue }
}

enum Role: String, Codable, CaseIterable, Identifiable {
    case admin, member
    var id: String { rawValue }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case zh, ja
    var id: String { rawValue }
}

// MARK: - Member library (割り勘 / AA book)

struct Member: Record {
    var id: UUID = UUID()
    var name: String
    var updatedAt: Date = .now
    var deleted: Bool = false
}

// MARK: - Split book (割り勘)

struct SplitShare: Codable, Hashable {
    var memberId: UUID
    var amount: Double
}

struct SplitExpense: Record {
    var id: UUID = UUID()
    var title: String
    var amount: Double                 // total, always positive
    var direction: Direction
    var paidBy: UUID                   // member id of the payer
    var splitMode: SplitMode
    var shares: [SplitShare]           // participants (equal or custom amounts)
    var date: Date
    var updatedAt: Date = .now
    var deleted: Bool = false

    func share(for memberId: UUID, memberCount: Int) -> Double? {
        switch splitMode {
        case .equal:
            guard memberCount > 0 else { return nil }
            return amount / Double(memberCount)
        case .custom:
            return shares.first { $0.memberId == memberId }?.amount
        }
    }
}

struct Repayment: Record {
    var id: UUID = UUID()
    var from: UUID   // who pays back
    var to: UUID     // who receives
    var amount: Double
    var date: Date
    var updatedAt: Date = .now
    var deleted: Bool = false
}

// MARK: - Points (积分记录)

struct PointsPlan: Record {
    var id: UUID = UUID()
    var name: String
    var updatedAt: Date = .now
    var deleted: Bool = false
}

struct PointsRecord: Record {
    var id: UUID = UUID()
    var planId: UUID
    var kind: PointsKind
    var amount: Double
    var isPending: Bool
    var expectedDate: Date?   // used only when isPending
    var date: Date
    var memo: String
    var updatedAt: Date = .now
    var deleted: Bool = false
}

// MARK: - Items (物品使用)

enum ItemStatus: String, CaseIterable, Hashable {
    case active, finished
}

struct Item: Record {
    var id: UUID = UUID()
    var name: String
    var category: String
    var startDate: Date
    var endDate: Date?       // nil == 使用中
    var updatedAt: Date = .now
    var deleted: Bool = false

    var status: ItemStatus {
        endDate == nil ? .active : .finished
    }
}

// MARK: - Token usage (Token 使用)

struct TokenRecord: Record {
    var id: UUID = UUID()
    var scenario: String     // 应用场景 (required, most important)
    var model: String        // 模型 (required)
    var apiKey: String       // full value stored locally; masked in UI
    var inputTokens: Int
    var outputTokens: Int
    var cost: Double
    var date: Date
    var updatedAt: Date = .now
    var deleted: Bool = false

    var maskedKey: String {
        guard apiKey.count > 4 else { return String(repeating: "•", count: min(apiKey.count, 8)) }
        let suffix = String(apiKey.suffix(4))
        return "•••• •••• \(suffix)"
    }
}

// MARK: - Users (登录)

struct UserRecord: Record {
    var id: UUID = UUID()
    var username: String
    var passwordHash: Data
    var salt: Data
    var role: Role
    var updatedAt: Date = .now
    var deleted: Bool = false
}

// MARK: - App configuration (recovery key, language, sync folder)

struct AppConfig: Codable {
    var recoveryKey: String = ""
    var language: AppLanguage = .zh
    var syncFolderPath: String? = nil
    var version: Int = 1
}