//
//  IP.swift
//  NetworkExtensions
//
//  Created by Luiz Rodrigo Martins Barbosa on 20.05.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation
import FoundationExtensions
import Network

public enum IP: Codable, CustomStringConvertible, Equatable, Hashable { // swiftlint:disable:this type_name
    case ipv4(IPv4Address)
    case ipv6(IPv6Address)

    public var genericIP: IPAddress {
        switch self {
        case let .ipv4(v4): return v4
        case let .ipv6(v6): return v6
        }
    }

    public var description: String {
        ipString
    }

    public var ipString: String {
        switch self {
        case let .ipv4(v4):
            return v4.rawValue.map(String.init).joined(separator: ".")
        case let .ipv6(v6):

            let bigEndian: Bool = (1 == CFSwapInt32LittleToHost(1))
            var address = (0..<8)
                .map { index in
                    v6.rawValue.range(start: index * 2, length: 2).readUInt16(bigEndian: bigEndian)
                }
                .map { $0 == 0 ? "" : String(format: "%llx", $0) }
                .joined(separator: ":")
            while (address.contains(":::")) {
                address = address.replacingOccurrences(of: ":::", with: "::")
            }
            if let ifName = v6.interface?.name {
                return "\(address)%\(ifName)"
            } else {
                return "\(address)"
            }
        }
    }

    public var ipUrlString: String {
        switch self {
        case .ipv4:
            return ipString
        case .ipv6:
            return "[\(ipString)]"
        }
    }

    public init?(_ ipString: String) {
        if let addr = IPv6Address(ipString) {
            self = .ipv6(addr)
        } else if let addr = IPv4Address(ipString) {
            self = .ipv4(addr)
        } else {
            return nil
        }
    }

    public init?(_ data: Data) {
        if let addr = IPv6Address(data) {
            self = .ipv6(addr)
        } else if let addr = IPv4Address(data) {
            self = .ipv4(addr)
        } else {
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let bytes = try container.decode(Data.self)
        if bytes.count == 4 {
            guard let v4 = IPv4Address(bytes) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Can't parse IPv4 address \(bytes)")
            }
            self = .ipv4(v4)
        } else {
            guard let v6 = IPv6Address(bytes) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Can't parse IPv6 address \(bytes)")
            }
            self = .ipv6(v6)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(genericIP.rawValue)
    }
}

extension IP {
    public var ipv4: IPv4Address? {
        get {
            guard case let .ipv4(value) = self else { return nil }
            return value
        }
        set {
            guard case .ipv4 = self, let newValue = newValue else { return }
            self = .ipv4(newValue)
        }
    }

    public var isIPv4: Bool {
        self.ipv4 != nil
    }
}

extension IP {
    public var ipv6: IPv6Address? {
        get {
            guard case let .ipv6(value) = self else { return nil }
            return value
        }
        set {
            guard case .ipv6 = self, let newValue = newValue else { return }
            self = .ipv6(newValue)
        }
    }

    public var isIPv6: Bool {
        self.ipv6 != nil
    }
}

extension Array where Element == IP {

    /// Picks the first IPv6 address over existing IPv4 addresses.
    public var preferredAddress: IP? {
        if let candidate = self.first(where: { $0.isIPv6 }) {
            return candidate
        }
        if let candidate = self.first(where: { $0.isIPv4 }) {
            return candidate
        }
        return nil
    }
}
