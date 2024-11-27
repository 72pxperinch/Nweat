import SwiftUI

struct ArchivedItemsView: View {
    @Bindable var viewModel: MediaManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems = Set<MediaItem.ID>()
    @Environment(\.colorScheme) private var colorScheme
    
    var archivedItems: [MediaItem] {
        viewModel.mediaItems.filter { $0.status == .archived }
    }
    
    var allItemsSelected: Bool {
        selectedItems.count == archivedItems.count && !archivedItems.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if archivedItems.isEmpty {
                    ContentUnavailableView(
                        "No Archived Items",
                        systemImage: "archivebox",
                        description: Text("Items you archive will appear here")
                    )
                    .transition(.opacity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(archivedItems) { item in
                                ArchivedItemCard(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id)
                                )
                                .aspectRatio(1, contentMode: .fit)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedItems.contains(item.id) {
                                            selectedItems.remove(item.id)
                                        } else {
                                            selectedItems.insert(item.id)
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        withAnimation {
                                            viewModel.restoreArchivedItem(item)
                                        }
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteArchivedItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .safeAreaInset(edge: .bottom) {
                        if !selectedItems.isEmpty {
                            VStack(spacing: 16) {
                                Text("\(selectedItems.count) items selected")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 16) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteSelected()
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    
                                    Button {
                                        withAnimation {
                                            restoreSelected()
                                        }
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                    }
                }
            }
            .navigationTitle("Archived Items")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !archivedItems.isEmpty {
                        Button(allItemsSelected ? "Deselect All" : "Select All") {
                            withAnimation(.spring(response: 0.3)) {
                                if allItemsSelected {
                                    selectedItems.removeAll()
                                } else {
                                    selectedItems = Set(archivedItems.map { $0.id })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func restoreSelected() {
        for id in selectedItems {
            if let item = archivedItems.first(where: { $0.id == id }) {
                viewModel.restoreArchivedItem(item)
            }
        }
        selectedItems.removeAll()
    }
    
    private func deleteSelected() {
        for id in selectedItems {
            if let item = archivedItems.first(where: { $0.id == id }) {
                viewModel.deleteArchivedItem(item)
            }
        }
        selectedItems.removeAll()
    }
}

struct ArchivedItemCard: View {
    let item: MediaItem
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Image container
                ZStack(alignment: .bottom) {
                    if let thumbnail = item.thumbnailImage {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)
                    }
                    
                    // Filename overlay
                    HStack(spacing: 4) {
                        Image(systemName: fileTypeIcon)
                        Text(item.url.lastPathComponent)
                            .lineLimit(1)
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Selection checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(.white)
                            .padding(4)
                    )
                    .padding(8)
            }
        }
        .frame(width: 150, height: 150)
    }
    
    private var fileTypeIcon: String {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(item.url.pathExtension.lowercased()) 
            ? "video.fill" 
            : "photo.fill"
    }
} 