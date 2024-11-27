import SwiftUI
import Photos
import AVFoundation

@Observable
class MediaManagerViewModel {
    var mediaItems: [MediaItem] = []
    var folders: [Folder] = []
    var currentIndex: Int = 0
    var showingOverlay = false
    var showingArchived = false
    var isCompleted = false
    var hasShownFolderHint = false
    
    private let fileManager = FileManager.default
    private var baseURL: URL?
    private var archiveFolderURL: URL?
    private let userDefaults = UserDefaults.standard
    private let lastFolderKey = "LastProcessedFolder"
    
    init() {
        // Try to load the last processed folder on launch
        if let savedURLString = userDefaults.string(forKey: lastFolderKey),
           let savedURL = URL(string: savedURLString) {
            loadFolder(url: savedURL)
        }
    }
    
    func loadFolder(url: URL) {
        do {
            baseURL = url
            // Save the current folder URL
            userDefaults.set(url.absoluteString, forKey: lastFolderKey)
            
            // Create archive folder if it doesn't exist
            archiveFolderURL = url.appendingPathComponent("Archived", isDirectory: true)
            try? fileManager.createDirectory(at: archiveFolderURL!, withIntermediateDirectories: true)
            
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            mediaItems = contents.compactMap { url in
                guard isMediaFile(url: url) else { return nil }
                return MediaItem(url: url)
            }
            
            // Load thumbnails efficiently
            loadThumbnails()
            
            // Load existing folders
            loadFolders()
            
            currentIndex = 0
            isCompleted = false
        } catch {
            print("Error loading folder: \(error)")
        }
    }
    
    private func isMediaFile(url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "heic"]
        let videoExtensions = ["mp4", "mov"]
        let allowedExtensions = imageExtensions + videoExtensions
        return allowedExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func loadThumbnails() {
        for (index, item) in mediaItems.enumerated() {
            if isVideo(url: item.url) {
                loadVideoThumbnail(for: &mediaItems[index])
            } else {
                loadImageThumbnail(for: &mediaItems[index])
            }
        }
    }
    
    private func loadImageThumbnail(for item: inout MediaItem) {
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 300
        ] as CFDictionary
        
