import SwiftUI

struct MediaStackView: View {
    @Bindable var viewModel: MediaManagerViewModel
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingActionHint = false
    @State private var dragAmount: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Current media item
                if let currentItem = viewModel.mediaItems[safe: viewModel.currentIndex] {
                    MediaItemView(item: currentItem)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard !viewModel.isCompleted || currentItem.status == .none else { return }
                                    dragAmount = value.translation
                                    showActionHint(for: value)
                                }
                                .onEnded { value in
                                    guard !viewModel.isCompleted || currentItem.status == .none else {
                                        withAnimation(.spring()) {
                                            dragAmount = .zero
                                            showingActionHint = false
                                        }
                                        return
                                    }
                                    withAnimation(.spring()) {
                                        dragAmount = .zero
                                        showingActionHint = false
                                    }
                                    handleSwipe(value)
                                }
                        )
                        .offset(dragAmount)
                }
                
                // Action hints
                ZStack {
                    if showingActionHint {
                        HStack {
                            ActionHint(
                                icon: "arrow.right.circle.fill",
                                text: "Skip",
                                color: .blue,
                                opacity: dragAmount.width > 0 ? 1 : 0
                            )
                            Spacer()
                            ActionHint(
                                icon: "archivebox.fill",
                                text: "Archive",
                                color: .red,
                                opacity: dragAmount.width < 0 ? 1 : 0
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(height: 40)
                
                // Progress indicator
                let processedCount = Double(viewModel.mediaItems.filter { $0.status != .none }.count)
                let totalCount = Double(viewModel.mediaItems.count)

                ProgressView(value: processedCount, total: totalCount)
                    .padding(.horizontal)
                    .tint(.blue)
                    .overlay(
                        Text("\(Int(processedCount))/\(Int(totalCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    )
                
                // Thumbnail row
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(Array(viewModel.mediaItems.enumerated()), id: \.element.id) { index, item in
                                ThumbnailView(item: item)
                                    .frame(width: 72, height: 72)
                                    .id(index)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(index == viewModel.currentIndex ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .opacity(index == viewModel.currentIndex ? 1.0 : 0.6)
                                    .scaleEffect(index == viewModel.currentIndex ? 1.1 : 1.0)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            // Reset the item's status when directly navigating to it
                                            if item.status != .none {
                                                viewModel.resetItemStatus(at: index)
                                            }
                                            viewModel.currentIndex = index
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(height: 96)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .onChange(of: viewModel.currentIndex) { _, newIndex in
                        withAnimation(.spring(response: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            
            // Overlays
            if viewModel.isCompleted {
                CompletionCard()
                    .transition(.scale.combined(with: .opacity))
            }
            
            if viewModel.showingOverlay {
                FolderOverlay(viewModel: viewModel)
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Media Manager")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingArchived = true
                } label: {
                    Label("Archived", systemImage: "archivebox")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingArchived) {
            ArchivedItemsView(viewModel: viewModel)
        }
    }
    
    private func showActionHint(for value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        showingActionHint = abs(horizontalAmount) > 20 && abs(horizontalAmount) > abs(verticalAmount)
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            if abs(horizontalAmount) > 100 {
                if horizontalAmount < 0 {
                    viewModel.moveToArchive()
                } else {
                    viewModel.skipItem()
                }
            }
        } else if verticalAmount > 50 {
            viewModel.showingOverlay = true
            viewModel.hasShownFolderHint = true
        }
    }
}

struct ActionHint: View {
    let icon: String
    let text: String
    let color: Color
    let opacity: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(text)
        }
        .foregroundColor(getActionColor())
        .opacity(opacity)
        .animation(.easeOut(duration: 0.2), value: opacity)
    }
    
    private func getActionColor() -> Color {
        switch text.lowercased() {
        case "archive":
            return Color(red: 1, green: 0.3, blue: 0.3) // Brighter red
        case "skip":
            return Color(red: 0.3, green: 0.5, blue: 1) // Brighter blue
        default:
            return color
        }
    }
} 