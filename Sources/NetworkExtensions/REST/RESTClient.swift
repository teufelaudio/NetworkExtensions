//
//  RESTClient.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Combine
import Foundation

/// REST Client protocol, it's meant to be implemented to conform with specific REST servers.
/// The implementations also should contain all possible actions in method extensions, so for example given
/// a `HostRESTClient` that implements `RESTClient`, you may want to have an extension to present possible
/// APIs exposed by the server, such as the Timer API:
/// ```
/// class HostRESTClient: RESTClient {
///     ...
/// }
///
/// extension HostRESTClient {
///     public func timer<Value>(action endpoint: TimerEndpoint,
///                              parser: ResponseParser<Value>,
///                              completion: @escaping (Result<Value, Error>) -> Void) {
///        ...
///     }
/// }
/// ```
///
/// That way, any instance of HostRESTClient will be able to perform requests to the timer service running on the Host.
public protocol RESTClient {
    /// Default port for this Network Client. Endpoints can override this port.
    var defaultPort: UInt16 { get }

    /// Whether or not to use SSL by default. This can be overriden by the endpoint.
    var defaultUseSSL: Bool { get }

    /// Server IP address or hostname.
    var hostname: String { get }

    /// Headers required by the host to be sent in any request, regardless of the endpoint.
    var requiredHeaders: [String: String] { get }

    /// Query parameters (URL parameters) required by the host to be sent in any request, regardless of the endpoint.
    var requiredQueryParameters: [QueryParameter] { get }

    /// URL Session to be used for all requests.
    var session: URLSessionProtocol { get }

    /// Status code handler that checks the HTTP response to decide if the status code is within the expected range.
    /// When nil, the default rule will be used
    var statusCodeHandler: StatusCodeHandler? { get }

    /// Initializes a new REST Client from the hostname (or IP address) and an URLSessionProtocol to be used. In this case, any rule regarding
    /// certificates should be done by whom provided that URLSessionProtocol.
    ///
    /// - Parameters:
    ///   - hostname: hostname or IP address
    ///   - session: a URL Session to be used in all requests
    init(hostname: String, session: URLSessionProtocol)
}

extension RESTClient {
    /// Initializes a new REST Client from the host (name/IP) and a boolean that indicates whether or not the certificate validation is bypassed.
    /// If allowing any certificate is true, then a new URLSession will be created having the default configurations but with the delegate set to
    /// `BypassCertificateValidation`,
    /// otherwise the `URLSession.shared` will be used
    ///
    /// - Parameters:
    ///   - host: host name or IP address
    ///   - allowAnyCertificate: when true, it's bypass certificate validation (self-signed certificates will be allowed)
    public init(hostname: String, allowAnyCertificate: Bool = false) {
        if allowAnyCertificate {
            let bypass = BypassCertificateValidation()
            self.init(hostname: hostname, session: URLSession(configuration: URLSession.shared.configuration, delegate: bypass, delegateQueue: nil))
        } else {
            self.init(hostname: hostname, session: URLSession.shared)
        }
    }

    /// The protocol to be used when communicating with the server, it depends on SSL configuration.
    ///
    /// - Parameter ssl: using SSL or not
    /// - Returns: the scheme for the corresponding network client and SSL configuration.
    public func scheme(ssl: Bool) -> String {
        return ssl ? "https" : "http"
    }
}

extension RESTClient {
    /// Common request endpoint operation, can be used by methods that are strongly-typed to specific Endpoints
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to fetch
    ///   - requestParser: parser that transforms the Encodable body into binary data to be sent during the request
    ///   - responseParser: parser that transforms the Decodable body from the response into a model object
    /// - Returns: a Promise that may return a value, generic over the provided type parameter
    public func request<Body, Value, Endpoint: RESTEndpoint>(
        endpoint: Endpoint,
        requestParser: RequestParser<Body> = .ignore,
        responseParser: ResponseParser<Value>
    ) -> AnyPublisher<Value, Error> where Body == Endpoint.Body {
        let statusCodeHandler = endpoint.statusCodeHandler ?? self.statusCodeHandler ?? .default
        let scopedSession = session

        return
            createURLRequest(endpoint: endpoint, requestParser: requestParser)
                .promise
                .flatMap { urlRequest -> Publishers.MapError<TeufelDataTaskPublisher, Error> in
                    scopedSession.dataTaskPublisher(request: urlRequest).mapError { $0 as Error }
                }
                .flatMap { taskResult -> Promise<(Data, HTTPURLResponse), Error> in
                    statusCodeHandler
                        .eval(taskResult.response as? HTTPURLResponse)
                        .map { httpResponse in
                            return (taskResult.data, httpResponse)
                        }
                        .promise
                }
                .flatMap { data, httpResponse -> Promise<Value, Error> in
                    responseParser.parse(data, httpResponse).promise
                }
                .eraseToAnyPublisher()
    }
}

extension RESTClient {
    public func longPollingRequest<Body, Value, Endpoint: RESTEndpoint>(
        endpoint: Endpoint,
        requestParser: RequestParser<Body> = .ignore,
        responseParser: ResponseParser<Value>
    ) -> AnyPublisher<Value, Error> where Body == Endpoint.Body {
        let statusCodeHandler = endpoint.statusCodeHandler ?? self.statusCodeHandler ?? .default
        let scopedSession = session

        return createURLRequest(endpoint: endpoint, requestParser: requestParser)
            .promise
            .map { urlRequest in
                scopedSession
                    .longPollingPublisher(for: urlRequest)
                    .mapError { $0 as Error }
            }
            .switchToLatest()
            .flatMap { taskResult -> Promise<(Data, HTTPURLResponse), Error> in
                let (data, response) = taskResult
                return statusCodeHandler
                    .eval(response as? HTTPURLResponse)
                    .map { httpResponse in
                        return (data, httpResponse)
                    }
                    .promise
            }
            .flatMap { data, httpResponse -> Promise<Value, Error> in
                responseParser.parse(data, httpResponse).promise
            }
            .eraseToAnyPublisher()
    }
}

extension RESTClient {

    /// Create an failable URLRequest given an Endpoint and a request body parser.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to fetch
    ///   - requestParser: the parser used to encode the body
    /// - Returns: result of either: an URLRequest or an error in case something went wrong during the URLRequest creation
    public func createURLRequest<Body, Endpoint: RESTEndpoint>(
        endpoint: Endpoint,
        requestParser: RequestParser<Body> = .ignore
    ) -> Result<URLRequest, Error> where Endpoint.Body == Body {
        let urlRequestCreator = URLRequestCreator<Body>(endpoint: endpoint, client: self)
        return urlRequestCreator.createURLRequest(requestParser: requestParser)
    }
}

extension URLRequestCreator {
    init<Endpoint: RESTEndpoint>(endpoint: Endpoint, client: RESTClient) where Endpoint.Body == Body {
        self.port = Int(endpoint.port.possibleValue ?? client.defaultPort)
        let useSSL = endpoint.useSSL ?? client.defaultUseSSL
        self.scheme = client.scheme(ssl: useSSL)
        self.hostname = client.hostname
        self.headers = client.requiredHeaders.merging(endpoint.headers, uniquingKeysWith: { $1 })
        self.queryParameters = client.requiredQueryParameters + endpoint.queryParameters
        self.path = endpoint.path
        self.method = endpoint.method
        self.body = endpoint.body
    }
}
