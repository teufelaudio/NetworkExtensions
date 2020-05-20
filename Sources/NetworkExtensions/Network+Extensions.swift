//
//  Network+Extensions.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation
import Network

public struct NetworkInterface: Hashable {
    public let interfaceName: String
    public let ipAddress: String

    public static func getIPAddresses() -> Set<NetworkInterface> {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        defer { freeifaddrs(ifaddr) }

        var ips = Set<NetworkInterface>()
        guard getifaddrs(&ifaddr) == 0 else { return ips }

        var ptr = ifaddr

        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            guard addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) else { continue }
            guard let name: String = (interface?.ifa_name).map({ String(cString: $0) }) else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(interface?.ifa_addr,
                        socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0), NI_NUMERICHOST)
            let address = String(cString: hostname)
            ips.insert(.init(interfaceName: name, ipAddress: address))
        }

        return ips
    }
}
