//
//  StatusCodeHandler.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// Evaluates the status code of a HTTP response and inject errors in case it's not within the expected range
public struct StatusCodeHandler {

    /// Closure that evaluates the status code inside a HTTP URL Response, and returns the result. It simply bypasses if current result state is
    /// already a failure
    public let eval: (HTTPURLResponse?, Data?) -> Result<HTTPURLResponse, Error>

    /// Initializes a Status Code Handler with the evaluation function
    ///
    /// - Parameter eval: A function that takes a HTTP Response and current result so far, and calculates the new result by evaluating the status
    ///                   code from the HTTP Response.
    public init(_ eval: @escaping (HTTPURLResponse?, Data?) -> Result<HTTPURLResponse, Error>) {
        self.eval = eval
    }
}

extension StatusCodeHandler {

    /// Default status code handler: if it's within the range from 200 to 299, it considers at a success, otherwise returns a `StatusCodeError`
    public static var `default`: StatusCodeHandler {
        return StatusCodeHandler { response, data in
            guard let httpResponse = response,
                (200...299) ~= httpResponse.statusCode else {
                    return .failure(StatusCodeError(statusCode: response?.statusCode ?? 0, httpResponse: response, data: data))
            }
            return .success(httpResponse)
        }
    }
}
