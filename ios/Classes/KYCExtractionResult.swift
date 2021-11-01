//
//  ExtractionResult.swift
//  eKYC
//
//  Created by Joy Sebastian on 17/09/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import Foundation
import UIKit

public struct KYCExtractionResult {
    public var cardImage: UIImage
    public var result: [String: String]
    public var jsonString: String
    public var selectedCardFace: CardFace
    public var cardType: CardType
    public var cardValidity: CardValidity
    public var error: Error?
}

public enum CardType {
    case empty
    case unknown
    case citizenId
    case nationalId12
    case nationalId9
}

public enum CardValidity {
    case valid
    case invalid
    case unknown
}

public enum CardFace {
    case front
    case back
}

