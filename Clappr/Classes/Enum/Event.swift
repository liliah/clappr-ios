public enum Event: String {
    case bufferUpdate
    case positionUpdate
    case ready
    case stalled
    case willUpdateAudioSource
    case didUpdateAudioSource
    case willUpdateSubtitleSource
    case didUpdateSubtitleSource
    case disableMediaControl
    case enableMediaControl
    case didComplete
    case willPlay
    case playing
    case willPause
    case didPause
    case willStop
    case didStop
    case error
    case airPlayStatusUpdate
    case requestFullscreen
    case exitFullscreen
    case requestPosterUpdate
    case willUpdatePoster
    case didUpdatePoster
}
