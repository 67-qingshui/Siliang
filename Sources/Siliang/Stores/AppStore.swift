import Foundation
import Observation

// Persisted file wrapper for a collection of records (includes tombstones).
struct StoreFile<T: Record>: Codable {
    var version: Int = 1
    var records: [T]
}

@MainActor
@Observable
final class AppStore {
    // MARK: Raw tables (include tombstones for LWW sync)
    private var memberTable: [UUID: Member] = [:]
    private var expenseTable: [UUID: SplitExpense] = [:]
    private var repaymentTable: [UUID: Repayment] = [:]
    private var planTable: [UUID: PointsPlan] = [:]
    private var pointTable: [UUID: PointsRecord] = [:]
    private var itemTable: [UUID: Item] = [:]
    private var tokenTable: [UUID: TokenRecord] = [:]
    private var userTable: [UUID: UserRecord] = [:]

    // MARK: Config + session
    private(set) var config: AppConfig
    private(set) var sessionUsername: String?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let sessionKey = "siliang.session.username"

    // MARK: Init

    init() {
        self.config = Self.loadConfig()
        self.memberTable = Self.load("members.json")
        self.expenseTable = Self.load("expenses.json")
        self.repaymentTable = Self.load("repayments.json")
        self.planTable = Self.load("plans.json")
        self.pointTable = Self.load("points.json")
        self.itemTable = Self.load("items.json")
        self.tokenTable = Self.load("tokens.json")
        self.userTable = Self.load("users.json")
        self.sessionUsername = defaults.string(forKey: sessionKey)
    }

    // MARK: Storage paths (shared, non-isolated so decoding can run before self is set)

    static func storageDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Siliang", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func localURL(_ name: String) -> URL { Self.storageDir().appendingPathComponent(name) }
    private func configURL() -> URL { Self.storageDir().appendingPathComponent("config.json") }

