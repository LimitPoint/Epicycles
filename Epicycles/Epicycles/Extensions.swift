//
//  Extensions.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/16/23.
//

import SwiftUI

extension CIImage {
    
    func cgimage() -> CGImage? {
        
        var cgImage:CGImage
        
        if let cgi = self.cgImage {
            cgImage = cgi
        }
        else {
            let context = CIContext(options: nil)
            guard let cgi = context.createCGImage(self, from: self.extent) else { return nil }
            cgImage = cgi
        }
        
        return cgImage
    }
    
}

extension FileManager {
    
    class func urlForDocumentsOrSubdirectory(subdirectoryName:String?) -> URL? {
        var documentsURL: URL?
        
        do {
            documentsURL = try FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        catch {
            return nil
        }
        
        guard let subdirectoryName = subdirectoryName else {
            return documentsURL
        }
        
        if let directoryURL = documentsURL?.appendingPathComponent(subdirectoryName) {
            if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: nil) == false {
                do {
                    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes:nil)
                }
                catch let error as NSError {
                    print("error = \(error.description)")
                    return nil
                }
            }
            
            return directoryURL
        }
        
        return nil
    }
    
    class func documentsURL(filename:String?, subdirectoryName:String?) -> URL? {
        
        guard let documentsDirectoryURL = FileManager.urlForDocumentsOrSubdirectory(subdirectoryName: subdirectoryName) else {
            return nil
        }
        
        var destinationURL = documentsDirectoryURL
        
        if let filename = filename {
            destinationURL = documentsDirectoryURL.appendingPathComponent(filename)
        }
        
        return destinationURL
    }
    
    class func deleteDocumentsSubdirectory(subdirectoryName:String) {
        if let subdirectoryURL  = FileManager.documentsURL(filename: nil, subdirectoryName: subdirectoryName) {
            do {
                try FileManager.default.removeItem(at: subdirectoryURL)
                print("FileManager deleted directory at \(subdirectoryURL)")
            }
            catch {
                print("FileManager had an error removing directory at \(subdirectoryURL)")
            }
        }
    }
}

