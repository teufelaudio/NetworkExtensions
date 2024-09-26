//
//  BypassCertificateValidation.swift
//  NetworkExtensions
//
//  Created by Luiz Barbosa on 21.02.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

/// An `URLSessionDelegate` that trusts by default any certificate, even self-signed ones
public final class BypassCertificateValidation: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                         didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        }
    }
}

extension URLSession {
    /// Initializes a new URLSession ignoring when the certificate validation is bypassed.
    /// A new URLSession will be created having the default configurations but with the delegate set to `BypassCertificateValidation`
    ///
    public static var sharedIgnoringCertificateValidation: URLSession {
        URLSession(configuration: URLSession.shared.configuration, delegate: BypassCertificateValidation(), delegateQueue: nil)
    }
}
