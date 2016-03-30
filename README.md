# MjpegStreamingKit
MjpegStreamingKit is a small iOS framework providing a view controller for UIImageView to play mjpeg video streams 
with content type _multipart/x-mixed-replace_ within it.

## How to use
Using this controller is quite simple... all you have to do is to import the framework, initialize it with an __UIImageView__ and call the __*play()*__ method:
```swift
import MjpegStreamingKit

let imageView = UIImageView(frame: rect)
let streamingController = MjpegStreamingController(imageView: imageView)
// To play url do:
let url = NSURL(string: "http://mjpeg.streaming.url/movie.mjpeg")
streamingController.play(url: url!)

// As an alternative you could do as well:
let imageView = UIImageView(frame: rect)
let streamingController = MjpegStreamingController(imageView: imageView)
streamingController.contentURL = NSURL(string: "http://mjpeg.streaming.url/movie.mjpeg")
streamingController.play() // if contentURL is not nul it will be played

// Or directly init the controller with both the imageView and the url
let imageView = UIImageView(frame: rect)
let url = NSURL(string: "http://mjpeg.streaming.url/movie.mjpeg")
let streamingController = MjpegStreamingController(imageView: imageView, contentURL: url!)
streamingController.play()
```
There is a slight difference between __*play(url: NSURL)*__ and __*play()*__:
  * __play(url: NSURL):__ when called if another video is playing it will be stopped and the new source will start
  * __play():__ when called if another video is playing nothing will happen, otherwise it will start reproducing the contentURL

To stop a video all you need to do is to call the __*stop()*__ method:
```swift
streamingController.stop() // this will stop the video and the data transfer
```

## Initialize with Interface Builder
You can of course create the __UIImageView__ with interface builder (an __IBOutlet__) and initialize the __MjpegStreamingController__ with it.

## Performing actions during the *loading* time
__MjpegStreamingController__ has two properties that can be set to perform actions at the beginning and at the end of the loading time:
  * __var didStartLoading: (()->Void)?:__ this closure is called right after the __*play()*__ method has been invoked and should be used to set-up whatever should happen while the stream is loading (like displaying an activity indicator and start its animation)
  * __var didFinishLoading: (()->Void)?:__ this closure is called right before displaying the first frame of the video stream and should be use to undo what was done by __*didStartLoading*__ (like stopping the anipation of the activity indicator and hide it)
```swift
class ViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  
  var streamingController: MjpegStreamingController!
    
  override func viewDidLoad() {
    super.viewDidLoad()
    streamingController.didStartLoading = { [unowned self] in
      self.loadingIndicator.hidden = false
      self.loadingIndicator.startAnimating()
    }
    streamingController.didFinishLoading = { [unowned self] in
      self.loadingIndicator.stopAnimating()
      self.loadingIndicator.hidden = true
    }
  }
  
  ...
}
```

These two properties are completely optionals hence you are free to ignore them

## Authentication
If when attempting to connect MjpegStreamingController receive an authentication challenge it will try to handle it in different ways depending on the authentication type and if the authenticationHandler is set:
  * authentication type is __NSURLAuthenticationMethodServerTrust:__ usually happening if the url is using *https* instead of *http*, this case is automatically handled and no action is required
  * __any other authentication type:__ in this case it checks if the closure __*authenticationHandler*__ is set:
    * if it's set then it calls it passing in input the authentication challange, it will be then up to the closure to provide the NSURLSessionAuthChallengeDisposition and NSURLCredential to continue with the authentication process
    * if it's not set MjpegStreamingController will fallback on the default behaviour of a NSURLSession in case of authentication challenges

Here it is an example of how to implement a custom authentication handler:
```swift
streamingController.authenticationHandler = { challenge in
  // Checking if credentials are available in key chain
  if let credentials = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(challenge.protectionSpace) where credentials.count > 0 {
    return (.UseCredential, credentials.values.first)
  } else { // if not already available generate a credentials object to use
    let credentials:  NSURLCredential? = self.retrieveCredentials() // a method that is creating NSURLCredential object
    return (.UseCredential, credentials)
  } 
}
```

A simple way to deal with __*HTTP Basic Auth*__ without having to provide an authentication handler is to put the credentials directly inside the url as follow:
```swift
streamingController.contentURL = NSURL(string: "http://username:password@mjpeg.streaming.url/movie.mjpeg")
```
