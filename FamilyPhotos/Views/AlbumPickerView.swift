import SwiftUI
import Photos

struct AlbumPickerView: View {
    @ObservedObject var photoManager: PhotoLibraryManager
    @Binding var selectedAlbumIdentifier: String
    
    var body: some View {
        NavigationStack {
            Group {
                if photoManager.sharedAlbums.isEmpty && photoManager.regularAlbums.isEmpty {
                    ContentUnavailableView(
                        "No Shared Albums",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("No iCloud shared albums found. Subscribe to a shared album in the Photos app first.")
                    )
                } else {
                    List {
                        if !photoManager.sharedAlbums.isEmpty {
                            Section("iCloud Shared Albums") {
                                ForEach(photoManager.sharedAlbums, id: \.localIdentifier) { album in
                                    AlbumRow(album: album) {
                                        selectedAlbumIdentifier = album.localIdentifier
                                    }
                                }
                            }
                        }
                        if !photoManager.regularAlbums.isEmpty {
                            Section("My Albums") {
                                ForEach(photoManager.regularAlbums, id: \.localIdentifier) { album in
                                    AlbumRow(album: album) {
                                        selectedAlbumIdentifier = album.localIdentifier
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Album")
            .onAppear {
                photoManager.loadAlbums()
            }
            .refreshable {
                photoManager.loadAlbums()
            }
        }
    }
}

struct AlbumRow: View {
    let album: PHAssetCollection
    let onSelect: () -> Void
    @State private var thumbnail: UIImage?
    @State private var assetCount: Int = 0
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.localizedTitle ?? "Untitled")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(assetCount) items")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .task {
            let assets = PHAsset.fetchAssets(in: album, options: nil)
            assetCount = assets.count
            thumbnail = await loadThumbnail(firstAsset: assets.firstObject)
        }
    }
    
    private func loadThumbnail(firstAsset asset: PHAsset?) async -> UIImage? {
        guard let asset = asset else { return nil }
        
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 112, height: 112),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
