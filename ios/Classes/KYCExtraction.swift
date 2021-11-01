//
//  KYCExtraction.swift
//  MSB
//
//  Created by Joy Sebastian on 03/09/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import Foundation
import eKYC
import MLKit

class KYCExtraction {
    
    /// Last front card type processed
    /// Used to compare with the back card
    static var cardType = CardType.unknown
    
    static var dobFromCard: Date?
    
    /// Extracts card details from card image
    /// - Parameters:
    ///   - cardFace: card face going to extract
    ///   - cardImage: id card image for extraction
    ///   - completionHandler: extraction result after completion
    static func extractCardDetails(_ cardFace: CardFace, and cardImage: UIImage, completionHandler: @escaping (_ result: KYCExtractionResult) -> Void ) {
        switch cardFace {
        case .front: // Front side
            extractCardFront(from: cardImage, completionHandler: { (result) in
                completionHandler(result)
            })
        case .back: // Back side
            extractCardBack(from: cardImage, completionHandler: { (result) in
                completionHandler(result)
            })
        }
    }
    
    fileprivate static func extractCardFront(from card: UIImage, completionHandler: @escaping (_ result: KYCExtractionResult) -> Void) {
        let textRecognizer = TextRecognizer.textRecognizer()
        let visionImage = VisionImage(image: card)
        textRecognizer.process(visionImage) { features, error in
            
            var extracted = KYCExtractionResult(cardImage: card, result: [:], jsonString: "", selectedCardFace: .front, cardType: .unknown, cardValidity: .unknown, error: nil)
            guard error == nil, let text = features else {
                let errorString = error?.localizedDescription ?? "Detection failed"
                print("Text recognizer failed with error: \(errorString)")
                extracted.error = error
                completionHandler(extracted)
                return
            }
            
            var result = self.processResult(from: text)
            
            let cardTypeString: String = result["card_type"] ?? ""
            let validityString: String = result["validity"] ?? ""
            let cardNumber: String = result["id_no"] ?? ""
            let gender: String = result["gender"] ?? ""
            let dob: String = result["dob"] ?? ""
            let exp: String = result["expiry_date"] ?? ""
            let cardTypeFound = cardTypeString.cardType()
            
            dobFromCard = dob.date(with: "dd/mm/yyyy")
            
            result["cardnumber_validity"] = "Invalid"
            result["year_validity"] = "Invalid"
            result["card_face"] = "Front"
            
            // Validity checks
            // Gender and dob
            if (cardTypeFound == .citizenId || cardTypeFound == .nationalId12) &&
                !cardNumber.isEmpty &&
                !dob.isEmpty {
                let genderIndex = cardNumber.index(cardNumber.startIndex, offsetBy: 3)
                let yearRange = cardNumber.index(cardNumber.startIndex, offsetBy: 4)...cardNumber.index(cardNumber.startIndex, offsetBy: 5)
                let dobYearRange = dob.index(dob.endIndex, offsetBy: -2)..<dob.endIndex
                let genderCode = cardNumber[genderIndex]
                let yearCode = cardNumber[yearRange]
                let dobCode = dob[dobYearRange]
                
                if (gender == "Nam" && genderCode == "0" && yearCode == dobCode) ||
                    (gender == "Nữ" && genderCode == "1" && yearCode == dobCode) {
                    print("GenderDob check success")
                    result["cardnumber_validity"] = "Valid"
                } else {
                    print("GenderDob check failed")
                }
            }
            
            if cardTypeFound == .citizenId,
               let dobCard = dobFromCard,
               let exDate = exp.date(with: "dd/mm/yyyy") {
                
                let calanderDate1 = Calendar.current.dateComponents([.year], from: dobCard)
                let calanderDate2 = Calendar.current.dateComponents([.year], from: exDate)
                let yDob = calanderDate1.year ?? 0
                let exDate = calanderDate2.year ?? 0
                
                if exDate == yDob + 25 ||
                    exDate == yDob + 40 ||
                    exDate == yDob + 60 {
                    result["year_validity"] = "Valid"
                } else if expLabel58Found(in: text) {
                    result["year_validity"] = "Valid"
                }
            }
            
            extracted.result = result
            extracted.jsonString = result.toJsonString()
            extracted.cardType = cardTypeFound
            extracted.cardValidity = validityString.cardValidity()
            cardType = cardTypeString.cardType()
            
            print(result)
            
            completionHandler(extracted)
        }
    }
    
