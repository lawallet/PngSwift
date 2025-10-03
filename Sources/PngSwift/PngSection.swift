//
//  PngSection.swift
//  PngSwift
//
//  Created by Richard Perry on 6/28/24.
//

import Foundation

public struct SectionPropertyBits {
    let isCritical: Bool
    let isSafeToCopy: Bool
    let isReserved: Bool
    let isPrivateSection: Bool
}

public class PngSection {
    public private(set) var length: UInt32
    // A 4 byte value. Should read this a byte at a time since PNG specs state you shouldn't read this as a string
    public private(set) var chunkType: PngHeaderTypes
    public private(set) var rawChunkType: String
    public private(set) var chunkData: Data
    public private(set) var CRC: UInt32
    public private(set) var sectionProperties: SectionPropertyBits!
    
    init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32) {
        self.length = length
        self.chunkType = chunkType
        self.rawChunkType = rawChunkType
        self.chunkData = chunkData
        self.CRC = CRC
        
        self.sectionProperties = parsePropertyBits(rawChunkType: rawChunkType)
    }
    
    func parsePropertyBits(rawChunkType: String) -> SectionPropertyBits {
        var isCritical: Bool = false
        var isSafeToCopy: Bool = false
        var isReserved: Bool = false
        var isPrivateSection: Bool = false
        
        for (loc, char) in rawChunkType.enumerated() {
            let asciiValue = char.asciiValue!
            // The fifth bit, 32 spot (0 indexed), is the one to check
            let onlyFifthBit = (asciiValue & 0b00100000) >> 5
            if loc == 0 {
                if onlyFifthBit == 0 {
                    isCritical = true
                }
            } else if loc == 1 {
                if onlyFifthBit == 1 {
                    isPrivateSection = true
                }
                
            } else if loc == 2 {
                if onlyFifthBit == 0 {
                    isReserved = true
                }
                
            } else if loc == 3 {
                if onlyFifthBit == 1 {
                    isSafeToCopy = true
                }
            }
        }
        return SectionPropertyBits(isCritical: isCritical, isSafeToCopy: isSafeToCopy, isReserved: isReserved, isPrivateSection: isPrivateSection)
    }
    
    convenience init?(fileHandle: FileHandle) {
        do {
            guard let chunkLength = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            var endianCorrectedChunkLength: UInt32 = 0
            chunkLength.withUnsafeBytes { rawBytes in
                let needToConvert = rawBytes.load(as: UInt32.self)
                // PNG data is stored in big endian format
                endianCorrectedChunkLength = needToConvert.bigEndian
                
            }
            guard let chunkType = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            for byte in chunkType {
                if byte < 65 || (byte > 90 && byte < 97) || byte > 122 {
                    return nil
                }
            }
            guard let convertedChunkType = String(data: chunkType, encoding: .utf8) else {
                return nil
            }
            let chunk = PngHeaderTypes(rawValue: convertedChunkType) ?? .unknown
            var chunkData: Data
            if endianCorrectedChunkLength > 0 {
                guard let chunkDat = try fileHandle.read(upToCount: Int(endianCorrectedChunkLength)) else {
                    return nil
                }
                chunkData = chunkDat
            } else {
                chunkData = Data()
            }
            guard let crcDat = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            var crcVal: UInt32 = 0
            crcDat.withUnsafeBytes { rawBytes in
                crcVal = rawBytes.load(as: UInt32.self)
            }
            
            self.init(length: endianCorrectedChunkLength, chunkType: chunk, rawChunkType: convertedChunkType, chunkData: chunkData, CRC: crcVal)
                    
        } catch {
            return nil
        }
    }
    
    convenience init?(sectionOffset: PngSectionOffsetInfo?, fileHandle: FileHandle) {
        guard let sectionOffset = sectionOffset else {
            return nil
        }
        do {
            // We already have the first 8 bytes of the section (Length and type) so skip those
            try fileHandle.seek(toOffset: sectionOffset.offset + 8)
            
            var chunkData: Data
            if sectionOffset.SectionLength > 0 {
                guard let chunkDat = try fileHandle.read(upToCount: Int(sectionOffset.SectionLength)) else {
                    return nil
                }
                chunkData = chunkDat
            } else {
                chunkData = Data()
            }
            guard let crcDat = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            var crcVal: UInt32 = 0
            crcDat.withUnsafeBytes { rawBytes in
                crcVal = rawBytes.load(as: UInt32.self)
            }
            let chunk = PngHeaderTypes(rawValue: sectionOffset.type) ?? .unknown
            self.init(length: sectionOffset.SectionLength, chunkType: chunk, rawChunkType: sectionOffset.type, chunkData: chunkData, CRC: crcVal)
        } catch {
            return nil
        }
        
    }
    private func updateCrc() {
        CRC = calculateCrc()
    }
    
    func calculateCrc() -> UInt32 {
        let chunkTypeArr: [UInt8] = Array(rawChunkType.utf8)
        let chunkDataArr: [UInt8] = chunkData.map({ $0 })
        let newCrc = crc(buf: chunkTypeArr + chunkDataArr)
        var chunkBuffer: Data = Data(chunkTypeArr)
        chunkBuffer.append(chunkData)
        return newCrc.bigEndian
    }
    
    static private let crcTable: [UInt32] = {
        
        var table: [UInt32] = []
        var c: UInt32 = 0
        for num:UInt32 in 0..<256 {
            c = num
            for _ in 0..<8 {
                if ((c & 1) != 0) {
                    c = 0xedb88320 ^ (c >> 1)
                } else {
                    c = c >> 1
                }
            }
            table.append(c)
        }
        return table
    }()
    
    private func makeCrc(crc: UInt32, buf: [UInt8]) -> UInt32 {
        var c = crc
        let crcTable = PngSection.crcTable
        
        for num in 0..<buf.count {
            let leftSide: UInt32 = c ^ UInt32(buf[num])
            let fullNum:UInt32 = leftSide & 0xff
            c = crcTable[Int(fullNum)] ^ (c >> 8)
        }
        return c
    }
    
    // Make inout?
    private func makeCrc(crc: UInt32, data: Data) -> UInt32 {
        var c = crc
        let crcTable = PngSection.crcTable
        
        for byte in data {
            let leftSide: UInt32 = c ^ UInt32(byte)
            let fullNum:UInt32 = leftSide & 0xff
            c = crcTable[Int(fullNum)] ^ (c >> 8)
        }
        return c
    }
    
    private func crc(buf: [UInt8]) -> UInt32 {
        return makeCrc(crc: 0xffffffff, buf: buf) ^ 0xffffffff
    }

    
    func createData() -> Data {
        var dataStart = Data()
        let lengthBytes: [UInt8] = withUnsafeBytes(of: length.bigEndian, Array.init)
        let chunkTypeBytes: [UInt8] = Array(rawChunkType.utf8)
        let crcBytes: [UInt8] = withUnsafeBytes(of: CRC, Array.init)
        dataStart.append(contentsOf: lengthBytes + chunkTypeBytes)
        dataStart.append(chunkData)
        dataStart.append(contentsOf: crcBytes)
        return dataStart
    }
    
    public func updateData(with newData: Data) throws {
        if !sectionProperties.isCritical && sectionProperties.isSafeToCopy {
            chunkData = newData
            length = UInt32(newData.count)
            updateCrc()
        } else {
            throw PngPopulatingError.unupdatableSection(unupdatableSection: chunkType.rawValue)
        }
        
    }
}
