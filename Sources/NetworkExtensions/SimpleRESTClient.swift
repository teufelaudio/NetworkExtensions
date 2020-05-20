//
//  SimpleRESTClient.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// A very simple implemementation of REST Client protocol that should work in most cases.
open class SimpleRESTClient: RESTClient {
    /// Default port for this REST Client. Endpoints can override this port.
    open var defaultPort: UInt16

    /// Whether or not to use SSL by default. This can be overriden by the endpoint.
    open var defaultUseSSL: Bool

    /// REST client IP address or hostname.
    open private(set) var hostname: String

    /// Headers required by the host to be sent in any request, regardless of the endpoint.
    open var requiredHeaders: [String: String]

    /// Query parameters (URL parameters) required by the host to be sent in any request, regardless of the endpoint.
    open var requiredQueryParameters: [QueryParameter]

    /// URL Session to be used for all requests.
    open private(set) var session: URLSessionProtocol

    /// Status code handler that checks the HTTP response to decide if the status code is within the expected range.
    /// When nil, the default rule will be used
    open var statusCodeHandler: StatusCodeHandler?

    /// Initializes a new REST Client from the hostname (or IP address) and an URLSessionProtocol to be used. In this case, any rule regarding
    /// certificates should be done by whom provided that URLSessionProtocol.
    ///
    /// - Parameters:
    ///   - hostname: hostname or IP address
    ///   - session: a URL Session to be used in all requests
    public required init(hostname: String, session: URLSessionProtocol) {
        self.hostname = hostname
        self.session = session
        self.defaultPort = 443
        self.defaultUseSSL = true
        self.requiredHeaders = [:]
        self.requiredQueryParameters = []
    }

    /// Initializes a new REST Client with all the available parameters. In this case, any rule regarding certificates should be done by whom
    /// provided that URLSessionProtocol.
    ///
    /// - Parameters:
    ///   - hostname: hostname or IP address
    ///   - session: a URL Session to be used in all requests
    ///   - defaultPort: HTTP port to be used by default, when endpoint doesn't specify one
    ///   - defaultUseSSL: whether or not to use SSL by default, when endpoint doesn't specify that
    ///   - requiredHeaders: HTTP headers required by the host for all requests, regardless of the endpoint
    ///   - requiredQueryParameters: query parameters (URL parameters) required by the host to be sent in any request, regardless of the endpoint.
    public convenience init(hostname: String,
                            session: URLSessionProtocol,
                            defaultPort: UInt16,
                            defaultUseSSL: Bool = true,
                            requiredHeaders: [String: String] = [:],
                            requiredQueryParameters: [QueryParameter] = []) {
        self.init(hostname: hostname, session: session)
        self.defaultPort = defaultPort
        self.defaultUseSSL = defaultUseSSL
        self.requiredHeaders = requiredHeaders
        self.requiredQueryParameters = requiredQueryParameters
    }

    /// Initializes a new REST Client with all the available parameters and a boolean that indicates whether or not the certificate validation is
    /// bypassed.
    /// If allowing any certificate is true, then a new URLSession will be created having the default configurations but with the delegate set to
    /// `BypassCertificateValidation`,
    /// otherwise the `URLSession.shared` will be used
    ///
    /// - Parameters:
    ///   - host: host name or IP address
    ///   - allowAnyCertificate: when true, it's bypass certificate validation (self-signed certificates will be allowed)
    ///   - defaultPort: HTTP port to be used by default, when endpoint doesn't specify one
    ///   - defaultUseSSL: whether or not to use SSL by default, when endpoint doesn't specify that
    ///   - requiredHeaders: HTTP headers required by the host for all requests, regardless of the endpoint
    ///   - requiredQueryParameters: query parameters (URL parameters) required by the host to be sent in any request, regardless of the endpoint.
    public convenience init(hostname: String,
                            allowAnyCertificate: Bool = false,
                            defaultPort: UInt16,
                            defaultUseSSL: Bool = true,
                            requiredHeaders: [String: String] = [:],
                            requiredQueryParameters: [QueryParameter] = []) {
        self.init(hostname: hostname, allowAnyCertificate: allowAnyCertificate)
        self.defaultPort = defaultPort
        self.defaultUseSSL = defaultUseSSL
        self.requiredHeaders = requiredHeaders
        self.requiredQueryParameters = requiredQueryParameters
    }
}
