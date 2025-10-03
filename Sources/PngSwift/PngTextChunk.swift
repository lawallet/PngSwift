//
//  PngTextChunk.swift
//  PngSwift
//
//  Created by Richard Perry on 6/28/24.
//

import Foundation

class PngTextChunk {
    var keyword: String
    var textData: Data
    
    init(keyword: String, textData: Data) {
        self.keyword = keyword
        self.textData = textData
    }
    
    // Todo: Add Logic in case malformed data causes read to go beyond length
    convenience init(data: Data) {
        var dataLoc = 1
        var textName: [UInt8] = []
        // In tEXt data the keyword can be up to 79 characters long and is separated from the text by a null (0) byte
        for byte in data {
            if byte == 0 {
                break
            }
            dataLoc += 1
            textName.append(byte)
        }
        
        let textDat = Data(data.dropFirst(dataLoc))
        let data = Data(textName)
        let keyword = String(data: data, encoding: .utf8) ?? ""
        self.init(keyword: keyword, textData: textDat)
    }
}
