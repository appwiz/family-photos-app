import SwiftUI
import Photos
import AVKit

struct VideoPlayerView: View {
    let asset: PHAsset
    let autoplay: Bool
    let onPlaybackEnded: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isLoading: Bool = true
    @State private var playerItem: AVPlayerItem?
    @State private var endObserver: Any?
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .task(id: asset.localIdentifier) {
            await loadVideo()
        }
        .onDisappear {
            player?.pause()
            if let token = endObserver {
                NotificationCenter.default.removeObserver(token)
                endObserver = nil
            }
        }
    }
    
    private func loadVideo() async {
        isLoading = true
        player = nil
        if let token = endObserver {
            NotificationCenter.default.removeObserver(token)
            endObserver = nil
        }
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                guard let item = item else {
                    continuation.resume()
                    return
                }
                
                Task { @MainActor in
                    self.playerItem = item
                    self.player = AVPlayer(playerItem: item)
                    self.isLoading = false
                    
                    self.endObserver = NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: item,
                        queue: .main
                    ) { _ in
                        self.onPlaybackEnded()
                    }
                    
                    if self.autoplay {
                        self.player?.play()
                    }
                    continuation.resume()
                }
            }
        }
    }
}
