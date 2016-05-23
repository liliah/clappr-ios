import Foundation

public class MediaControl: UIBaseObject {
    private let animationDuration = 0.3
    
    @IBOutlet weak var seekBarView: UIView?
    @IBOutlet weak var bufferBarView: UIView?
    @IBOutlet weak var progressBarView: UIView?
    @IBOutlet weak var scrubberLabel: UILabel?
    @IBOutlet weak var scrubberView: UIView?


    @IBOutlet weak var scrubberDragger: UIPanGestureRecognizer?
    @IBOutlet weak var bufferBarWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint?

    @IBOutlet weak public var durationLabel: UILabel?
    @IBOutlet weak public var currentTimeLabel: UILabel?

    @IBOutlet weak public var controlsOverlayView: GradientView?
    @IBOutlet weak public var controlsWrapperView: UIView?
    @IBOutlet weak public var playbackControlButton: UIButton?
    
    public internal(set) var container: Container!
    public internal(set) var controlsHidden = false
    
    private var bufferPercentage: CGFloat = 0.0
    private var seekPercentage: CGFloat = 0.0
    private var scrubberInitialPosition: CGFloat!
    private var hideControlsTimer: NSTimer!
    private var enabled = false
    private var livePlayback = false
    
    public lazy var liveProgressBarColor = UIColor.redColor()
    public lazy var vodProgressBarColor = UIColor.blueColor()
    public lazy var playButtonImage: UIImage? = self.imageFromName("play")
    public lazy var pauseButtonImage: UIImage? = self.imageFromName("pause")
    public lazy var stopButtonImage: UIImage? = self.imageFromName("stop")
    
    public var playbackControlState: PlaybackControlState = .Stopped {
        didSet {
            updatePlaybackControlButtonIcon()
        }
    }
    
    private var isSeeking = false {
        didSet {
            scrubberLabel?.hidden = !isSeeking
        }
    }
    