    private static func load<T: Record>(_ name: String) -> [UUID: T] {
        let url = storageDir().appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url),
              let f = try? JSONDecoder().decode(StoreFile<T>.self, from: data) else { return [:] }
        var d: [UUID: T] = [:]
        for r in f.records { d[r.id] = r }
        return d
    }

    private func save<T: Record>(_ table: [UUID: T], _ name: String) {
        let url = localURL(name)
        guard let data = try? JSONEncoder().encode(StoreFile(records: Array(table.values))) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func loadConfig() -> AppConfig {
        let url = storageDir().appendingPathComponent("config.json")
        if let data = try? Data(contentsOf: url), let c = try? JSONDecoder().decode(AppConfig.self, from: data) {
            return c
        }
        return AppConfig()
    }

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configURL(), options: .atomic)
        }
    }

    // MARK: Generic helpers

    private func active<T: Record>(_ t: [UUID: T]) -> [T] {
        t.values.filter { !$0.deleted }.sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    private func upsert<T: Record>(_ r: T, _ t: inout [UUID: T]) -> Bool {
        if let existing = t[r.id], existing.updatedAt > r.updatedAt { return false }
        t[r.id] = r
        return true
    }

    // MARK: Active collections (observable)

    var members: [Member] { active(memberTable) }
    var expenses: [SplitExpense] { active(expenseTable) }
    var repayments: [Repayment] { active(repaymentTable) }
    var plans: [PointsPlan] { active(planTable) }
    var points: [PointsRecord] { active(pointTable) }
    var items: [Item] { active(itemTable) }
    var tokens: [TokenRecord] { active(tokenTable) }
    var users: [UserRecord] { active(userTable) }

    func member(id: UUID?) -> Member? {
        guard let id else { return nil }
        return memberTable[id].flatMap { $0.deleted ? nil : $0 }
    }

    /// 显示用成员名: 即使成员已删除也返回名字, 避免历史记录出现 "?".
    func memberName(_ id: UUID?, deletedFallback: String) -> String {
        guard let id else { return deletedFallback }
        if let m = memberTable[id] { return m.name }
        return deletedFallback
    }

    // MARK: Config accessors

    var language: AppLanguage {
        get { config.language }
        set { var c = config; c.language = newValue; config = c; saveConfig() }
    }

    var recoveryKey: String { config.recoveryKey }

    var syncFolderPath: String? { config.syncFolderPath }
    var syncFolderURL: URL? {
        guard let p = config.syncFolderPath else { return nil }
        return URL(fileURLWithPath: p)
    }

    func setSyncFolder(_ path: String?) {
        var c = config
        c.syncFolderPath = path
        config = c
        if let path {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
        saveConfig()
    }

    // MARK: Session / auth

    var isInitialized: Bool { userTable.values.contains { !$0.deleted && $0.role == .admin } }
    var isLoggedIn: Bool { currentUser != nil }

    var currentUser: UserRecord? {
        guard let name = sessionUsername else { return nil }
        return userTable.values.first { !$0.deleted && $0.username == name }
    }

    private func persistSession() {
        defaults.set(sessionUsername, forKey: sessionKey)
    }

    func login(username: String, password: String) -> Bool {
        guard let u = userTable.values.first(where: { !$0.deleted && $0.username == username }),
              Crypto.verify(password, salt: u.salt, expected: u.passwordHash) else { return false }
        sessionUsername = username
        persistSession()
        return true
    }

    func logout() {
        sessionUsername = nil
        persistSession()
    }

    /// Returns the generated recovery key.
    @discardableResult
    func createAdmin(username: String, password: String) -> String {
        let salt = Crypto.randomSalt()
        let u = UserRecord(username: username, passwordHash: Crypto.hash(password, salt: salt), salt: salt, role: .admin)
        var t = userTable; upsert(u, &t); userTable = t; save(t, "users.json")

        let key = Crypto.generateRecoveryKey()
        var c = config; c.recoveryKey = key; config = c; saveConfig()

        sessionUsername = username
        persistSession()
        return key
    }

    func resetPassword(recoveryKey: String, newPassword: String) -> Bool {
        guard !config.recoveryKey.isEmpty, recoveryKey == config.recoveryKey else { return false }
        guard let admin = userTable.values.first(where: { !$0.deleted && $0.role == .admin }) else { return false }
        let salt = Crypto.randomSalt()
        var u = admin
        u.salt = salt
        u.passwordHash = Crypto.hash(newPassword, salt: salt)
        u.updatedAt = .now
        var t = userTable; upsert(u, &t); userTable = t; save(t, "users.json")
        return true
    }

    /// Regenerate recovery key (admin only).
    @discardableResult
    func regenerateRecoveryKey() -> String {
        let key = Crypto.generateRecoveryKey()
        var c = config; c.recoveryKey = key; config = c; saveConfig()
        return key
    }

    // MARK: User management (admin)

    @discardableResult
    func addUser(username: String, password: String, role: Role) -> Bool {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !userTable.values.contains(where: { !$0.deleted && $0.username == username }) else { return false }
        let salt = Crypto.randomSalt()
        let u = UserRecord(username: username, passwordHash: Crypto.hash(password, salt: salt), salt: salt, role: role)
        var t = userTable; t[u.id] = u; userTable = t; save(t, "users.json")
        return true
    }

    func removeUser(id: UUID) {
        var t = userTable
        guard var u = t[id] else { return }
        u.deleted = true; u.updatedAt = .now
        t[id] = u
        userTable = t
        if sessionUsername == u.username { sessionUsername = nil; persistSession() }
        save(t, "users.json")
    }

    func setRole(id: UUID, role: Role) {
        var t = userTable
        guard var u = t[id] else { return }
        u.role = role; u.updatedAt = .now
        t[id] = u; userTable = t
        save(t, "users.json")
    }

    func changePassword(id: UUID, newPassword: String) {
        var t = userTable
        guard var u = t[id], !newPassword.isEmpty else { return }
        let salt = Crypto.randomSalt()
        u.salt = salt
        u.passwordHash = Crypto.hash(newPassword, salt: salt)
        u.updatedAt = .now
        t[id] = u; userTable = t
        save(t, "users.json")
    }

    // MARK: Members (割り勘)

    @discardableResult
    func addMember(name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return false }
        var t = memberTable
        let m = Member(name: n)
        upsert(m, &t); memberTable = t
        save(t, "members.json")
        return true
    }

    func removeMember(id: UUID) {
        var t = memberTable
        guard var m = t[id] else { return }
        m.deleted = true; m.updatedAt = .now
        t[id] = m; memberTable = t
        save(t, "members.json")
    }

    // MARK: Expenses (割り勘)

    func addExpense(_ e: SplitExpense) {
        var t = expenseTable
        upsert(e, &t); expenseTable = t
        save(t, "expenses.json")
    }

    func removeExpense(id: UUID) {
        var t = expenseTable
        guard var e = t[id] else { return }
        e.deleted = true; e.updatedAt = .now
        t[id] = e; expenseTable = t
        save(t, "expenses.json")
    }

    // MARK: Repayments

    func addRepayment(_ r: Repayment) {
        var t = repaymentTable
        upsert(r, &t); repaymentTable = t
        save(t, "repayments.json")
    }

    func removeRepayment(id: UUID) {
        var t = repaymentTable
        guard var r = t[id] else { return }
        r.deleted = true; r.updatedAt = .now
        t[id] = r; repaymentTable = t
        save(t, "repayments.json")
    }

    // MARK: Points plans

    @discardableResult
    func addPlan(name: String) -> PointsPlan? {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return nil }
        let p = PointsPlan(name: n)
        var t = planTable
        upsert(p, &t); planTable = t
        save(t, "plans.json")
        return p
    }

    func removePlan(id: UUID) {
        var t = planTable
        guard var p = t[id] else { return }
        p.deleted = true; p.updatedAt = .now
        t[id] = p; planTable = t
        save(t, "plans.json")
    }

    // MARK: Points records

    func addPoints(_ r: PointsRecord) {
        var t = pointTable
        upsert(r, &t); pointTable = t
        save(t, "points.json")
    }

    func removePoints(id: UUID) {
        var t = pointTable
        guard var r = t[id] else { return }
        r.deleted = true; r.updatedAt = .now
        t[id] = r; pointTable = t
        save(t, "points.json")
    }

    // MARK: Items

    func addItem(_ i: Item) {
        var t = itemTable
        upsert(i, &t); itemTable = t
        save(t, "items.json")
    }

    func updateItem(_ i: Item) {
        var u = i; u.updatedAt = .now
        var t = itemTable
        upsert(u, &t); itemTable = t
        save(t, "items.json")
    }

    func removeItem(id: UUID) {
        var t = itemTable
        guard var i = t[id] else { return }
        i.deleted = true; i.updatedAt = .now
        t[id] = i; itemTable = t
        save(t, "items.json")
    }

    // MARK: Tokens

    func addToken(_ r: TokenRecord) {
        var t = tokenTable
        upsert(r, &t); tokenTable = t
        save(t, "tokens.json")
    }

    func removeToken(id: UUID) {
        var t = tokenTable
        guard var r = t[id] else { return }
        r.deleted = true; r.updatedAt = .now
        t[id] = r; tokenTable = t
        save(t, "tokens.json")
    }

    // MARK: Sync (LWW + tombstone)

    func syncAll() {
        guard let dir = syncFolderURL else { return }
        memberTable = syncTable(memberTable, "members.json", dir)
        expenseTable = syncTable(expenseTable, "expenses.json", dir)
        repaymentTable = syncTable(repaymentTable, "repayments.json", dir)
        planTable = syncTable(planTable, "plans.json", dir)
        pointTable = syncTable(pointTable, "points.json", dir)
        itemTable = syncTable(itemTable, "items.json", dir)
        tokenTable = syncTable(tokenTable, "tokens.json", dir)
        userTable = syncTable(userTable, "users.json", dir)

        save(memberTable, "members.json")
        save(expenseTable, "expenses.json")
        save(repaymentTable, "repayments.json")
        save(planTable, "plans.json")
        save(pointTable, "points.json")
        save(itemTable, "items.json")
        save(tokenTable, "tokens.json")
        save(userTable, "users.json")
    }

    private func syncTable<T: Record>(_ table: [UUID: T], _ name: String, _ dir: URL) -> [UUID: T] {
        let url = dir.appendingPathComponent(name)
        var t = table
        if let data = try? Data(contentsOf: url),
           let f = try? JSONDecoder().decode(StoreFile<T>.self, from: data) {
            for r in f.records { upsert(r, &t) }
        }
        if let data = try? JSONEncoder().encode(StoreFile(records: Array(t.values))) {
            try? data.write(to: url, options: .atomic)
        }
        return t
    }
}