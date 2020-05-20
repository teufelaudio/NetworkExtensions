//
//  URLRequestCreator.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

internal struct URLRequestCreator<Body> {
    let port: Int
    let scheme: String
    let hostname: String
    let headers: [String: String]
    let queryParameters: [QueryParameter]
    let path: String
    let method: HTTPMethod
    let body: Body?

    func createURLRequest(requestParser: RequestParser<Body>) -> Result<URLRequest, Error> {
        createURLComponents()
            .urlRequest
            .with(\URLRequest.httpMethod,
                  value: method.rawValue)
            .with { request in
                headers.forEach { key, value in
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            .with(body: body, parser: requestParser)
    }

    func createURLComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = scheme
        components.host = hostname
        components.port = port
        components.path = path
        let queryItems = queryParameters.map(URLQueryItem.init)
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        return components
    }
}
