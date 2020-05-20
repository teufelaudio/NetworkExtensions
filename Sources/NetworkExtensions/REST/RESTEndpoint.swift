//
//  RESTEndpoint.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// Protocol to define a REST Endpoint
public protocol RESTEndpoint {
    associatedtype Body

    /// Path for the endpoint, starts with a slash such as "/users"
    var path: String { get }

    /// HTTP Method
    var method: HTTPMethod { get }

    /// Optional body to send
    var body: Body? { get }

    /// The endpoint can replace the default REST Client port, when needed
    var port: EndpointPort { get }

    /// Parameters to send in the URL request
    var queryParameters: [QueryParameter] { get }

    /// Key-valie pairs to send in the HTTP Header
    var headers: [String: String] { get }

    /// It should or not use SSL, when `nil` it's to be decided by the REST Client
    var useSSL: Bool? { get }

    /// Status code handler that checks the HTTP response to decide if the status code is within the expected range.
    /// When nil, the API rule will be used
    var statusCodeHandler: StatusCodeHandler? { get }
}
