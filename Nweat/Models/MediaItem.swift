import Foundation
import SwiftUI

struct MediaItem: Identifiable, Hashable, Equatable {
    let id: UUID
    var url: URL
    var status: ItemStatus
    var thumbnailImage: UIImage?
    
    enum ItemStatus: String, Equatable {
        case none
        case archived
        case skipped
        case moved
    }
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.status = .none
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
} 