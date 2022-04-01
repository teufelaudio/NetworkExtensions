//
//  StatusCodeError.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// Even with a successful response from an HTTP Request, the result may have failed if status code is not on 200...299 range.
/// This structure allows us to treat such cases as Errors, handled by upper levels of our code.
public struct StatusCodeError: Error {
    public let httpResponse: HTTPURLResponse?
    public let statusCode: Int
    public let data: Data?

    public init(statusCode: Int, httpResponse: HTTPURLResponse?, data: Data?) {
        self.httpResponse = httpResponse
        self.statusCode = statusCode
        self.data = data
    }
}

extension StatusCodeError: Equatable { }

/// Compares two status code error
///
/// - Parameters:
///   - lhs: left-hand-side status code
///   - rhs: rhs-hand-side status code
/// - Returns: it compares only the numerical status code and returns true if they are the same.
public func == (lhs: StatusCodeError, rhs: StatusCodeError) -> Bool {
    return lhs.statusCode == rhs.statusCode
}
