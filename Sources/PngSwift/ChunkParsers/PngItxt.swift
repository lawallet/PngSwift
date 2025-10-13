//
//  PngItxt.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public class PngItxt: PngSection, Populatable {
    private(set) var dataValid: Bool = false

    public private(set) var keyword: String?
    public private(set) var compressionFlag: UInt8?
    public private(set) var compressionMethod: UInt8?
    public private(set) var languageTag: String?
    public private(set) var translatedKeyword: String?
    public private(set) var text: Data?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        
        var nameEnd = 0
        var nameArray: [UInt8] = []
        for byte in data {
            // Is character in latin set
            if byte == 0 {
                break
            }
            if (byte >= 33 && byte <= 126) || (byte >= 161 && byte <= 255) || byte == 32 {
                if nameEnd == 79 {
                    return
                }
                
                if nameEnd == 0 && byte == 32 {
                    // No leading spaces allowed
                    return
                } else {
                    nameArray.append(byte)
                }
                nameEnd += 1
            }
        }
        if nameArray.count == 0 {
            return
        }
        guard let profileName = String(bytes: nameArray, encoding: .isoLatin1) else { return }
        self.keyword = profileName
        if nameEnd == data.count {
            return
        }
        nameEnd += 1
        if nameEnd >= data.count {
            return
        }
        
        let compressionFlagData = data[nameEnd..<nameEnd + 1]
        compressionFlagData.withUnsafeBytes { ptr in
            self.compressionFlag = ptr.load(as: UInt8.self)
        }
        if nameEnd + 1 >= data.count {
            return
        }
        nameEnd += 1
        
        let compressionMethodData = data[nameEnd..<nameEnd + 1]
        compressionMethodData.withUnsafeBytes { ptr in
            self.compressionMethod = ptr.load(as: UInt8.self)
        }
        if nameEnd + 1 >= data.count { return }
        nameEnd += 1
        if data[nameEnd] != 0 {
            var languageData: [UInt8] = []
            for byte in data[nameEnd...] {
                if byte == 0 {
                    break
                }
                languageData.append(byte)
                nameEnd += 1
            }
            guard let langString = String(bytes: languageData, encoding: .ascii) else { return }
            self.languageTag = langString
        }
        if nameEnd + 1 >= data.count { return }
        nameEnd += 1
        if data[nameEnd] != 0 {
            var translatedData: [UInt8] = []
            for byte in data[nameEnd...] {
                if byte == 0 {
                    break
                }
                translatedData.append(byte)
                nameEnd += 1
            }
            guard let translatedKeywordString = String(bytes: translatedData, encoding: .utf8) else { return }
            self.translatedKeyword = translatedKeywordString
        }
        
        nameEnd += 1
        if nameEnd < data.count - 1{
            self.text = data[nameEnd...]
        }
        self.dataValid = true
    }
}
