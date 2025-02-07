//
//  URLSessionProtocol.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Combine
import Foundation
import FoundationExtensions

/// A protocol to abstract `URLSession`, it makes easier to mock requests and responses.
public protocol URLSessionProtocol {
    func dataTaskPromise(url: URL) -> Promise<(data: Data, response: URLResponse), URLError>
    func dataTaskPromise(request: URLRequest) -> Promise<(data: Data, response: URLResponse), URLError>
    func resilientDataTaskPromise(url: URL) -> Promise<(data: Data, response: URLResponse), URLError>
    func resilientDataTaskPromise(request: URLRequest) -> Promise<(data: Data, response: URLResponse), URLError>
    var timeoutIntervalForResource: TimeInterval { get }
    var timeoutIntervalForRequest: TimeInterval { get }
}

extension URLSession: URLSessionProtocol {
    public func dataTaskPromise(url: URL) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: url).eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }

    public func dataTaskPromise(request: URLRequest) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }

    public func resilientDataTaskPromise(url: URL) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: url).hardenAgainstATS()
    }

    public func resilientDataTaskPromise(request: URLRequest) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).hardenAgainstATS()
    }

    public var timeoutIntervalForRequest: TimeInterval {
        configuration.timeoutIntervalForRequest
    }

    public var timeoutIntervalForResource: TimeInterval {
        configuration.timeoutIntervalForResource
    }
}

extension URLSession.DataTaskPublisher {
    fileprivate func hardenAgainstATS() -> Promise<(data: Data, response: URLResponse), URLError> {
        eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
            .catch { urlError in
                // ATS blocks http-URLs. We catch the error and retry with an https-URL
                if urlError.code == URLError.appTransportSecurityRequiresSecureConnection, let url = self.request.url {
                    var atsRequest = self.request
                    atsRequest.url = Self.forceHttps(url: url)
                    return self.session.dataTaskPromise(request: atsRequest)
                }
                return Promise(error: urlError)
            }
    }

    /// Rewrites an http-URL to an https-URL.
    private static func forceHttps(url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true), components.scheme == "http" else {
            return url
        }

        components.scheme = "https"
        if let httpsSubstitutedURL = components.url {
            return httpsSubstitutedURL
        }
        return url
    }
}

#if DEBUG
public final class URLSessionMock {
    public init() { }

    /// Mockables
    public var timeoutIntervalForResource: TimeInterval = 1
    public var timeoutIntervalForRequest: TimeInterval = 1
    public var dataTaskPassthrough = PassthroughSubject<(data: Data, response: URLResponse), URLError>()

    public lazy var dataTaskPromiseURL: (URL) -> Promise<(data: Data, response: URLResponse), URLError> = { url in
        self.dataTaskPassthrough.eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }
    public lazy var dataTaskPromiseURLRequest: (URLRequest) -> Promise<(data: Data, response: URLResponse), URLError> = { request in
        self.dataTaskPassthrough.eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }
    public lazy var resilientDataTaskPromiseURL: (URL) -> Promise<(data: Data, response: URLResponse), URLError> = { url in
        self.dataTaskPassthrough.eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }
    public lazy var resilientDataTaskPromiseURLRequest: (URLRequest) -> Promise<(data: Data, response: URLResponse), URLError> = { request in
        self.dataTaskPassthrough.eraseToPromise(onEmpty: .failure(URLError(.cancelled)))
    }
    public func serverSendsDataSuccess(
        data: Data = Data(),
        response: URLResponse = HTTPURLResponse(url: URL(string: "https://127.0.0.1")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        completes: Bool = true
    ) {
        dataTaskPassthrough.send((data: data, response: response))
        if completes { dataTaskPassthrough.send(completion: .finished) }
    }

    public func serverSendsDataFailure(_ error: URLError) {
        dataTaskPassthrough.send(completion: .failure(error))
    }
}

/// Conformance to URLSessionProtocol
extension URLSessionMock: URLSessionProtocol {

    public func dataTaskPromise(url: URL) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPromiseURL(url)
    }
    public func dataTaskPromise(request: URLRequest) -> Promise<(data: Data, response: URLResponse), URLError> {
        dataTaskPromiseURLRequest(request)
    }
    public func resilientDataTaskPromise(url: URL) -> Publishers.Promise<(data: Data, response: URLResponse), URLError> {
        resilientDataTaskPromiseURL(url)
    }
    public func resilientDataTaskPromise(request: URLRequest) -> Publishers.Promise<(data: Data, response: URLResponse), URLError> {
        resilientDataTaskPromiseURLRequest(request)
    }
}
#endif
