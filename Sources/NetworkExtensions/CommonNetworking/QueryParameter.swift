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

    public init(key: String, value: String? = nil, urlEncode: Bool = false) {
        self.key = key
        self.value = urlEncode ? value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) : value
    }
}

extension URLQueryItem {
    public init(queryParameter: QueryParameter) {
        self.init(name: queryParameter.key, value: queryParameter.value)
    }
}

extension QueryParameter {
    public init?<T: Encodable>(key: String, encodable: T, encoder: () -> JSONEncoder = JSONEncoder.init, urlEncode: Bool = true) {
        guard let data = try? encoder().encode(encodable) else { return nil }
        let string = String(data: data, encoding: .utf8)
        self = .init(key: key, value: string, urlEncode: urlEncode)
    }
}
