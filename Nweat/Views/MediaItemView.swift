import SwiftUI
import AVKit

struct MediaItemView: View {
    let item: MediaItem
    @State private var player: AVPlayer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Media content
                if isVideo(url: item.url) {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .onAppear {
                            player = AVPlayer(url: item.url)
                        }
                        .onDisappear {
                            player?.pause()
                            player = nil
                        }
                } else {
                    AsyncImage(url: item.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
                        ProgressView()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Filename overlay at the bottom
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: isVideo(url: item.url) ? "video.fill" : "photo.fill")
                            .foregroundColor(.white)
                        Text(item.url.lastPathComponent)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func isVideo(url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
} 