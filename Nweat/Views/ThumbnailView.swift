import SwiftUI

struct ThumbnailView: View {
    let item: MediaItem
    
    var body: some View {
        ZStack {
            // Base image or placeholder
            Group {
                if let thumbnail = item.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Status indicator in top-right corner
            if item.status != .none {
                VStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 24, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, overlayColor)
                }
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(overlayColor)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8)
                .transition(.scale.combined(with: .opacity))
            }
            
            // File type indicator in bottom-left corner
            HStack(spacing: 4) {
                Image(systemName: isVideo ? "video.fill" : "photo.fill")
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(8)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .id("\(item.id)-\(item.status)")
    }
    
    private var overlayColor: Color {
        switch item.status {
        case .archived:
            Color(red: 0.92, green: 0.25, blue: 0.25)
        case .skipped:
            Color(red: 0.25, green: 0.52, blue: 0.95)
        case .moved:
            Color(red: 0.25, green: 0.85, blue: 0.45)
        case .none:
            Color.clear
        }
    }
    
    private var statusIcon: String {
        switch item.status {
        case .archived:
            "archivebox"
        case .skipped:
            "arrow.right.circle"
        case .moved:
            "folder"
        case .none:
            ""
        }
    }
    
    private var isVideo: Bool {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(item.url.pathExtension.lowercased())
    }
} 