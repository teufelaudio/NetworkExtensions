//
//  URLComponents.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// Error caused by parsing URLComponents into URLRequest
///
/// - invalidComponents: the `url` object returned nil, components are not well-formed
public enum URLComponentsError: Error {
    case invalidComponents(URLComponents)
}

extension URLComponents {
    /// gets an url request out of these components
    public var urlRequest: Result<URLRequest, Error> {
        guard let url = self.url else { return .failure(URLComponentsError.invalidComponents(self)) }

        return .success(URLRequest(url: url))
    }
}
