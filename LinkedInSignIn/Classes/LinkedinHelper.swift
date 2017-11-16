//
//  LinkedinHelper.swift
//  LISignIn
//
//  Created by Serhii Londar on 11/16/17.
//  Copyright © 2017 Appcoda. All rights reserved.
//

import Foundation
import UIKit

enum LinkedinHelperError: Error {
    case error(String)
}

public class LinkedinHelper: NSObject {
    var linkedInConfig: LinkedInConfig! = nil
    
    var completion: ((String) -> Void)? = nil
    var failure: ((Error) -> Void)? = nil
    
    let accessTokenEndPoint = "https://www.linkedin.com/uas/oauth2/accessToken"
    
    public init(linkedInConfig: LinkedInConfig) {
        self.linkedInConfig = linkedInConfig
    }
    
    public func login(from viewController: UIViewController, completion: @escaping (String) -> Void, failure: @escaping (Error) -> Void) {
        self.completion = completion
        self.failure = failure
        
        let storyboard = UIStoryboard(name: "LinkedInLoginVC", bundle: Bundle(for: LinkedInLoginVC.self))
        let linkedInLoginVC = storyboard.instantiateViewController(withIdentifier: "LinkedInLoginVC") as! LinkedInLoginVC
        linkedInLoginVC.loadViewIfNeeded()
        linkedInLoginVC.login(linkedInConfig: linkedInConfig, completion: { (code) in
            self.requestForAccessToken(authorizationCode: code)
        }, failure: failure)
        viewController.present(linkedInLoginVC, animated: true, completion: nil)
    }
}


extension LinkedinHelper {
    func failure(_ error: Error) {
        if let failure = failure {
            failure(LinkedInLoginError.error(error.localizedDescription))
        }
    }
    
    func failure(_ error: String) {
        if let failure = failure {
            failure(LinkedInLoginError.error(error))
        }
    }
    
    func completion(_ accessToken: String) {
        if let completion = completion {
            completion(accessToken)
        }
    }
}


extension LinkedinHelper {
    func requestForAccessToken(authorizationCode: String) {
        let grantType = "authorization_code"
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(linkedInConfig.redirectURL)&"
        postParams += "client_id=\(linkedInConfig.linkedInKey)&"
        postParams += "client_secret=\(linkedInConfig.linkedInSecret)"
        
        let postData = postParams.data(using: String.Encoding.utf8)
        var request = URLRequest(url: URL(string: accessTokenEndPoint)!)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) -> Void in
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: Any]
                    if let accessToken = dataDictionary["access_token"] as? String {
                        self.completion(accessToken)
                    } else {
                        self.failure("Could not get access_token from json")
                    }
                } catch {
                    self.failure("Could not convert JSON data into a dictionary.")
                }
            } else {
                self.failure("Received error with code: \(statusCode)")
            }
        }
        task.resume()
    }
}