    fileprivate static func processResult(from text: Text) -> [String: String] {

        print(text.text)
        if text.text.isEmpty {
            return ["card_type" : "Empty"]
        }
        
        let card = cardType(from: text.text)
        
        let dates = extractDates(from: text)
        
        var dataFound = extractNameAndGender(from: text)
        dataFound["card_type"] = card["card_type"]
        dataFound["id_no"] = extractIdNumber(from: text)
        dataFound["dob"] = dates["dob"] ?? ""
        dataFound["expiry_date"] = dates["exp"] ?? ""
        
        if let expDate = dates["exp"] ?? "",
            let date = expDate.date(with: "dd/mm/yyyy") {
            let today = Date()
            
            if today < date {
                dataFound["validity"] = "Valid"
            } else {
                dataFound["validity"] = "Invalid"
            }
            
        } else {
            dataFound["validity"] = "Unknown"
        }
        
        return dataFound
    }
    
    fileprivate static func expLabel58Found(in text: Text) -> Bool {
        
        if text.text.isEmpty {
            return false
        }
        let comps = text.text.components(separatedBy: "\n")
        let exGreater58 = "không thời hạn"
        
        var found = false
        
        for comp in comps {
            if Tools.levenshtein(aStr: comp, bStr: exGreater58) <= 5 {
                found = true
                break
            }
        }
        
        return found
    }
        
    fileprivate static func extractIdNumber(from text: Text) -> String {
        
        let comps = text.text.components(separatedBy: "\n")
        
        if comps.count < 4 {
            return ""
        }
        var idNumber = ""
        for comp in comps {
 
            let id = comp.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if id.count < 9 || id.count > 13 {
                idNumber = ""
            } else if id.count == 13 {
                idNumber = id
                idNumber.remove(at: idNumber.startIndex)
                break
            } else {
                idNumber = id
                break
            }
        }
        
        return idNumber
    }
        
    fileprivate static func extractDates(from text:Text) -> [String: String?] {
        
        var dateText = text.text
        
        dateText = dateText.replacingOccurrences(of: "o", with: "0")
        dateText = dateText.replacingOccurrences(of: "O", with: "0")
        
        if dateText.isEmpty {
            return [:]
        }
        
        var dates: [Date] = []
        
        let range = NSRange(location: 0, length: dateText.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: "\\d{2}[-/]\\d{1,2}[-/]\\d{4}") else {
            return ["dob": "",
                    "exp": ""]
        }
        regex.firstMatch(in: dateText, options: [], range: range)
        let result = regex.matches(in: dateText, options: [], range: range)
        
        if result.count == 1 { // ( Digit id have dob only
            let dt = dateText[Range(result.first!.range, in: dateText)!]
            return ["dob": String(dt)]
        }

        for rg in result {
            
            let dt = dateText[Range(rg.range, in: dateText)!]
            
            if let date = String(dt).date(with: "dd/mm/yyyy") {
                dates.append(date)
            } else if let date = String(dt).date(with: "dd/m/yyyy") {
                dates.append(date)
            }
        }
        
        let datesFound = dates.sorted(by: { $0.compare($1) == .orderedAscending })
        
        return ["dob": datesFound.first?.dateString(with: "dd/mm/yyyy"),
                "exp": datesFound.last?.dateString(with: "dd/mm/yyyy")]
    }
        
