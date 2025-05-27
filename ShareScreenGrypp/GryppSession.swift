
import Foundation

struct GryppSession: Codable {
    let sessionCode: String
    let apiKey: String
    let sessionId: String
    let customerToken: String
    
    enum CodingKeys: String, CodingKey {
        case sessionCode
        case apiKey
        case sessionId
        case customerToken
    }
}


