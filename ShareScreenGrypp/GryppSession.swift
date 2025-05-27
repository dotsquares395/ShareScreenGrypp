//
//  Untitled.swift
//  GryppSDk
//
//  Created by Hemraj Yogi on 12/05/25.
//
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