    fileprivate static func extractNameAndGender(from text: Text) -> [String: String] {
        let genderMale = "Nam"
        let genderFemale = "Nữ"

        let genderLabel1 = "Giới tính: Nam"
        let genderLabel2 = "Giới tính: NU"
        let nameType1 = "Ho và tén:"
        let nameType2 = "Ho và tên khai sinh:"
        
        let list = text.text.components(separatedBy: "\n")
        var nameFound = ""
        var genderFound = ""
        for name in list {
            
            // Name
            if Tools.levenshtein(aStr: name, bStr: nameType1) <= 3 || Tools.levenshtein(aStr: name, bStr: nameType2) <= 3 {
                let nameLabel = name.components(separatedBy: ":")
                if nameLabel.count > 2 &&
                    nameLabel[1].count > 6 {
                    nameFound = nameLabel[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                } else {
                    if let index = list.firstIndex(of: name){
                        
                        if list[index + 1].count > 6 && !(list[index + 1].contains(":")) {
                            nameFound = list[index + 1]
                        } else if !(list[index - 1].contains(":")) {
                            nameFound = list[index - 1]
                        }
                    }
                }
            }
            
//            print("Name NotProcessed :: " + nameFound)
            // Process name
            nameFound = process(nameFound)
        }
        
        for name in list {
            // Gender
            if Tools.levenshtein(aStr: name, bStr: genderLabel1) <= 3 || Tools.levenshtein(aStr: name, bStr: genderLabel2) <= 3 {
                if let gender = name.components(separatedBy: CharacterSet(charactersIn: ": ")).last,
                    gender != "" {
                    if Tools.levenshtein(aStr: genderMale, bStr: gender) <= 1 {
                        genderFound = genderMale
                    }
                    else if Tools.levenshtein(aStr: genderFemale, bStr: gender) <= 1 {
                        genderFound = genderFemale
                    }
                    else {
                        
                    }
                }
            }
        }
        
        return ["name": nameFound,
                "gender": genderFound]
    }
    
    fileprivate static func getNames() -> String? {
        
        let bundle = Bundle.init(for: KYCIdDetectionView.self)
        if let path = bundle.path(forResource: "names", ofType: "txt"), // file path for file "data.txt"
        let string = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            return string
        }
        return nil
    }
        
