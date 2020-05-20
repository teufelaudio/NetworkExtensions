//
//  QueryParameter.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

public struct QueryParameter: Equatable, Codable {
    public var key: String
    public var value: String?

    public init(key: String, value: String? = nil) {
        self.key = key
        self.value = value
    }
}

extension URLQueryItem {
    public init(queryParameter: QueryParameter) {
        self.init(name: queryParameter.key, value: queryParameter.value)
    }
}
