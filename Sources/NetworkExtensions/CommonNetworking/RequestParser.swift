//
//  RequestParser.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// A container for the `parse` function that takes `Data` and returns `Result<T, Error>`
public struct RequestParser<T> {

    /// Main function that when given `T`, will apply the transformation into a `Result<Data, Error>`.
    public private(set) var parse: (T) -> Result<Data, Error>

    /// Initialize the `RequestParser` with a closure that does the transformation. This is the
    /// most basic way to create a `RequestParser`.
    ///
    /// - Parameter transformation: a function that goes from `T` to `Result<Data, Error>`, in other words, a way to get
    ///             the object of type `T` and transform it in some binary data to be sent across the network, or an error
    ///             in case the object wasn't in the expected format.
    public init(_ transformation: @escaping (T) -> Result<Data, Error>) {
        self.parse = transformation
    }
}

extension RequestParser where T: Encodable {

    /// Creates a `RequestParser` that uses JSON Encoder to transform any object that conforms to `Encodable` protocol into Data
    ///
    /// - Parameters:
    ///   - encoder: the JSON Encoder to be used, defaults to `JSONEncoder()`
    /// - Returns: a new `RequestParser`.
    public static func json(encoder: JSONEncoder = .init()) -> RequestParser {
        return .init { object in
            do {
                let data = try encoder.encode(AnyEncodable(object))
                return .success(data)
            } catch {
                return .failure(error)
            }
        }
    }
}

extension RequestParser {

    /// Creates a `RequestParser` that simply ignores the input and returns empty `Data`. Useful for requests that don't have body.
    public static var ignore: RequestParser {
        return .init { _ in
            return Result<Data, Error>.success(Data())
        }
    }
}

extension RequestParser {

    /// Creates a `RequestParser` that transforms a string into Data. If the input is not a string, the stringify function can be
    /// provided, otherwise the return will be empty data.
    ///
    /// - Parameters:
    ///   - stringify: a method that transforms the encodable input into string, in case it's not. Optional.
    /// - Returns: a new `RequestParser`.
    public static func plainText(stringify: ((T) throws -> String)? = nil) -> RequestParser {
        return .init { object in
            if let string = object as? String {
                return .success(string.data(using: .utf8) ?? Data())
            }

            guard let stringify = stringify else { return .success(Data()) }

            do {
                let string = try stringify(object)
                return .success(string.data(using: .utf8) ?? Data())
            } catch {
                return .failure(error)
            }
        }
    }
}
