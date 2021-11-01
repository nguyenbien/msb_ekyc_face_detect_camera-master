//
//  MSBEkycUtils.swift
//  MSB
//
//  Created by Tuyen Topebox on 01/10/20.
//  Copyright © 2020 Topebox. All rights reserved.
//

import Foundation

class MSBEkycUtils {

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    static func currentTimeInMiliseconds() -> Int {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        return Int(since1970 * 1000)
    }

}
