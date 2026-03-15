import SwiftUI
import Photos

struct PhotoItemView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var isLoading: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
        .task(id: asset.localIdentifier) {
            image = nil
            isLoading = true
            image = await loadImage()
            isLoading = false
        }
    }
    
    private func loadImage() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.resizeMode = .exact
            
            let targetSize = CGSize(
                width: UIScreen.main.bounds.width * UIScreen.main.scale,
                height: UIScreen.main.bounds.height * UIScreen.main.scale
            )
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
