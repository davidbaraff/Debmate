//
//  HttpUtil.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
#if os(Linux)
import OpenCombineShim
import FoundationNetworking
#else
import Combine
#endif

extension Util {
    // This accounts for the fact that URLQueryItem doesn't encode ';'
    // chars, which is flat-out broken!
    // + is also broken, but we have to wait till later to encode that,
    // see below.
    private static func preEncode(_ any: Any) -> String {
        return String(describing: any).replacingOccurrences(of: ";", with: "%3B")
    }
    
    /// Return a URL for a request.
    ///
    /// - Parameters:
    ///   - host: host
    ///   - port: optional port
    ///   - command: path (without parameters)
    ///   - parameters: dictionary of string/value parameters
    ///   - https: if a secure connection is required.
    /// - Returns: URL.
    ///
    static public func createURL(host: String, port: Int? = nil,
                                 command: String? = nil,
                                 parameters: [String: Any]? = nil,
                                 optionalParameters: [String: Any?]? = nil,
                                 https: Bool = false) throws -> URL {
        guard var uc1 = URLComponents(string: "http://\(host)") else {
            throw GeneralError("URL with host = '\(host)' is malformed")
        }
        
        if https {
            uc1.scheme = "https"
        }
        
        if let command = command,
            !command.isEmpty {
            if command.hasPrefix("/") {
                uc1.path = command
            }
            else {
                uc1.path = "/" + command
            }
        }
        
        if let port = port {
            uc1.port = port
        }
        
        var queryItems = [URLQueryItem]()
        if let parameters = parameters {
            for (key, value) in parameters {
                if let values = value as? [Any] {
                    for (value) in values {
                        queryItems.append(URLQueryItem(name: key, value: preEncode(value)))
                    }
                }
                else {
                    queryItems.append(URLQueryItem(name: key, value: preEncode(value)))
                }
            }
        }
        
        if let optionalParameters = optionalParameters {
            for (key, optionalValue) in optionalParameters {
                guard let value = optionalValue else { continue }
                if let values = value as? [Any] {
                    for (value) in values {
                        queryItems.append(URLQueryItem(name: key, value: preEncode(value)))
                    }
                }
                else {
                    queryItems.append(URLQueryItem(name: key, value: preEncode(value)))
                }
            }
        }
        
        uc1.queryItems = queryItems
        uc1.percentEncodedQuery = uc1.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        if let url = uc1.url {
            return url
        }
        
        throw GeneralError("failed to create valid URL for \(host):\(command ?? ""), with params = \(String(describing: parameters))")
    }

    /// Decode a URL
    ///
    /// - Parameter url: url
    /// - Returns: (path, params)
    ///
    /// The first element of the return value is the path of the URL.
    /// The second element of the return value is a dictionary of string key/value pairs
    /// which were the arguments of the URL.
    ///
    /// If the URL cannot be decoded, nil is returned.
    static public func decodeURL(_ url: URL) -> (String, [String : String])? {
        if let uc = URLComponents(string: url.absoluteString) {
            let path = uc.path
            if let items = uc.queryItems {
                let params = Dictionary(overwriting: items.map { ($0.name, $0.value ?? "") })
                return (path, params)
            }
        }
        return nil
    }
    
    /// Make an http request.
    ///
    /// - Parameters:
    ///   - host: host
    ///   - port: optional port
    ///   - command: path (without parameters)
    ///   - parameters: dictionary of string/value parameters
    ///   - body: optional body (implies post)
    /// - Returns: Publisher.
    static public func httpRequestPublisher(host: String, port: Int? = nil, command: String? = nil,
                                         parameters: [String: Any]? = nil, body: Data? = nil) -> AnyPublisher<Data, Error> {
        let url: URL
        do {
            url = try createURL(host: host, port: port, command: command, parameters: parameters)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let urlSession = URLSession(configuration: .ephemeral)
        var urlRequest = URLRequest(url: url)
        if let body = body {
            urlRequest.httpBody = body
            urlRequest.httpMethod = "POST"
        }
       
        return urlSession.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
