import SwiftUI

struct FolderOverlay: View {
    @Bindable var viewModel: MediaManagerViewModel
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showingOverlay = false
                }
            
            VStack(spacing: 0) {
                // Header with title and cancel button
                HStack {
                    Text("Select Folder")
                        .font(.title3)
                    Spacer()
                    Button {
                        viewModel.showingOverlay = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        // Add Folder Button
                        FolderGridItem(isAddButton: true) {
                            showingNewFolderAlert = true
                        }
                        
                        // Existing Folders
                        ForEach(viewModel.folders) { folder in
                            FolderGridItem(folder: folder) {
                                viewModel.moveToFolder(folder)
                                viewModel.showingOverlay = false
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createNewFolder()
            }
        }
    }
    
    private func createNewFolder() {
        guard !newFolderName.isEmpty else { return }
        viewModel.createNewFolder(name: newFolderName)
        newFolderName = ""
    }
}

struct FolderGridItem: View {
    var folder: Folder?
    var isAddButton = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if isAddButton {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32))
                    Text("Add Folder")
                        .font(.callout)
                } else if let folder = folder {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                    Text(folder.name)
                        .font(.callout)
                        .lineLimit(1)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
} 