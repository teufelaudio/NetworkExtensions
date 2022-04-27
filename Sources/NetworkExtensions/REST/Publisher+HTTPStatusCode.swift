//
//  Publisher+HTTPStatusCode.swift
//  NetworkExtensions
//
//  Created by Giulia Ariu on 27.04.22.
//  Copyright © 2022 Lautsprecher Teufel GmbH. All rights reserved.
//

import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Output == (data: Data, response: URLResponse), Failure == URLError {
    public func validStatusCode() -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        flatMap { (data, response: URLResponse) -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
            guard let httpResponse = response as? HTTPURLResponse else {
                return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
            }

            return (200..<400) ~= httpResponse.statusCode
            ? Just((data: data, response: httpResponse)).setFailureType(to: URLError.self).eraseToAnyPublisher()
            : Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
