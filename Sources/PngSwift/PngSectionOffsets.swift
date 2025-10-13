//
//  PngSectionOffsets.swift
//  PngSwift
//
//  Created by Richard Perry on 10/2/25.
//

import Foundation

public class PngSectionOffsets {
    public private(set) var ihdrChunk: PngSectionOffsetInfo!
    public private(set) var idatChunk: [PngSectionOffsetInfo] = []
    public private(set) var iendChunk: PngSectionOffsetInfo!
    public private(set) var plteChunk: PngSectionOffsetInfo?
    public private(set) var chrmChunk: PngSectionOffsetInfo?
    public private(set) var gamaChunk: PngSectionOffsetInfo?
    public private(set) var iccpChunk: PngSectionOffsetInfo?
    public private(set) var sbitChunk: PngSectionOffsetInfo?
    public private(set) var srgbChunk: PngSectionOffsetInfo?
    public private(set) var bkgdChunk: PngSectionOffsetInfo?
    public private(set) var histChunk: PngSectionOffsetInfo?
    public private(set) var trnsChunk: PngSectionOffsetInfo?
    public private(set) var physChunk: PngSectionOffsetInfo?
    public private(set) var spltChunk: [PngSectionOffsetInfo]?
    public private(set) var timeChunk: PngSectionOffsetInfo?
    public private(set) var itxtChunk: [PngSectionOffsetInfo]?
    public private(set) var textChunk: [PngSectionOffsetInfo]?
    public private(set) var ztxtChunk: [PngSectionOffsetInfo]?
    public private(set) var nonstandardChunks: [String: PngSectionOffsetInfo] = [:]
    
    weak var headerSection: PngIhdr?
    
    var pngLocation: URL
    
