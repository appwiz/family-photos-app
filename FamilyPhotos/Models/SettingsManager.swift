import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // Settings keys - must match Settings.bundle Root.plist
    static let slideshowDelayKey = "slideshow_delay"
    static let autoPlayVideosKey = "autoplay_videos"
    static let defaultSlideshowDelay: Double = 5.0
    
    @Published var slideshowDelay: Double {
        didSet {
            UserDefaults.standard.set(slideshowDelay, forKey: SettingsManager.slideshowDelayKey)
        }
    }
    
    @Published var autoPlayVideos: Bool {
        didSet {
            UserDefaults.standard.set(autoPlayVideos, forKey: SettingsManager.autoPlayVideosKey)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Register defaults
        UserDefaults.standard.register(defaults: [
            SettingsManager.slideshowDelayKey: SettingsManager.defaultSlideshowDelay,
            SettingsManager.autoPlayVideosKey: true
        ])
        
        slideshowDelay = UserDefaults.standard.double(forKey: SettingsManager.slideshowDelayKey)
        if slideshowDelay < 1.0 { slideshowDelay = SettingsManager.defaultSlideshowDelay }
        
        autoPlayVideos = UserDefaults.standard.bool(forKey: SettingsManager.autoPlayVideosKey)
        
        // Listen for Settings app changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }
    
    private func reload() {
        let delay = UserDefaults.standard.double(forKey: SettingsManager.slideshowDelayKey)
        if delay >= 1.0 {
            slideshowDelay = delay
        }
        autoPlayVideos = UserDefaults.standard.bool(forKey: SettingsManager.autoPlayVideosKey)
    }
}
