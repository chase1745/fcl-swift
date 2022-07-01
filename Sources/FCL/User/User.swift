//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import Cadence

struct User: Decodable {
    var fclType: String = "USER"
    var fclVersion: String = "1.0.0"
    let address: Address
    let cid: String
    var loggedIn: Bool = false
    let expiresAt: TimeInterval
    let services: [Service]

    var expiresAtDate: Date {
        Date(timeIntervalSince1970: expiresAt)
    }

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case cid
        case loggedIn
        case expiresAt
        case services
    }

}