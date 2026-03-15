import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoManager = PhotoLibraryManager()
    @State private var showAlbumPicker = false
    @AppStorage("selectedAlbumIdentifier") private var selectedAlbumIdentifier: String = ""
    
    var body: some View {
        Group {
            if photoManager.authorizationStatus == .authorized || photoManager.authorizationStatus == .limited {
                if selectedAlbumIdentifier.isEmpty {
                    AlbumPickerView(photoManager: photoManager, selectedAlbumIdentifier: $selectedAlbumIdentifier)
                } else {
                    SlideshowView(photoManager: photoManager, albumIdentifier: selectedAlbumIdentifier)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Change Album") {
                                    selectedAlbumIdentifier = ""
                                }
                            }
                        }
                        .navigationBarHidden(true)
                }
            } else if photoManager.authorizationStatus == .notDetermined {
                PermissionRequestView(photoManager: photoManager)
            } else {
                PermissionDeniedView()
            }
        }
        .onAppear {
            photoManager.checkAuthorization()
        }
    }
}

struct PermissionRequestView: View {
    @ObservedObject var photoManager: PhotoLibraryManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            Text("Family Photos")
                .font(.largeTitle.bold())
            
            Text("This app needs access to your photo library to display your iCloud shared albums.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Allow Access") {
                photoManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.slash")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            Text("Photo Access Required")
                .font(.largeTitle.bold())
            
            Text("Please allow photo library access in Settings to use Family Photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
