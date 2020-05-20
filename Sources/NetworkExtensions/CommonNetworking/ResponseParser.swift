//
//  ResponseParser.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// A container for the `parse` function that takes `Data` and returns `Result<T, Error>`
public struct ResponseParser<T> {

    /// Main function that when given `Data`, will apply the transformation into a `Result<T, Error>`.
    public private(set) var parse: (Data, HTTPURLResponse) -> Result<T, Error>

    /// Initialize the `ResponseParser` with a closure that does the transformation. This is the
    /// most basic way to create a `ResponseParser`.
    ///
    /// - Parameter transformation: a function that goes from `Data` to `Result<T, Error>`, in other words, a
    ///             way to get the binary data and transform in some meaningful object of type `T`, or an error
    ///             in case the data wasn't in the expected format.
    public init(_ transformation: @escaping (Data, HTTPURLResponse) -> Result<T, Error>) {
        self.parse = transformation
    }
}

public struct InvalidJsonError: Error, CustomDebugStringConvertible {
    public let error: Error
    public let data: String

    public var debugDescription: String {
        "\(error.localizedDescription):\n\(data)"
    }
}

extension ResponseParser {

    /// Creates a `ResponseParser` that uses JSON Decoder to transform to any object that conforms to `Decodable` protocol
    ///
    /// - Parameters:
    ///   - type: the type of object expected to be transformed into, it can be any type that conforms to `Decodable`.
    ///   - decoder: the JSON Decoder to be used, defaults to `JSONDecoder()`
    /// - Returns: a new `ResponseParser<X>`, where `X` is the type provided as parameter, therefore `Decodable`.
    public static func json<X: Decodable>(_ type: X.Type, decoder: JSONDecoder = .init()) -> ResponseParser<X> {
        .init { data, _ in
            do {
                let value = try decoder.decode(X.self, from: data)
                return Result<X, Error>.success(value)
            } catch {
                let jsonError = InvalidJsonError.init(error: error, data: String.init(data: data, encoding: .utf8) ?? "<nil>")
                return Result<X, Error>.failure(jsonError)
            }
        }
    }
}

extension ResponseParser {

    /// Creates a `ResponseParser` that simply ignores the input Data and returns `Void`. Useful for APIs that respond
    /// with no meaningful body, or no body at all.
    public static var ignore: ResponseParser<Void> {
        .init { _, _ in
            Result<Void, Error>.success(())
        }
    }
}

extension ResponseParser where T == Data {
    public static var identity: ResponseParser<Data> {
        .init { data, _ in
            Result<Data, Error>.success(data)
        }
    }
}
extension ResponseParser {

    /// Creates a `ResponseParser` that transforms the Data into plain string.
    ///
    /// - Returns: a new `ResponseParser<String>`.
    public static func plainText() -> ResponseParser<String> {
        .init { data, _ in
            Result<String, Error>.success(String(data: data, encoding: .utf8) ?? "")
        }
    }
}

#if DEBUG

extension ResponseParser {
    public static func print(using encoding: String.Encoding = .utf8) -> ResponseParser<Void> {
        .init { data, _ in
            Swift.print(String(data: data, encoding: encoding) ?? "")
            return Result<Void, Error>.success(())
        }
    }

    public static func dump(using encoding: String.Encoding = .utf8) -> ResponseParser<Void> {
        .init { data, response in
            Swift.print("Headers:")
            Swift.dump(response.allHeaderFields)
            Swift.print("Body:")
            Swift.print(String(data: data, encoding: encoding) ?? "")
            return Result<Void, Error>.success(())
        }
    }
}

#endif