        if let imageSource = CGImageSourceCreateWithURL(item.url as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) {
            item.thumbnailImage = UIImage(cgImage: cgImage)
        }
    }
    
    private func loadVideoThumbnail(for item: inout MediaItem) {
        let asset = AVAsset(url: item.url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            item.thumbnailImage = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating video thumbnail: \(error)")
        }
    }
    
    func moveToArchive() {
        guard let item = mediaItems[safe: currentIndex],
              let archiveURL = archiveFolderURL else { return }
        
        let destination = archiveURL.appendingPathComponent(item.url.lastPathComponent)
        do {
            try fileManager.moveItem(at: item.url, to: destination)
            withAnimation(.easeInOut(duration: 0.2)) {
                var updatedItem = mediaItems[currentIndex]
                updatedItem.status = .archived
                updatedItem.url = destination
                mediaItems[currentIndex] = updatedItem
            }
            moveToNext()
        } catch {
            print("Error moving to archive: \(error)")
        }
    }
    
    func skipItem() {
        guard currentIndex < mediaItems.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            var updatedItem = mediaItems[currentIndex]
            updatedItem.status = .skipped
            mediaItems[currentIndex] = updatedItem
        }
        moveToNext()
    }
    
    func moveToFolder(_ folder: Folder) {
        guard let item = mediaItems[safe: currentIndex] else { return }
        
        let destination = folder.url.appendingPathComponent(item.url.lastPathComponent)
        do {
            try fileManager.moveItem(at: item.url, to: destination)
            withAnimation(.easeInOut(duration: 0.2)) {
                var updatedItem = mediaItems[currentIndex]
                updatedItem.status = .moved
                updatedItem.url = destination
                mediaItems[currentIndex] = updatedItem
            }
            moveToNext()
            showingOverlay = false
        } catch {
            print("Error moving to folder: \(error)")
        }
    }
    
    private func moveToNext() {
        // First check if all items are processed
        let allProcessed = mediaItems.allSatisfy { $0.status != .none }
        if allProcessed {
            isCompleted = true
            return // Don't move to next item if all are processed
        }
        
        // First try to find the next unprocessed item after current index
        if let nextIndex = mediaItems[currentIndex + 1..<mediaItems.count].firstIndex(where: { $0.status == .none }) {
            currentIndex = nextIndex
            return
        }
        
        // If not found after current index, look from the beginning
        if let firstUnprocessedIndex = mediaItems[0..<currentIndex].firstIndex(where: { $0.status == .none }) {
            currentIndex = firstUnprocessedIndex
            return
        }
        
        // If we reach here, all items are processed (double-check)
        isCompleted = true
    }
    
    func restoreArchivedItem(_ item: MediaItem) {
        guard let baseURL = baseURL else { return }
        let destination = baseURL.appendingPathComponent(item.url.lastPathComponent)
        
        do {
            try fileManager.moveItem(at: item.url, to: destination)
            if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
                withAnimation {
                    mediaItems[index].status = .none
                    mediaItems[index].url = destination
                    // Reset completion state since we now have an unprocessed item
                    isCompleted = false
                }
            }
        } catch {
            print("Error restoring item: \(error)")
        }
    }
    
    func deleteArchivedItem(_ item: MediaItem) {
        do {
            try fileManager.removeItem(at: item.url)
            mediaItems.removeAll(where: { $0.id == item.id })
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    func restoreAllArchivedItems() {
        guard let baseURL = baseURL else { return }
        
        for index in mediaItems.indices where mediaItems[index].status == .archived {
            let destination = baseURL.appendingPathComponent(mediaItems[index].url.lastPathComponent)
            do {
                try fileManager.moveItem(at: mediaItems[index].url, to: destination)
                withAnimation {
                    mediaItems[index].status = .none
                    mediaItems[index].url = destination
                }
            } catch {
                print("Error restoring item: \(error)")
            }
        }
        // Reset completion state since we now have unprocessed items
        isCompleted = false
    }
    
    func deleteAllArchivedItems() {
        let archivedItems = mediaItems.filter { $0.status == .archived }
        for item in archivedItems {
            do {
                try fileManager.removeItem(at: item.url)
            } catch {
                print("Error deleting item: \(error)")
            }
        }
        mediaItems.removeAll(where: { $0.status == .archived })
    }
    
    func createNewFolder(name: String) {
        guard let baseURL = baseURL else { return }
        let folderURL = baseURL.appendingPathComponent(name, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            folders.append(Folder(name: name, url: folderURL))
        } catch {
            print("Error creating folder: \(error)")
        }
    }
    
    private func loadFolders() {
        guard let baseURL = baseURL else { return }
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            folders = contents.compactMap { url in
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                      isDirectory.boolValue,
                      url != archiveFolderURL else { return nil }
                return Folder(name: url.lastPathComponent, url: url)
            }
        } catch {
            print("Error loading folders: \(error)")
        }
    }
    
    private func isVideo(url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
    
    func resetItemStatus(at index: Int) {
        guard index < mediaItems.count else { return }
        let item = mediaItems[index]
        
        // If the item was archived or moved, move it back to original location
        if item.status == .archived || item.status == .moved {
            guard let baseURL = baseURL else { return }
            let destination = baseURL.appendingPathComponent(item.url.lastPathComponent)
            
            do {
                try fileManager.moveItem(at: item.url, to: destination)
                withAnimation(.easeInOut(duration: 0.2)) {
                    var updatedItem = mediaItems[index]
                    updatedItem.status = .none
                    updatedItem.url = destination
                    mediaItems[index] = updatedItem
                }
            } catch {
                print("Error resetting item: \(error)")
            }
        } else {
            // For skipped items, just reset the status
            withAnimation(.easeInOut(duration: 0.2)) {
                var updatedItem = mediaItems[index]
                updatedItem.status = .none
                mediaItems[index] = updatedItem
            }
        }
        
        // Reset completion state since we now have an unprocessed item
        isCompleted = false
    }
} 