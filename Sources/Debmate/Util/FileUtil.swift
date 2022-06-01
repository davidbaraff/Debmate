//
//  FileUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
#if os(Linux)
import DebmateLinuxC
#endif

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

    /// The application's Application Support directory
    public static let applicationSupportDirectory = applicationURL(forDirectory: .applicationSupportDirectory)
    
    /// Test if a directory exists.
    ///
    /// - Parameter url: directory location
    /// - Returns: true if the directory exists
    public static func isDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    
    /// Returns a resolved path
    /// - Parameter url: path to resolve
    /// Returns the path with symlinks resolved.
    public static func realpath(url: URL) -> URL {
        return (try? URL(fileURLWithPath: FileManager.default.destinationOfSymbolicLink(atPath: url.path))) ??
            (url as NSURL).resolvingSymlinksInPath ?? url
    }
    
    /// Creates a directory as necessary.
    ///
    /// - Parameter url: directory location
    /// - Returns: true if the directory exists or was succesfully created
    @discardableResult
    public static func ensureDirectoryExists(url: URL) -> Bool {
        if isDirectory(url: url) {
            return true
        }
        
        let rp = realpath(url: url)
        return isDirectory(url: rp) ||
            (try? FileManager.default.createDirectory(atPath: rp.path,
                                                      withIntermediateDirectories: true, attributes: nil)) != nil
    }

    /// Creates a directory as necessary.
    ///
    /// - Parameter url: file location requiring directory
    /// - Returns: true if the directory exists or was succesfully created
    @discardableResult
    public static func ensureDirectoryExists(forFile fileURL: URL) -> Bool {
        ensureDirectoryExists(url: fileURL.deletingLastPathComponent())
    }
    
    
    /// Rename a file.
    /// - Parameters:
    ///   - fromURL: original location
    ///   - toURL: new location
    ///
    ///   On non-linux systems, this is atomic. On linux, this call does (possibly) a delete of srcURL followed by an atomic rename.
    public static func renameFile(fromURL: URL, toURL: URL) throws {
        #if !os(Linux)
       _ = try FileManager.default.replaceItemAt(toURL, withItemAt: fromURL)
        #else
        if FileManager.default.fileExists(atPath: toURL.path) {
            _ = try FileManager.default.removeItem(at: toURL)
            _ = try FileManager.default.moveItem(at: fromURL, to: toURL)
        }
        #endif
    }
    
    /// Compute a file relative path
    /// - Parameters:
    ///   - src: The source file.
    ///   - dest: The destination file.
    /// The returned result reflects a relative path to dest using src as the starting point.
    static public func fileRelativePath(src: URL, dest: URL) -> URL {
        let pathComponents = (dest.path as NSString).pathComponents
        let anchorComponents = (src.path as NSString).pathComponents
        
        var componentsInCommon = 0
        for (c1, c2) in zip(pathComponents, anchorComponents) {
            if c1 != c2 {
                break
            }
            componentsInCommon += 1
        }
        
        let numberOfParentComponents = anchorComponents.count - componentsInCommon
        let numberOfPathComponents = pathComponents.count - componentsInCommon
        
        var relativeComponents = [String]()
        relativeComponents.reserveCapacity(numberOfParentComponents + numberOfPathComponents)
        for _ in 0..<numberOfParentComponents {
            relativeComponents.append("..")
        }
        
        for i in componentsInCommon ..< pathComponents.count {
            relativeComponents.append(pathComponents[i])
        }
        
        return URL(fileURLWithPath: relativeComponents.joined(separator: "/"))
    }
    
    /// List contents of directory, handling symlinks
    /// - Parameter url: directory URL
    public static func directoryContents(url: URL) throws -> [URL] {
        let resolvedURL = (url as NSURL).resolvingSymlinksInPath ?? url
        return try FileManager.default.contentsOfDirectory(at: resolvedURL, includingPropertiesForKeys: nil, options: [])
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
        #if !os(Linux)
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary {
            return attrs.fileSize()
        }
        return nil
        #else
        let nbytes = linux_file_size(url.path)
        return nbytes >= 0 ? UInt64(nbytes) : nil
        #endif
    }
    
    /// Return the creation time of a file, in seconds.
    public static func fileCreationTime(url: URL) -> Double? {
        #if !os(Linux)
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary {
            return attrs.fileCreationDate()?.timeIntervalSince1970
        }
        return nil
        #else
        let mtime = linux_file_mtime(url.path)
        return mtime > 0 ? Double(mtime) : nil
        #endif
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
        md5FileCacheLocation(hexDigest: md5Digest(assetName), directory: directory, pathExtension: pathExtension)
    }

    /// Cache file location for a given md5 hex digest.
    ///
    /// - Parameters:
    ///   - md5Digest: A hex md5 digest.
    ///   - directory: optional directory
    ///   - pathSuffix: optional path suffix
    ///   - pathExtension: optional path extension
    ///
    /// Returns a path of the form d[0]/d[1]d[2]/d[3:16] + <pathSuffix>.<pathExtension> where d is
    /// presumed to be at least a 16 byte length md5 hex digest.  (At any rate, d must be at least length
    /// three or greater.)
    ///
    /// If directory is supplied, directory is prepended.
    public static func md5FileCacheLocation(hexDigest digest: String, directory: URL? = nil,
                                            pathSuffix: String? = nil,
                                            pathExtension: String? = nil) -> URL {
        var startIndex = digest.startIndex
        
        let d0 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        
        let d1 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        let d2 = digest[startIndex]
        
        var suffix = pathSuffix ?? ""
        if let pathExtension = pathExtension {
            suffix = "\(suffix).\(pathExtension)"
        }
        
        let cacheFile = "\(d0)/\(d1)\(d2)/\(digest.suffix(13))" + suffix
        if let directory = directory {
            return directory.appendingPathComponent(cacheFile)
        }
        else {
            return URL(fileURLWithPath: cacheFile)
        }
    }
    
    /// Relative cache file location for a given md5 hex digest.
    ///
    /// - Parameters:
    ///   - md5Digest: A hex md5 digest.
    ///   - pathSuffix: optional path suffix
    ///   - pathExtension: optional path extension
    ///
    /// Returns a path of the form d[0]/d[1]d[2]/d[3:] + <pathSuffix>.<pathExtension> where d is
    /// presumed to be an md5 hex digest of length three or greater.
    public static func relativeMD5FileCacheLocation(hexDigest digest: String,
                                                    pathSuffix: String? = nil,
                                                    pathExtension: String? = nil) -> String {
        var startIndex = digest.startIndex
        
        let d0 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        
        let d1 = digest[startIndex]
        startIndex = digest.index(after: startIndex)
        let d2 = digest[startIndex]
        
        var suffix = pathSuffix ?? ""
        if let pathExtension = pathExtension {
            suffix = "\(suffix).\(pathExtension)"
        }
        
        return "\(d0)\(d1)/\(d2)/\(digest.dropFirst(3))" + suffix
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
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
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
