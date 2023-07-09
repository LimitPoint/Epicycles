//
//  EpicyclesDocument.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/23/23.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    static let epicyclesDocument = UTType(exportedAs: "com.limit-point.Epicycles.epi")
}

class EpicyclesDocument: FileDocument {
    
    var terms:[Term]
    
    static var readableContentTypes: [UTType] { [.epicyclesDocument] }
    
    init(terms: [Term] = []) {
        self.terms = terms
    }
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            terms = try JSONDecoder().decode([Term].self, from: data)
        } else {
            terms = []
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(terms)
        return FileWrapper(regularFileWithContents: data)
    }
    
}
