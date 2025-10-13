//
//  PngErrors.swift
//  PngSwift
//
//  Created by Richard Perry on 10/2/25.
//

import Foundation

public enum PngSavingError: LocalizedError {
    case failed
    case containsUnknownChunks
    case dataDifferent
    
    public var errorDescription: String? {
        switch self {
        case .failed:
            "PNG failed to save"
        case .containsUnknownChunks:
            "PNG contains unknown chunks"
        case .dataDifferent:
            "PNG data is different from original"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case.failed:
            "PNG could not be saved at wanted location"
        case .containsUnknownChunks:
            "Can not save PNG with unsupported chunks"
        case .dataDifferent:
            "PNG file is different or has been modified since creation"
        }
    }
}

public enum PngLoadingError: LocalizedError {
    case failed
    case invalidFile
    case notPng
    case corrupted
    case notFound
    case malformed(failedSection: String)
    case missingRequiredSection(missingSection: String)
    case invalidName
    
    public var errorDescription: String? {
        switch self {
        case .failed:
            "PNG failed to load"
        case .invalidFile:
            "PNG file is invalid"
        case .notPng:
            "File is not a PNG file"
        case .malformed(let section):
            "Section \(section) is malformed"
        case .missingRequiredSection(let setion):
            "Required section \(setion) is missing"
        case .corrupted:
            "PNG file is corrupted"
        case .notFound:
            "PNG file not found"
        case .invalidName:
            "Section name is invalid"
        }
    }
}

public enum PngPopulatingError: LocalizedError {
    case fileMissing
    case sectionNotFound
    case dataDoesNotMatchOriginalData
    case unexpectedSectionName(unexpectedSection: String)
    case unupdatableSection(unupdatableSection: String)
    case invalidSectionData(invalidSection: String)
    
    public var errorDescription: String? {
        switch self {
        case .fileMissing:
            "File is missing"
        case .sectionNotFound:
            "Section not found"
        case .dataDoesNotMatchOriginalData:
            "Data does not match original data"
        case .unexpectedSectionName(unexpectedSection: let unexpectedSection):
            "Unexpected section name: \(unexpectedSection)"
        case .unupdatableSection(unupdatableSection: let unupdatableSection):
            "The section is not able to be updated: \(unupdatableSection)"
        case .invalidSectionData(invalidSection: let invalidSection):
            "Section \(invalidSection) has invalid data"
        }
    }
}
