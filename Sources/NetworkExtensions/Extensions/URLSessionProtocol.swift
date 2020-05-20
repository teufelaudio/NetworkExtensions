//
//  URLSessionProtocol.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Combine
import CombineLongPolling
import Foundation

/// A protocol to abstract `URLSession`, it makes easier to mock requests and responses.
public protocol URLSessionProtocol: LongPollingSessionProtocol {
    func dataTaskPublisher(url: URL) -> TeufelDataTaskPublisher
    func dataTaskPublisher(request: URLRequest) -> TeufelDataTaskPublisher
    var timeoutIntervalForResource: TimeInterval { get }
    var timeoutIntervalForRequest: TimeInterval { get }
}

extension URLSession: URLSessionProtocol {
    public func dataTaskPublisher(url: URL) -> TeufelDataTaskPublisher {
        dataTaskPublisher(request: URLRequest(url: url))
    }

    public func dataTaskPublisher(request: URLRequest) -> TeufelDataTaskPublisher {
        TeufelDataTaskPublisher(request: request, session: self)
    }

    public var timeoutIntervalForRequest: TimeInterval {
        configuration.timeoutIntervalForRequest
    }

    public var timeoutIntervalForResource: TimeInterval {
        configuration.timeoutIntervalForResource
    }
}

/// Equivalent to URLSession.DataTaskPublisher, but mockable
public struct TeufelDataTaskPublisher: Publisher {
    public typealias Output = (data: Data, response: URLResponse)
    public typealias Failure = URLError

    public let request: URLRequest
    public let session: URLSessionProtocol
    private let internalPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError>

    public init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
        self.internalPublisher = session.dataTaskPublisher(for: request).eraseToAnyPublisher()
    }

    public init<P: Publisher>(_ customPublisher: P, request: URLRequest, session: URLSessionProtocol)
    where P.Failure == Failure, P.Output == Output {
        self.request = request
        self.session = session
        self.internalPublisher = customPublisher.eraseToAnyPublisher()
    }

    public static func alwaysSucceeds(with output: (data: Data, response: URLResponse), request: URLRequest, session: URLSessionProtocol)
    -> TeufelDataTaskPublisher {
        TeufelDataTaskPublisher(Just(output).setFailureType(to: URLError.self), request: request, session: session)
    }

    public static func alwaysFails(with error: URLError, request: URLRequest, session: URLSessionProtocol) -> TeufelDataTaskPublisher {
        TeufelDataTaskPublisher(Fail(error: error), request: request, session: session)
    }

    public func receive<S: Subscriber>(subscriber: S)
    where S.Failure == Failure, S.Input == Output {
        internalPublisher.subscribe(subscriber)
    }
}

extension URLSessionProtocol {
    public func resilientDataTaskPublisher(url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        self.dataTaskPublisher(url: url)
            .hardenAgainstATS()
    }

    public func resilientDataTaskPublisher(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        self.dataTaskPublisher(request: request)
            .hardenAgainstATS()
    }
}

extension TeufelDataTaskPublisher {
    public func hardenAgainstATS() -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        self.catch { (urlError) -> TeufelDataTaskPublisher in
            // ATS blocks http-URLs. We catch the error and retry with an https-URL
            if urlError.code == URLError.appTransportSecurityRequiresSecureConnection, let url = self.request.url {
                var atsRequest = self.request
                atsRequest.url = Self.forceHttps(url: url)
                return self.session.dataTaskPublisher(request: atsRequest)
            }
            return TeufelDataTaskPublisher.alwaysFails(with: urlError, request: self.request, session: self.session)
        }.eraseToAnyPublisher()
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
    public var longPollingPassthrough = PassthroughSubject<(data: Data, response: URLResponse), URLError>()

    public lazy var dataTaskPublisherURL: (URL) -> TeufelDataTaskPublisher = { url in
        TeufelDataTaskPublisher(self.dataTaskPassthrough, request: URLRequest(url: url), session: self)
    }
    public lazy var dataTaskPublisherURLRequest: (URLRequest) -> TeufelDataTaskPublisher = { request in
        TeufelDataTaskPublisher(self.dataTaskPassthrough, request: request, session: self)
    }
    public lazy var longPollingPassthroughURL: (URL) -> LongPollingPublisher = { _ in
        LongPollingPublisher(dataTaskPublisher: self.longPollingPassthrough)
    }
    public lazy var longPollingPassthroughURLRequest: (URLRequest) -> LongPollingPublisher = { _ in
        LongPollingPublisher(dataTaskPublisher: self.longPollingPassthrough)
    }
    public lazy var longPollingPassthroughFromPublisher: (AnyPublisher<(data: Data, response: URLResponse), URLError>) -> LongPollingPublisher = { p in
        LongPollingPublisher(dataTaskPublisher: p)
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

    public func serverSendsLongPollingSuccess(
        data: Data = Data(),
        response: URLResponse = HTTPURLResponse(url: URL(string: "https://127.0.0.1")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        completes: Bool = false
    ) {
        longPollingPassthrough.send((data: data, response: response))
        if completes { longPollingPassthrough.send(completion: .finished) }
    }

    public func serverSendsLongPollingFailure(_ error: URLError) {
        longPollingPassthrough.send(completion: .failure(error))
    }
}

/// Conformance to URLSessionProtocol
extension URLSessionMock: URLSessionProtocol {
    public func dataTaskPublisher(url: URL) -> TeufelDataTaskPublisher {
        dataTaskPublisherURL(url)
    }
    public func dataTaskPublisher(request: URLRequest) -> TeufelDataTaskPublisher {
        dataTaskPublisherURLRequest(request)
    }
}

/// Conformance to LongPollingSessionProtocol
extension URLSessionMock {
    public func longPollingPublisher(for url: URL) -> LongPollingPublisher {
        longPollingPassthroughURL(url)
    }

    public func longPollingPublisher(for request: URLRequest) -> LongPollingPublisher {
        longPollingPassthroughURLRequest(request)
    }

    public func longPollingPublisher<P>(for dataTaskPublisher: P) -> LongPollingPublisher
    where P: Publisher, P.Failure == URLError, P.Output == (data: Data, response: URLResponse) {
        longPollingPassthroughFromPublisher(dataTaskPublisher.eraseToAnyPublisher())
    }
}
#endif
