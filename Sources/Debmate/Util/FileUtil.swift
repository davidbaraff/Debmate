//
//  FileUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

fileprivate func applicationURL(forDirectory dir: FileManager.SearchPathDirectory) -> URL {
    do {
        return try FileManager.default.url(for: dir, in: .userDomainMask, appropriateFor: nil, create: false)
    } catch {
        fatalErrorForCrashReport("Failed to find standard directory for \(dir)")
    }
}

extension Util {
    // MARK: - File utilities
    
    /// The application's caches directory.
    public static let cachesDirectory = applicationURL(forDirectory: .cachesDirectory)
    
    /// The application's documents directory.
    public static let documentsDirectory = applicationURL(forDirectory: .documentDirectory)
    
    /// Test if a directory exists.
    ///
    /// - Parameter url: directory location
    /// - Returns: true if the directory exists
    public static func isDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Creates a directory as necessary.
    ///
    /// - Parameter url: directory location
    /// - Returns: true if the directory exists or was succesfully created
    @discardableResult
    public static func ensureDirectoryExists(url: URL) -> Bool {
        return isDirectory(url: url) ||
          (try? FileManager.default.createDirectory(atPath: url.path,
                                                    withIntermediateDirectories: true, attributes: nil)) != nil
    }
    
    /// Clear the contents of a directory
    ///
    /// - Parameter url: directory to be cleared
    /// - Returns: true on success
    ///
    /// The directory at url is moved to a temporary location, a new directory
    /// is created at location url, and then the moved directory is destroyed.
    public static func clearDirectory(url: URL) -> Bool {
        let randomName = UUID().uuidString.suffix(10)
        let tmpName = "\(url.path)-\(randomName)"
        if (try? FileManager.default.moveItem(atPath: url.path, toPath: tmpName)) != nil {
            if ensureDirectoryExists(url: url) {
                if (try? FileManager.default.removeItem(atPath: tmpName)) != nil {
                    return true
                }
            }
        }
        return false
    }
    
    /// Return size of file.
    public static func fileSize(url: URL) -> UInt64? {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary {
            return attrs.fileSize()
        }
        return nil
    }
    
    /// Compute cache file location for an asset based on md5 checksum.
    ///
    /// - Parameters:
    ///   - assetName: The name of the asset
    ///   - directory: optional directory
    ///   - pathExtension: optional path extension
    ///
    /// Returns a path of the form d[0]/d[1]d[2]/d[3:] + <pathExtension> where d is the 16 byte
    /// hex encoding of the md5 digest of assetName.  If directory is supplied,
    /// directory is prepended.
    public static func md5FileCacheLocation(assetName: String, directory: URL? = nil,
                                            pathExtension: String? = nil) -> URL {
        let digest = md5Digest(assetName)
        var startIndex = digest.startIndex
        
        let d0 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        
        let d1 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        let d2 = digest[startIndex]
        
        var suffix = ""
        if let pathExtension = pathExtension {
            suffix = ".\(pathExtension)"
        }
        
        let cacheFile = "\(d0)/\(d1)\(d2)/\(digest.suffix(13))" + suffix
        if let directory = directory {
            return directory.appendingPathComponent(cacheFile)
        }
        else {
            return URL(fileURLWithPath: cacheFile)
        }
    }
    
    /// Write a value as a json string to a file.
    ///
    /// - Parameters:
    ///   - value: An Encodable value
    ///   - url: url to write to
    /// - Returns: true if successful
    ///
    /// If unsuccessful and onError is supplied, errorHandler is called with a string
    /// description of what went wrong.
    public static func encode<T>(_ value: T, toURL url: URL,
                                 errorHandler: ((String) -> ())? = nil) -> Bool where T : Encodable {
        do {
            ensureDirectoryExists(url: url.deletingLastPathComponent())
            try JSONEncoder().encode(value).write(to: url, options: .atomicWrite)
            return true
        }
        catch {
            if let errorHandler = errorHandler {
                errorHandler("Failed to encode value of type \(type(of: T.self)) to \(url): \(error)")
            }
        }
        return false
    }
    
    /// Decode a value from a json string in a file.
    ///
    /// - Parameters:
    ///   - type: type of decoded object
    ///   - url: url to read from
    /// - Returns: optional value of type T, if successful
    ///
    /// If unsuccessful and onError is supplied, errorHandler is called with a string
    /// description of what went wrong.
    public static func decode<T>(_ type: T.Type, fromURL url: URL,
                                 errorHandler: ((String) -> ())? = nil) -> T? where T : Decodable {
        do {
            return try JSONDecoder().decode(type, from:  Data(contentsOf: url, options: .uncached))
        } catch {
            if let errorHandler = errorHandler {
                errorHandler("Failed to decode value of type \(type) from \(url): \(error)")
            }
        }
        
        return nil
    }
    
    /// Return a unique file name using "-<N>" syntax.
    ///
    /// - Parameters:
    ///   - fileName: desired file name
    ///   - existingFileNames: a set of existing file names
    /// - Returns: The next file name in the sequence.
    ///
    /// If fileName is not found in existingFileNames, then fileName is returned.
    /// Otherwise, the return value is <baseFileName>-<N>.<extension>
    /// where <baseFileName>.<extension> is equal to fileName, and <N> is the smallest
    /// value such that <baseFileName>-<N-1>.<extension> was not found in existingFileNames.
    ///
    public static func nextNumberedFileName(_ fileName: String, existingFileNames: Set<String>) -> String {
        guard existingFileNames.contains(fileName) else {
            return fileName
        }
        
        var nextVersion = 1
        let ext = (fileName as NSString).pathExtension
        let extensionlessFileName = (fileName as NSString).deletingPathExtension
        let prefix = extensionlessFileName + "-"
        
        for existingFileName in existingFileNames {
            if existingFileName.hasPrefix(prefix) && (existingFileName as NSString).pathExtension == ext {
                if let version = Int((existingFileName.dropFirst(prefix.count) as NSString).deletingPathExtension) {
                    if version >= nextVersion {
                        nextVersion = version + 1
                    }
                }
            }
        }
        
        if ext.isEmpty {
            return "\(extensionlessFileName)-\(nextVersion)"
        }
        else {
            return "\(extensionlessFileName)-\(nextVersion).\(ext)"
        }
    }
}
