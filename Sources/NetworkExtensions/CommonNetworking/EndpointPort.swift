//
//  EndpointPort.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// Defines an endpoint port number or sets to use the REST Client default one
///
/// - useDefault: the endpoint will follow REST Client port
/// - override: the endpoint will override the default port with the associated value
public enum EndpointPort {
    case useDefault
    case override(UInt16)

    /// If it overrides the port, it will return which port should be used, if it's set to use default REST Client port, it will return nil
    public var possibleValue: UInt16? {
        switch self {
        case .useDefault: return nil
        case let .override(port): return port
        }
    }
}
