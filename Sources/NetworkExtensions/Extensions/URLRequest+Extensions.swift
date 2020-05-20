//
//  URLRequest+Extensions.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

extension URLRequest {

    /// Allows the URLRequest to be mutated in place, given a closure that performs all mutations needed
    ///
    /// - Parameter mutation: closure that mutates an URLRequest in place
    /// - Returns: a pointer to the original URLRequest, but modified according to the given closure
    public func with(_ mutation: (inout URLRequest) -> Void) -> URLRequest {
        var request = self
        mutation(&request)
        return request
    }

    /// Allows the URLRequest to be mutated in place, given a keyPath to the property to be changed, and the new value
    ///
    /// - Parameters:
    ///   - keyPath: A WritableKeyPath that points to the property of URLRequest we want to change
    ///   - value: The new value to be set
    /// - Returns: a pointer to the original URLRequest, but modified with the new property value
    public func with<T>(_ keyPath: WritableKeyPath<URLRequest, T>, value: T) -> URLRequest {
        return with {
            $0[keyPath: keyPath] = value
        }
    }

    /// Sets the body of an URLRequest to the provided object, using the given `RequestParser` (which defaults to JSON).
    ///
    /// - Parameters:
    ///   - body: object that will be serialized into the body of a HTTP Request
    ///   - parser: Parser that's gonna be used to transform the given object into binary data, defaults to `RequestParser<T>.json(T.self)`
    /// - Returns: result that can be either the URLRequest after the successful body mutation, or an error in case the parser has failed.
    public func with<T>(body: T?, parser: RequestParser<T>) -> Result<URLRequest, Error> {
        guard let body = body else { return .success(self) }

        switch parser.parse(body) {
        case .success(let data):
            return .success(with(\URLRequest.httpBody, value: data))
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension Result where Success == URLRequest, Failure == Error {
    /// Allows the URLRequest to be mutated in place, given a closure that performs all mutations needed
    ///
    /// - Parameter mutation: closure that mutates an URLRequest in place
    /// - Returns: a pointer to the original URLRequest, but modified according to the given closure
    public func with(_ mutation: (inout URLRequest) -> Void) -> Result<Success, Error> {
        switch self {
        case .success(var request):
            mutation(&request)
            return .success(request)
        default: return self.map { $0 }.mapError { $0 }
        }
    }

    /// Allows the URLRequest to be mutated in place, given a keyPath to the property to be changed, and the new value
    ///
    /// - Parameters:
    ///   - keyPath: A WritableKeyPath that points to the property of URLRequest we want to change
    ///   - value: The new value to be set
    /// - Returns: a pointer to the original URLRequest, but modified with the new property value
    public func with<T>(_ keyPath: WritableKeyPath<URLRequest, T>, value: T) -> Result<Success, Error> {
        return with {
            $0[keyPath: keyPath] = value
        }
    }

    /// Sets the body of an URLRequest to the provided object, using the given `RequestParser` (which defaults to JSON).
    ///
    /// - Parameters:
    ///   - body: object that will be serialized into the body of a HTTP Request
    ///   - parser: Parser that's gonna be used to transform the given object into binary data, defaults to `RequestParser<T>.json(T.self)`
    /// - Returns: result that can be either the URLRequest after the successful body mutation, or an error in case the parser has failed.
    public func with<T>(body: T?, parser: RequestParser<T>) -> Result<Success, Error> {
        guard let body = body else { return self.map { $0 }.mapError { $0 } }

        switch parser.parse(body) {
        case .success(let data):
            return with(\URLRequest.httpBody, value: data).map { $0 }.mapError { $0 }
        case .failure(let error):
            return Result<Success, Error>.failure(error)
        }
    }
}
