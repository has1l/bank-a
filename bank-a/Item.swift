//
//  Item.swift
//  bank-a
//
//  Created by Родион Милосердов on 12.06.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