    private var duration: CGFloat {
        get {
            return CGFloat(container.playback.duration())
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    public class func loadNib() -> UINib {
        return UINib(nibName: "MediaControlView", bundle: NSBundle(forClass: MediaControl.self))
    }
    
    public class func initFromNib() -> MediaControl {
        let mediaControl = loadNib().instantiateWithOwner(self, options: nil).last as! MediaControl
        mediaControl.scrubberInitialPosition = mediaControl.progressBarWidthConstraint?.constant ?? 0
        mediaControl.hide()
        mediaControl.bindOrientationChangedListener()
        return mediaControl
    }

    private func imageFromName(name: String) -> UIImage? {
        return UIImage(named: name, inBundle: NSBundle(forClass: MediaControl.self), compatibleWithTraitCollection: nil)
    }
    
    private func updatePlaybackControlButtonIcon() {
        var image: UIImage?
        
        if playbackControlState == .Playing {
            image = livePlayback ? stopButtonImage : pauseButtonImage
        } else {
            image = playButtonImage
        }
        
        playbackControlButton?.setBackgroundImage(image, forState: .Normal)
    }
    
    private func bindOrientationChangedListener() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaControl.didRotate),
            name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func didRotate() {
        updateBars()
        updateScrubberPosition()
    }
    
    public func setup(container: Container) {
        stopListening()
        self.container = container
        bindEventListeners()
        container.mediaControlEnabled ? enable() : disable()
        playbackControlState = container.isPlaying ? .Playing : .Stopped
    }
    
    private func bindEventListeners() {
        for (event, callback) in eventBindings() {
            listenTo(container, eventName: event.rawValue, callback: callback)
        }
    }
    
    private func eventBindings() -> [ContainerEvent : EventCallback] {
        return [
            .Play       : { [weak self] (info: EventUserInfo) in self?.triggerPlay() },
            .Pause      : { [weak self] (info: EventUserInfo) in self?.triggerPause() },
            .Ready      : { [weak self] (info: EventUserInfo) in self?.containerReady() },
            .TimeUpdated: { [weak self] (info: EventUserInfo) in self?.timeUpdated(info) },
            .Progress   : { [weak self] (info: EventUserInfo) in self?.progressUpdated(info) },
            .Ended      : { [weak self] (info: EventUserInfo) in self?.playbackControlState = .Stopped },
            .MediaControlDisabled : { [weak self] (info: EventUserInfo) in self?.disable() },
            .MediaControlEnabled  : { [weak self] (info: EventUserInfo) in self?.enable() },
        ]
    }
    
    private func triggerPlay() {
        playbackControlState = .Playing
        trigger(.Playing)
    }
    
    private func triggerPause() {
        playbackControlState = .Paused
        trigger(.NotPlaying)
    }
    
    private func disable() {
        enabled = false
        hide()
    }
    
    private func enable() {
        enabled = true
        show()
    }
    
    private func timeUpdated(info: EventUserInfo) {
        guard let position = info!["position"] as? NSTimeInterval where !livePlayback else {
            return
        }
        
        currentTimeLabel?.text = DateFormatter.formatSeconds(position)
        seekPercentage = duration == 0 ? 0 : CGFloat(position) / duration
        updateScrubberPosition()
    }
    
    private func progressUpdated(info: EventUserInfo) {
        guard let end = info!["end_position"] as? CGFloat where !livePlayback else {
            return
        }
        
        bufferPercentage = duration == 0 ? 0 : end / duration
        updateBars()
    }
    
    private func updateScrubberPosition() {
        if let scrubberView = self.scrubberView as? ScrubberView,
            let seekBarView = self.seekBarView where !isSeeking {
            let delta = (CGRectGetWidth(seekBarView.frame) - scrubberView.innerCircle.frame.width) * seekPercentage
            progressBarWidthConstraint?.constant = delta + scrubberInitialPosition
            scrubberView.setNeedsLayout()
            progressBarView?.setNeedsLayout()
        }
    }
    
    private func updateBars() {
        if let seekBarView = self.seekBarView,
            let bufferBarWidthConstraint = self.bufferBarWidthConstraint {
            bufferBarWidthConstraint.constant = seekBarView.frame.size.width * bufferPercentage
            bufferBarView?.layoutIfNeeded()
        }
    }
    
    private func containerReady() {
        livePlayback = container.playback.playbackType() == .Live
        livePlayback ? setupForLive() : setupForVOD()
        updateBars()
        updateScrubberPosition()
        updatePlaybackControlButtonIcon()
    }
    
    private func setupForLive() {
        seekPercentage = 1
        progressBarView?.backgroundColor = liveProgressBarColor
        scrubberDragger?.enabled = false
    }
    
    private func setupForVOD() {
        progressBarView?.backgroundColor = vodProgressBarColor
        durationLabel?.text = DateFormatter.formatSeconds(container.playback.duration())
        scrubberDragger?.enabled = true
    }
    
    public func hide() {
        setSubviewsVisibility(hidden: true)
    }
    
    public func show() {
        setSubviewsVisibility(hidden: false)
    }

    public func showAnimated() {
        setSubviewsVisibility(hidden: false, animated: true)
    }
    
    public func hideAnimated() {
        setSubviewsVisibility(hidden: true, animated: true)
    }
    
    private func setSubviewsVisibility(hidden hidden: Bool, animated: Bool = false) {
        if (!hidden && !enabled) {
            return
        }
        
        let duration = animated ? animationDuration : 0
        
        UIView.animateWithDuration(duration, animations: {
            for subview in self.subviews {
                subview.alpha = hidden ? 0 : 1
            }
        })
        
        userInteractionEnabled = !hidden
        controlsHidden = hidden
    }
    
    public func toggleVisibility() {
        controlsHidden ? showAnimated() : hideAnimated()
    }

    @IBAction func togglePlay(sender: UIButton) {
        if playbackControlState == .Playing {
            livePlayback ? stop() : pause()
        } else {
            play()
            scheduleTimerToHideControls()
        }
    }
    
    private func pause() {
        playbackControlState = .Paused
        container.pause()
        trigger(MediaControlEvent.NotPlaying.rawValue)
    }
    
    private func play() {
        playbackControlState = .Playing
        container.play()
        trigger(MediaControlEvent.Playing.rawValue)
    }
    
    private func stop() {
        playbackControlState = .Stopped
        container.stop()
        trigger(MediaControlEvent.NotPlaying.rawValue)
    }
    
    private func scheduleTimerToHideControls() {
        hideControlsTimer = NSTimer.scheduledTimerWithTimeInterval(3.0,
            target: self, selector: #selector(MediaControl.hideAfterPlay), userInfo: nil, repeats: false)
    }
    
    func hideAfterPlay() {
        if container.isPlaying {
            hideAnimated()
        }
        
        hideControlsTimer.invalidate()
    }
    
    @IBAction func handleScrubberPan(panGesture: UIPanGestureRecognizer) {
        let touchPoint = panGesture.locationInView(seekBarView)
        
        switch panGesture.state {
        case .Began:
            isSeeking = true
        case .Changed:
            progressBarWidthConstraint?.constant = touchPoint.x + scrubberInitialPosition
            scrubberLabel?.text = DateFormatter.formatSeconds(secondsRelativeToPoint(touchPoint))
            scrubberView?.setNeedsLayout()
        case .Ended:
            container.seekTo(secondsRelativeToPoint(touchPoint))
            isSeeking = false
        default: break
        }
    }
    
    private func secondsRelativeToPoint(touchPoint: CGPoint) -> Double {
        if let seekBarView = self.seekBarView {
            let positionPercentage = touchPoint.x / seekBarView.frame.size.width
            return Double(duration * positionPercentage)
        }
        return 0
    }

    private func trigger(event: MediaControlEvent) {
        trigger(event.rawValue)
    }
    
    deinit {
        stopListening()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}