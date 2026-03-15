import Foundation
import Photos
import Combine

@MainActor
class PhotoLibraryManager: NSObject, ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var sharedAlbums: [PHAssetCollection] = []
    @Published var regularAlbums: [PHAssetCollection] = []
    
    override init() {
        super.init()
        // .readWrite is the correct access level for reading photos from the library.
        // PHAccessLevel has only .addOnly (write-only) and .readWrite (read+write);
        // there is no read-only level in PhotoKit.
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            loadAlbums()
        }
    }
    
    func requestAuthorization() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            authorizationStatus = status
            if status == .authorized || status == .limited {
                loadAlbums()
            }
        }
    }
    
    func loadAlbums() {
        // Load iCloud shared albums
        let sharedOptions = PHFetchOptions()
        sharedOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        let sharedResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumCloudShared,
            options: sharedOptions
        )
        
        var shared: [PHAssetCollection] = []
        sharedResult.enumerateObjects { collection, _, _ in
            shared.append(collection)
        }
        sharedAlbums = shared
        
        // Load regular albums
        let albumOptions = PHFetchOptions()
        albumOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        let albumResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: albumOptions
        )
        
        var regular: [PHAssetCollection] = []
        albumResult.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            if count > 0 {
                regular.append(collection)
            }
        }
        regularAlbums = regular
    }
    
    func fetchAssets(for albumIdentifier: String) async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumIdentifier],
                options: nil
            )
            
            guard let collection = collections.firstObject else {
                continuation.resume(returning: [])
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchOptions.predicate = NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue
            )
            
            let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            var assets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            continuation.resume(returning: assets)
        }
    }
}

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            loadAlbums()
        }
    }
}
