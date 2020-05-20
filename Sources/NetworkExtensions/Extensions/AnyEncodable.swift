//
//  AnyEncodable.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

/// Type-erasure for Encodable type
public struct AnyEncodable: Encodable {
    private var encodeFunc: (Encoder) throws -> Void

    public init(_ encodable: Encodable) {
        func internalEncode(to encoder: Encoder) throws {
            try encodable.encode(to: encoder)
        }

        self.encodeFunc = internalEncode
    }

    public func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
