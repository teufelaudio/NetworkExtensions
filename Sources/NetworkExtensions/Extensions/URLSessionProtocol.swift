//
//  URLSessionProtocol.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Combine
import Foundation

/// A protocol to abstract `URLSession` to the only used parameter required from the `RFNetworking` framework.
/// It makes easier to mock requests and responses.
public protocol URLSessionProtocol {
    var delegate: URLSessionDelegate? { get }
    func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher
    func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
}

extension URLSession: URLSessionProtocol { }
