
import Foundation
import AVFoundation

// https://medium.com/@evandro.hoffmann/fading-volume-with-avplayer-in-swift-74cbcc6172c6

/*
extension AVPlayer {
  /// Fades player volume FROM any volume TO any volume
  /// - Parameters:
  ///   - from: initial volume
  ///   - to: target volume
  ///   - duration: duration in seconds for the fade
  ///   - completion: callback indicating completion
  /// - Returns: Timer?
  func fadeVolume(from: Float, to: Float, duration: Float, completion: (() -> Void)? = nil) -> Timer? {
    volume = from
    // There's nothing to fade if target volume is the same as initial
    guard from != to else { return nil }
    // 1. We define the time interval the interaction will loop into (fraction of a second)
    let interval: Float = 0.1
    // 2. Set the range the volume will move
    let range = to-from
    // 3. Based on the range, the interval and duration, we calculate how big is the step we need to take in order to reach the target in the given duration
    let step = (range*interval)/duration
    
    // 1. internal function whether the target has been reached or not
    func reachedTarget() -> Bool {
      // 2. volume passed max/min
      
      guard volume >= 0, volume <= 1 else {
        volume = to
        return true
      }
      // 3. checks whether the volume is going forward or backward and compare current volume to target
      if to > from {
        return volume >= to
      }
      return volume <= to
    }
    
    // 1. We create a timer that will repeat itself with the given interval
    return Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true, block: { [weak self] (timer) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        // 2. Check if we reached the target, otherwise we add the volume
        if !reachedTarget() {
          // note that if the step is negative, meaning that the to value is lower than the from value, the volume will be decreased instead
          self.volume += step
        } else {
          timer.invalidate()
          completion?()
        }
      }
    })

  }
    
}

*/

/*
 private lazy var player: AVPlayer = .init()
 private var fadeTimer: Timer?
 private func setupPlayer() {
   // Setup player
   let url = URL(string: "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3")!
   let item = AVPlayerItem(url: url)
   player.replaceCurrentItem(with: item)
   player.volume = 0
   player.play()
   // Fade player volume from 0 to 1 in 5 seconds
   fadeTimer = player.fadeVolume(from: 0, to: 1, duration: 5)
 }
 */
