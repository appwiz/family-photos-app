import SwiftUI
import Photos

struct SlideshowView: View {
    @ObservedObject var photoManager: PhotoLibraryManager
    let albumIdentifier: String
    
    @StateObject private var settings = SettingsManager.shared
    @State private var assets: [PHAsset] = []
    @State private var currentIndex: Int = 0
    @State private var timer: Timer?
    @State private var isShowingControls: Bool = true
    @State private var isPaused: Bool = false
    @State private var showChangeAlbumConfirm: Bool = false
    @AppStorage("selectedAlbumIdentifier") private var selectedAlbumIdentifier: String = ""
    
    var currentAsset: PHAsset? {
        guard !assets.isEmpty, currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Photos",
                    systemImage: "photo.slash",
                    description: Text("This album has no photos or videos.")
                )
                .foregroundStyle(.white)
            } else if let asset = currentAsset {
                if asset.mediaType == .video {
                    VideoPlayerView(asset: asset, autoplay: settings.autoPlayVideos) {
                        if !isPaused {
                            advanceToNext()
                        }
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                } else {
                    PhotoItemView(asset: asset)
                        .ignoresSafeArea()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
            }
            
            // Controls overlay
            if isShowingControls {
                controlsOverlay
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingControls.toggle()
                    }
                }
        )
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 {
                        advanceToNext()
                    } else if value.translation.width > 50 {
                        goToPrevious()
                    }
                }
        )
        .onAppear {
            loadAssets()
        }
        .onDisappear {
            stopTimer()
        }
        .statusBarHidden(true)
        .confirmationDialog("Change Album", isPresented: $showChangeAlbumConfirm) {
            Button("Change Album", role: .destructive) {
                selectedAlbumIdentifier = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Return to album selection?")
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            // Top bar
            HStack {
                Button {
                    showChangeAlbumConfirm = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .symbolVariant(.circle.fill)
                }
                
                Spacer()
                
                if !assets.isEmpty {
                    Text("\(currentIndex + 1) / \(assets.count)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Spacer()
            
            // Bottom bar
            HStack(spacing: 32) {
                Button {
                    goToPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                
                Button {
                    isPaused.toggle()
                    if isPaused {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                }
                
                Button {
                    advanceToNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
            .padding()
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .transition(.opacity)
    }
    
    private func loadAssets() {
        Task {
            let fetched = await photoManager.fetchAssets(for: albumIdentifier)
            await MainActor.run {
                assets = fetched.shuffled()
                currentIndex = 0
                if !assets.isEmpty && !isPaused {
                    startTimer()
                }
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        guard !isPaused else { return }
        let delay = settings.slideshowDelay
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { _ in
            advanceToNext()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func advanceToNext() {
        guard !assets.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            currentIndex = (currentIndex + 1) % assets.count
        }
        if !isPaused {
            startTimer()
        }
    }
    
    private func goToPrevious() {
        guard !assets.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            currentIndex = currentIndex == 0 ? assets.count - 1 : currentIndex - 1
        }
        if !isPaused {
            startTimer()
        }
    }
}
