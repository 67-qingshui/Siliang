import Foundation
import CryptoKit

enum Crypto {
    static func randomSalt() -> Data {
        Data((0..<16).map { _ in UInt8.random(in: 0...255) })
    }

    static func hash(_ password: String, salt: Data) -> Data {
        let input = salt + Data(password.utf8)
        return Data(SHA256.hash(data: input))
    }

    static func verify(_ password: String, salt: Data, expected: Data) -> Bool {
        hash(password, salt: salt) == expected
    }

    /// 32-char uppercase recovery key.
    static func generateRecoveryKey() -> String {
        let a = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let b = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String((a + b).prefix(32)).uppercased()
    }
}