//
//  KYCExtensions.swift
//  eKYC
//
//  Created by Joy Sebastian on 17/09/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import Foundation

// MARK: - String
extension String {
    
    func date(with format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format //"yyyy-MM-dd'T'HH:mm:ssXXX"
        
        if let date = dateFormatter.date(from: self) {
            return date
        }
        return nil
    }
    
    func cardValidity() -> CardValidity {
        switch self {
        case "Valid":
            return .valid
        case "Invalid":
            return .invalid
        default:
            return .unknown
        }
    }
    
    func cardType() -> CardType {
        switch self {
        case "Citizen_ID":
            return .citizenId
        case "National_ID_12":
            return .nationalId12
        case "National_ID_9":
            return .nationalId9
        case "Empty":
            return .empty
        default:
            return .unknown
        }
    }
}

// MARK: - Date
extension Date {
    
    func dateString(with format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - Dictionary
extension Dictionary {
    
    func toJsonString() -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]),
            let json = String(data: jsonData, encoding: String.Encoding.utf8) {
            return json
        }
        return ""
    }
}
