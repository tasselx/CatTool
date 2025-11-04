import Foundation

struct Subscription: Identifiable, Hashable {
    let id: Int
    var name: String
    var url: String
    var description: String?
    let createdAt: String
    let updatedAt: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.id == rhs.id
    }
}

