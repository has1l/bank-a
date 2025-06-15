import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let phone: String
    let password_hash: String
    let created_at: String
}