    fileprivate static func process(_ name: String) -> String {
        
        let A = "AĂÂÀẰẦÁẮẤẠẶẬÃẴẪẢẲẨĀÄ"
        let E = "EÊÈỀÉẾẸỆẼỄẺỂ"
        let I = "IÌÍỊĨỈĮỊ"
        let O = "OÔƠÒỒỜÓỐỚỌỘỢÕỖỠỎỔỞ"
        let U = "UƯÙỪÚỨỤỰŨỮỦỬ"
        let Y = "YỲÝỴỸỶ"
        let D = "DĐ"
        
        
//        name = name.replacingOccurrences(of: "", with: "")
        let nameParts = name.components(separatedBy: " ")  // nam dfd ere -> ["nam","dfd","ere"]
        var processed : [String] = []
        if let words = getNames() {
            let nameWords = words.components(separatedBy: "\n")
            for namePart in nameParts {
                var nm = namePart
                for nameWord in nameWords { // nam
                    if namePart.count == nameWord.count && Tools.levenshtein(aStr: namePart, bStr: nameWord) < 2 {
                        
                        var proNm = ""
                        var namePartIndex = namePart.startIndex
                        var nameWordIndex = nameWord.startIndex
                        while namePartIndex != namePart.endIndex || nameWordIndex != nameWord.endIndex {
                            
                            let namePartChar = namePart[namePartIndex]
                            let nameWordChar = nameWord[nameWordIndex]
                            
                            if namePartChar == nameWordChar {
                                proNm.insert(namePartChar, at: proNm.endIndex)
                            } else if
                                (A.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (D.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (E.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (I.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (O.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (U.contains(namePartChar) && A.contains(nameWordChar)) ||
                                (Y.contains(namePartChar) && A.contains(nameWordChar)) {
                                proNm.insert(nameWordChar, at: proNm.endIndex)
                            } else {
                                proNm.insert(namePartChar, at: proNm.endIndex)
                            }
                            
                            // Update indexes
                            namePartIndex = namePart.index(after: namePartIndex)
                            nameWordIndex = nameWord.index(after: nameWordIndex)
                        }
                        nm = proNm
                        break
                    } else {
                        nm = namePart
                    }
                }
                
                processed.append(nm)
            }
            return processed.joined(separator: " ")
        }
        return name
    }
    
    fileprivate static func cardType(from data: String) -> [String: String] {
        
        // Empty
        var cardTypeFound = "Empty"
        
        if !data.isEmpty {
            
            // Unknown card
            cardTypeFound = "Unknown_Card"
            let comps = data.components(separatedBy: "\n")
            
            for comp in comps {
                
                if comp.count < 15 || comp.count > 28 {
                    continue
                }
                
                if Tools.levenshtein(aStr: "CHỨNG MINH NHÂN DÂN", bStr: comp) <= 3 {
                    cardTypeFound = "National_ID_12"
                    break
                } else if Tools.levenshtein(aStr: "CĂN CUỚC CÔNG DÂN", bStr: comp) <= 3 {
                    cardTypeFound = "Citizen_ID"
                    break
                } else if Tools.levenshtein(aStr: "GIÂY CHỨNG MINH NHÂN DÂN", bStr: comp) <= 3 {
                    cardTypeFound = "National_ID_9"
                    break
                }
            }
        }
        return ["card_type": cardTypeFound]
    }
    
}

extension KYCExtraction {
    
    fileprivate static func extractCardBack(from card: UIImage, completionHandler: @escaping (_ result: KYCExtractionResult) -> Void) {
        
        let textRecognizer = TextRecognizer.textRecognizer()
        let visionImage = VisionImage(image: card)
        textRecognizer.process(visionImage) { features, error in
            
            var extracted = KYCExtractionResult(cardImage: card, result: [:], jsonString: "", selectedCardFace: .front, cardType: .unknown, cardValidity: .unknown, error: nil)
            
            guard error == nil, let text = features else {
                let errorString = error?.localizedDescription ?? "Detection failed"
                print("Text recognizer failed with error: \(errorString)")
                extracted.error = error
                completionHandler(extracted)
                return
            }
            
            var result = self.extractBackSide(from: text)
            let cardTypeString: String = result["card_type"] ?? ""
            let issueDate: String = result["issue_date"] ?? ""
            let cardTypeFound = cardTypeString.cardType()
            
            result["age_validity"] = "Invalid"
            result["validity"] = "Invalid"
            result["card_face"] = "Back"
            
            // Year check
            if let cardDob = dobFromCard ,
               let issue = issueDate.date(with: "dd/mm/yyyy") {
                let calanderDate1 = Calendar.current.dateComponents([.year], from: cardDob) 
                let calanderDate2 = Calendar.current.dateComponents([.year], from: issue)
                let yDob = calanderDate1.year ?? 0
                let yIssue = calanderDate2.year ?? 0
                
                let cardIssuedAge = yIssue - yDob
                
                if cardIssuedAge > 13 { // valid
                    result["age_validity"] = "Valid"
                } else {
                    
                }
                
            }
                        
            if cardType == cardTypeString.cardType() {
                result["validity"] = "Valid"
            }
            
            if cardType == .nationalId9 && (cardTypeFound == .citizenId || cardTypeFound == .nationalId12) {
                result["validity"] = "Valid"
            }
            
            let validityString: String = result["validity"] ?? ""
            
            extracted.result = result
            extracted.jsonString = result.toJsonString()
            extracted.cardType = cardTypeString.cardType()
            extracted.cardValidity = validityString.cardValidity()
            print(result)
            
            completionHandler(extracted)
        }
    }
    
    fileprivate static func extractBackSide(from text: Text) -> [String: String] {
        
        print(text.text)
        
        let data = text.text
        
        var backSideData: [String:String] = ["validity": "Invalid",
                                       "issue_date": "",
                                       "card_type": "Empty"]
        
        if data.isEmpty {
            return backSideData
        }
        backSideData["card_type"] = "Unknown_Card"
        var cucValid = false
        var dkqlValid = false
        var dacValid = false
        let details = data.components(separatedBy: "\n")
        
        for line in details {
            
            if Tools.levenshtein(aStr: "CỤC TRƯỞNG CỤC CẢNH SẤT", bStr: line) <= 4 {
                cucValid = true
            }
            else if Tools.levenshtein(aStr: "ĐKQL CƯ TRÜ VÀ ĐLQG VẾ DÂN CƯ", bStr: line) <= 7 {
                dkqlValid = true
            }
            else {
                let dac = line.components(separatedBy: CharacterSet(charactersIn: ": "))
                
                if Tools.levenshtein(aStr: "Đặc", bStr: dac[0]) <= 2 &&
                    Tools.levenshtein(aStr: "điểm", bStr: dac[1]) <= 3 &&
                    Tools.levenshtein(aStr: "nhấn", bStr: dac[2]) <= 3 &&
                    Tools.levenshtein(aStr: "dạng", bStr: dac[3]) <= 3 {
                    dacValid = true
                }
            }
        }
        
        print("1 >> \(cucValid) 2 >> \(dkqlValid) 3 >> \(dacValid) ")
        
//        if cucValid && dkqlValid && dacValid {

            var dateArray: [String] = []
            var issueDate = ""

            let range = NSRange(location: 0, length: data.utf16.count)
            guard let regex = try? NSRegularExpression(pattern: "\\d{2,4}") else {
                return backSideData
            }
            regex.firstMatch(in: data, options: [], range: range)
            let result = regex.matches(in: data, options: [], range: range)

            for dt in result {
                let dat = data[Range(dt.range, in: data)!]
                print(dat)
                dateArray.append(String(dat))
            }

            issueDate = dateFrom(dateArray)
            print("issueDate :: " + issueDate)
            
            if let date = issueDate.date(with: "dd/mm/yyyy"),
                let citizenID = "01/01/2016".date(with: "dd/mm/yyyy"),
                let natID12 = "31/12/2015".date(with: "dd/mm/yyyy") {
                
                if date < natID12 {
                    backSideData["validity"] = "Valid"
                    backSideData["issue_date"] = issueDate
                    backSideData["card_type"] = "National_ID_12"
                } else if date > citizenID {
                    backSideData["validity"] = "Valid"
                    backSideData["issue_date"] = issueDate
                    backSideData["card_type"] = "Citizen_ID"
                } else {
                    backSideData["validity"] = "Invalid"
                    backSideData["issue_date"] = ""
                }
            } else {
                backSideData["validity"] = "Invalid"
                backSideData["issue_date"] = ""
                
            }
            return backSideData
//        }
//
//        return backSideData
    }
    
    fileprivate static func dateFrom(_ array: [String]) -> String {
        if array.count < 3 {
            return ""
        }
        var issueArray = array
        
        var yearIndex = 0
        for (i,dt) in issueArray.enumerated() {
            if dt.count == 4 {
                yearIndex = i
            }
        }
        issueArray.append(issueArray.remove(at: yearIndex))
        
        if issueArray.count == 3 {
        }
        else if issueArray.count == 4 {
            issueArray.removeFirst()
        } else {
            return ""
        }
        
        let day = issueArray.first!
        let month = issueArray[1]
        
        if Int(month)! > 12 && Int(day)! <= 12 {
            issueArray.remove(at: 1)
            issueArray.insert(month, at: 0)
        }
        
        return issueArray.joined(separator: "/")
    }
}