    init(pngPath: URL) throws(PngLoadingError) {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: pngPath)
        } catch {
            throw PngLoadingError.notFound
        }
        defer {
            try? handle.close()
        }
        pngLocation = pngPath
        let endOfFile: UInt64
        let readBytes: Data?
        do {
            endOfFile = try handle.seekToEnd()
            try handle.seek(toOffset: 0)
            readBytes = try handle.read(upToCount: 8)
        } catch {
            throw PngLoadingError.invalidFile
        }
        
        if readBytes?.count ?? 0 < 8 {
            throw PngLoadingError.invalidFile
        }
        let pngHeader:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        let headerData = Data(bytes: pngHeader, count: pngHeader.count)
        if headerData != readBytes {
            throw PngLoadingError.notPng
        }
        guard var currOffset = try? handle.offset() else {
            throw PngLoadingError.invalidFile
        }
        while currOffset < endOfFile {
            let sectionOffset = try partiallyParseSection(fileHandle: handle)
            let sectionType = PngHeaderTypes(rawValue: sectionOffset.type) ?? .unknown
            switch sectionType {
                
            case .IHDR:
                ihdrChunk = sectionOffset
            case .IDAT:
                idatChunk.append(sectionOffset)
            case .IEND:
                iendChunk = sectionOffset
            case.PLTE:
                plteChunk = sectionOffset
            case .cHRM:
                chrmChunk = sectionOffset
            case .gAMA:
                gamaChunk = sectionOffset
            case .iCCP:
                iccpChunk = sectionOffset
            case .sBIT:
                sbitChunk = sectionOffset
            case .sRGB:
                srgbChunk = sectionOffset
            case .bKGD:
                bkgdChunk = sectionOffset
            case .hIST:
                histChunk = sectionOffset
            case .tRNS:
                trnsChunk = sectionOffset
            case .pHYs:
                physChunk = sectionOffset
            case .sPLT:
                if nil == spltChunk {
                    spltChunk = []
                }
                spltChunk?.append(sectionOffset)
            case .tIME:
                timeChunk = sectionOffset
            case .iTXt:
                if nil == itxtChunk {
                    itxtChunk = []
                }
                itxtChunk?.append(sectionOffset)
            case .tEXt:
                if nil == textChunk {
                    textChunk = []
                }
                textChunk?.append(sectionOffset)
            case .zTXt:
                if nil == ztxtChunk {
                    ztxtChunk = []
                }
                ztxtChunk?.append(sectionOffset)
            default:
                nonstandardChunks[sectionOffset.type] = sectionOffset
            
            }
            do {
                currOffset = try handle.offset()
            } catch {
                throw PngLoadingError.invalidFile
            }
            
        }
        // IHDR, IDAT, and IEND chunks are required to be in a PNG
        if ihdrChunk == nil {
            throw PngLoadingError.missingRequiredSection(missingSection: "IHDR")
        } else if  idatChunk.isEmpty {
            throw PngLoadingError.missingRequiredSection(missingSection: "IDAT")
        } else if iendChunk == nil {
            throw PngLoadingError.missingRequiredSection(missingSection: "IEND")
        }
    }
    
    func partiallyParseSection(fileHandle: FileHandle) throws(PngLoadingError) -> PngSectionOffsetInfo {
        var offsetInfo = PngSectionOffsetInfo()
        do {
            offsetInfo.offset = try fileHandle.offset()
        } catch {
            throw PngLoadingError.corrupted
        }
        
        guard let chunkLength = try? fileHandle.read(upToCount: 4) else {
            throw PngLoadingError.corrupted
        }
        var endianCorrectedChunkLength: UInt32 = 0
        chunkLength.withUnsafeBytes { rawBytes in
            let needToConvert = rawBytes.load(as: UInt32.self)
            // PNG data is stored in big endian format
            endianCorrectedChunkLength = needToConvert.bigEndian
            
        }
        offsetInfo.SectionLength = endianCorrectedChunkLength
        
        guard let chunkType = try? fileHandle.read(upToCount: 4) else {
            throw PngLoadingError.corrupted
        }
        for byte in chunkType {
            // Only ascii letters are allowed in section names
            if byte < 65 || (byte > 90 && byte < 97) || byte > 122 {
                throw PngLoadingError.invalidName
            }
        }
        guard let convertedChunkType = String(data: chunkType, encoding: .utf8) else {
            throw PngLoadingError.corrupted
        }
        offsetInfo.type = convertedChunkType
        do {
            // Next section is current offset + the data length + 4 bytes for CRC
            try fileHandle.seek(toOffset: fileHandle.offset() + UInt64(endianCorrectedChunkLength) + 4)
        } catch {
            throw PngLoadingError.malformed(failedSection: convertedChunkType)
        }
        return offsetInfo
    }
    
    func populateDataForSection(type: PngHeaderTypes, nonStandardChunkName: String = "") throws(PngPopulatingError) -> [PngSection] {
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: pngLocation)
        } catch {
            throw PngPopulatingError.fileMissing
        }
        defer {
            try? fileHandle.close()
        }
        if type == .unknown || !nonStandardChunkName.isEmpty {
            guard let unknownOffset = nonstandardChunks[nonStandardChunkName] else {
                throw PngPopulatingError.sectionNotFound
            }
            if !sanityCheckOffset(for: unknownOffset, fileHandle: fileHandle) {
                throw PngPopulatingError.dataDoesNotMatchOriginalData
            }
            guard let nonStandardChunk = PngSection(sectionOffset: unknownOffset, fileHandle: fileHandle) else {
                throw PngPopulatingError.sectionNotFound
            }
            return [nonStandardChunk]
        } else {
            switch type {
            // Required sections
            case .IHDR:
                return try populateData(offset: ihdrChunk, fileHandle: fileHandle)
            
            case .IDAT:
                return try populateDataForMultiSection(offsets: idatChunk, fileHandle: fileHandle)
                
            case .IEND:
                return try populateData(offset: iendChunk, fileHandle: fileHandle)
            // End required sections
            case .PLTE:
                return try populateData(offset: plteChunk, fileHandle: fileHandle)
            case .cHRM:
                return try populateData(offset: chrmChunk, fileHandle: fileHandle)
            case .gAMA:
                return try populateData(offset: gamaChunk, fileHandle: fileHandle)
            case .iCCP:
                return try populateData(offset: iccpChunk, fileHandle: fileHandle)
            case .sBIT:
                return try populateData(offset: sbitChunk, fileHandle: fileHandle)
            case .sRGB:
                return try populateData(offset: srgbChunk, fileHandle: fileHandle)
            case .bKGD:
                return try populateData(offset: bkgdChunk, fileHandle: fileHandle)
            case .hIST:
                return try populateData(offset: histChunk, fileHandle: fileHandle)
            case .tRNS:
                return try populateData(offset: trnsChunk, fileHandle: fileHandle)
            case .pHYs:
                return try populateData(offset: physChunk, fileHandle: fileHandle)
            case .sPLT:
                return try populateDataForMultiSection(offsets: spltChunk, fileHandle: fileHandle)
            case .tIME:
                return try populateData(offset: timeChunk, fileHandle: fileHandle)
            case .iTXt:
                return try populateDataForMultiSection(offsets: itxtChunk, fileHandle: fileHandle)
            case .tEXt:
                return try populateDataForMultiSection(offsets: textChunk, fileHandle: fileHandle)
            case .zTXt:
                return try populateDataForMultiSection(offsets: ztxtChunk, fileHandle: fileHandle)
            case .unknown:
                // This should never happen
                throw PngPopulatingError.sectionNotFound
            }
        }
    }
    
    func populateData(offset: PngSectionOffsetInfo?) throws (PngPopulatingError)-> PngSection {
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: pngLocation)
        } catch {
            throw PngPopulatingError.fileMissing
        }
        defer {
            try? fileHandle.close()
        }
        let sectionArr = try populateData(offset: offset, fileHandle: fileHandle)
        return sectionArr.first!
    }
    
    private func populateData(offset: PngSectionOffsetInfo?, fileHandle: FileHandle) throws(PngPopulatingError) -> [PngSection] {
        guard let offset = offset else { throw PngPopulatingError.sectionNotFound }
        if !sanityCheckOffset(for: offset, fileHandle: fileHandle) {
            throw PngPopulatingError.dataDoesNotMatchOriginalData
        }
//        guard let wantedSection = PngSection(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
//        return [wantedSection]
        return try populateWantedSection(offset: offset, fileHandle: fileHandle)
    }
    
    private func populateWantedSection(offset: PngSectionOffsetInfo, fileHandle: FileHandle) throws(PngPopulatingError) -> [PngSection] {
        let type = PngHeaderTypes(rawValue: offset.type) ?? .unknown
        switch type {
        case .IHDR:
            guard let wantedSection = PngIhdr(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .PLTE:
            guard let wantedSection = PngPlte(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .gAMA:
            guard let wantedSection = PngGama(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .cHRM:
            guard let wantedSection = PngChrm(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .sRGB:
            guard let wantedSection = PngSrgb(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .iCCP:
            guard let wantedSection = PngIccp(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .tIME:
            guard let wantedSection = PngTime(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .IEND:
            guard let wantedSection = PngSection(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .sBIT:
            guard let wantedSection = PngSbit(sectionOffset: offset, fileHandle: fileHandle, colorType: headerSection?.colorType) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .bKGD:
            guard let wantedSection = PngBkgd(sectionOffset: offset, fileHandle: fileHandle, bitDepth: headerSection?.bitDepth, colorType: headerSection?.colorType) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .hIST:
            guard let wantedSection = PngSection(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .tRNS:
            guard let wantedSection = PngTrns(sectionOffset: offset, fileHandle: fileHandle, bitDepth: headerSection?.bitDepth, colorType: headerSection?.colorType) else { throw PngPopulatingError.sectionNotFound }
            return [wantedSection]
        case .pHYs:
            guard let wantedSection = PngPhys(sectionOffset: offset, fileHandle: fileHandle) else { throw PngPopulatingError.sectionNotFound}
            return [wantedSection]
        default:
            throw PngPopulatingError.sectionNotFound
        }
    }
    
    private func populateDataForMultiSection(offsets: [PngSectionOffsetInfo]?, fileHandle: FileHandle) throws(PngPopulatingError) -> [PngSection] {
        guard let offsets = offsets else { throw PngPopulatingError.sectionNotFound }
        for offset in offsets {
            if !sanityCheckOffset(for: offset, fileHandle: fileHandle) {
                throw PngPopulatingError.dataDoesNotMatchOriginalData
            }
        }
        return try populateWantedSections(offsets: offsets, fileHandle: fileHandle)

    }
    
    private func populateWantedSections(offsets: [PngSectionOffsetInfo]?, fileHandle: FileHandle) throws(PngPopulatingError) -> [PngSection] {
        guard let offsets = offsets else { throw PngPopulatingError.sectionNotFound }
        for offset in offsets {
            if !sanityCheckOffset(for: offset, fileHandle: fileHandle) {
                throw PngPopulatingError.dataDoesNotMatchOriginalData
            }
        }
        let firstSection = offsets.first!
        let wantedType = PngHeaderTypes(rawValue: firstSection.type) ?? .unknown
        var wantedSections: [PngSection]
        switch wantedType {
        case .tEXt:
            wantedSections = offsets.compactMap({ PngText(sectionOffset: $0, fileHandle: fileHandle)})

        case .iTXt:
            wantedSections = offsets.compactMap({ PngItxt(sectionOffset: $0, fileHandle: fileHandle)})

        case .zTXt:
            wantedSections = offsets.compactMap({ PngZtxt(sectionOffset: $0, fileHandle: fileHandle)})

        case .sPLT:
            wantedSections = offsets.compactMap({ PngSplt(sectionOffset: $0, fileHandle: fileHandle)})

        case .IDAT:
            wantedSections = offsets.compactMap({ PngSection(sectionOffset: $0, fileHandle: fileHandle)})
            
        default:
            throw PngPopulatingError.sectionNotFound
        }
        if !wantedSections.isEmpty {
            return wantedSections
        } else {
            throw PngPopulatingError.sectionNotFound
        }
        
    }
    
    // Sanity check data to make sure the file wasn't changed
    func sanityCheckOffset(for offset:PngSectionOffsetInfo, fileHandle:FileHandle) -> Bool {
        do {
            try fileHandle.seek(toOffset: offset.offset)
            guard let chunkLength = try fileHandle.read(upToCount: 4) else { return false }
            let convertedLength = convertLengthToProperEndianess(chunkLength: chunkLength)
            if convertedLength != offset.SectionLength { return false }
            guard let chunkType = try fileHandle.read(upToCount: 4) else { return false }
            guard let convertedChunkType = String(data: chunkType, encoding: .utf8) else { return false }
            if convertedChunkType != offset.type { return false }
        } catch {
            return false
        }
        return true
    }
    
    func convertLengthToProperEndianess(chunkLength:Data) -> UInt32 {
        var endianCorrectedChunkLength: UInt32 = 0
        chunkLength.withUnsafeBytes { rawBytes in
            let needToConvert = rawBytes.load(as: UInt32.self)
            // PNG data is stored in big endian format
            endianCorrectedChunkLength = needToConvert.bigEndian
        }
        return endianCorrectedChunkLength
    }
    
    func haveOffset(for type: PngHeaderTypes, unknownString: String = "") -> Bool {
        switch type {
            
        case .IHDR:
            return ihdrChunk != nil
        case .PLTE:
            return plteChunk != nil
        case .IDAT:
            return !idatChunk.isEmpty
        case .IEND:
            return iendChunk != nil
        case .cHRM:
            return chrmChunk != nil
        case .gAMA:
            return gamaChunk != nil
        case .iCCP:
            return iccpChunk != nil
        case .sBIT:
            return sbitChunk != nil
        case .sRGB:
            return srgbChunk != nil
        case .bKGD:
            return bkgdChunk != nil
        case .hIST:
            return histChunk != nil
        case .tRNS:
            return trnsChunk != nil
        case .pHYs:
            return physChunk != nil
        case .sPLT:
            return spltChunk != nil
        case .tIME:
            return timeChunk != nil
        case .iTXt:
            return itxtChunk?.isEmpty ?? true == false
        case .tEXt:
            return textChunk?.isEmpty ?? true == false
        case .zTXt:
            return ztxtChunk?.isEmpty ?? true == false
        case .unknown:
            if unknownString.isEmpty {
                return false
            } else {
                return nonstandardChunks[unknownString] != nil
            }
        }
    }
}
