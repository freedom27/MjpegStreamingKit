//
//  ViewController.swift
//  DemoApp
//
//  Created by Stefano Vettor on 28/03/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit
import MjpegStreamingKit

class ViewController: UIViewController {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var url: URL?
    
    var playing = false
    
    var streamingController: MjpegStreamingController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        streamingController = MjpegStreamingController(imageView: imageView)
        streamingController.didStartLoading = { [unowned self] in
            self.loadingIndicator.startAnimating()
        }
        streamingController.didFinishLoading = { [unowned self] in
            self.loadingIndicator.stopAnimating()
        }
        
        url = URL(string: "http://webcams.hotelcozumel.com.mx:6003/axis-cgi/mjpg/video.cgi?resolution=320x240&dummy=1458771208837")
        streamingController.contentURL = url
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playAndStop(sender: AnyObject) {
        if playing {
            playButton.setTitle("Play", for: .normal)
            streamingController.stop()
            playing = false
        } else {
            
            streamingController.play()
            playing = true
            playButton.setTitle("Stop", for: .normal)
        }
    }
    
    
}


