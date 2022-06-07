//
//  SSLManager.swift
//  LeapSDK
//
//  Created by Ajay S on 06/01/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

class LeapSSLManager: NSObject {

     static let shared = LeapSSLManager()

     private lazy var certificates: [Data] = {
         let bundle = Bundle(for: type(of: self))
         guard let url = bundle.url(forResource: constant_Leap, withExtension: constant_cer) else { return [] }
         let data = try! Data(contentsOf: url)
         return [data]
     }()

     var session: URLSession!

     override init() {
         super.init()
         session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
     }

     func isValidForSSLPinning(urlString: String) -> Bool {

         var checkingResult = [NSTextCheckingResult]()

         do {
             let regExp = try NSRegularExpression(pattern: constant_leapDomainPattern, options: .caseInsensitive)
             let range = NSRange(location: 0, length: urlString.count)
             checkingResult = regExp.matches(in: urlString, options: .reportCompletion, range: range)
         } catch {
             print(error.localizedDescription)
         }

         return checkingResult.count > 0
     }
 }

 // MARK: - URLSessionDelegate
 extension LeapSSLManager: URLSessionDelegate {
     func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
         if let trust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0 {
             if let certificate = SecTrustGetCertificateAtIndex(trust, 0) {
                 let data = SecCertificateCopyData(certificate) as Data
                 if certificates.contains(data) {
                     completionHandler(.useCredential, URLCredential(trust: trust))
                     return
                 }
             }
         }
         completionHandler(.cancelAuthenticationChallenge, nil)
     }
 }
