import SwiftUI

struct CompletionCard: View {
    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Content
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                    )
                
                VStack(spacing: 8) {
                    Text("Successfully Completed!")
                        .font(.title3.bold())
                    
                    Text("All items have been processed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
        .frame(width: UIScreen.main.bounds.width - 32)
        .frame(height: 200)
    }
} 