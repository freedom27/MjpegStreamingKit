//
//  MjpegStreamingController.swift
//  MjpegStreamingKit
//
//  Created by Stefano Vettor on 28/03/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit

public class MjpegStreamingController: NSObject, NSURLSessionDataDelegate {
    
    private enum Status {
        case Stopped
        case Loading
        case Playing
    }
    
    private var receivedData: NSMutableData?
    private var dataTask: NSURLSessionDataTask?
    private var session: NSURLSession!
    private var status: Status = .Stopped
    
    public var authenticationHandler: ((NSURLAuthenticationChallenge) -> (NSURLSessionAuthChallengeDisposition, NSURLCredential?))?
    public var didStartLoading: (()->Void)?
    public var didFinishLoading: (()->Void)?
    public var contentURL: NSURL?
    public var imageView: UIImageView
    
    public init(imageView: UIImageView) {
        self.imageView = imageView
        super.init()
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    public convenience init(imageView: UIImageView, contentURL: NSURL) {
        self.init(imageView: imageView)
        self.contentURL = contentURL
    }
    
    deinit {
        dataTask?.cancel()
    }
    
    public func play(url url: NSURL){
        if status == .Playing || status == .Loading {
            stop()
        }
        contentURL = url
        play()
    }
    
    public func play() {
        guard let url = contentURL where status == .Stopped else {
            return
        }
        
        status = .Loading
        dispatch_async(dispatch_get_main_queue()) { self.didStartLoading?() }
        
        receivedData = NSMutableData()
        let request = NSURLRequest(URL: url)
        dataTask = session.dataTaskWithRequest(request)
        dataTask?.resume()
    }
    
    public func stop(){
        status = .Stopped
        dataTask?.cancel()
    }
    
    // MARK: - NSURLSessionDataDelegate
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        if let imageData = receivedData where imageData.length > 0,
            let receivedImage = UIImage(data: imageData) {
            // I'm creating the UIImage before performing didFinishLoading to minimize the interval
            // between the actions done by didFinishLoading and the appearance of the first image
            if status == .Loading {
                status = .Playing
                dispatch_async(dispatch_get_main_queue()) { self.didFinishLoading?() }
            }
            
            dispatch_async(dispatch_get_main_queue()) { self.imageView.image = receivedImage }
        }
        
        receivedData = NSMutableData()
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        receivedData?.appendData(data)
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        var credential: NSURLCredential?
        var disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trust = challenge.protectionSpace.serverTrust {
                credential = NSURLCredential(trust: trust)
                disposition = .UseCredential
            }
        } else if let onAuthentication = authenticationHandler {
            (disposition, credential) = onAuthentication(challenge)
        }
        
        completionHandler(disposition, credential)
    }
}
