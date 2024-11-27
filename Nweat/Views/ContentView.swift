import SwiftUI

struct ContentView: View {
    @State private var viewModel = MediaManagerViewModel()
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            if viewModel.mediaItems.isEmpty {
                EmptyStateView(showingFilePicker: $showingFilePicker)
            } else {
                MediaStackView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(viewModel: viewModel)
        }
    }
}

struct EmptyStateView: View {
    @Binding var showingFilePicker: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
            Text("Select a folder to begin")
                .font(.title2)
            Button("Choose Folder") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
} 