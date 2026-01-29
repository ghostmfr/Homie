import SwiftUI

struct HomieCharacter: View {
    enum Mood: String, CaseIterable {
        case happy      // 😊 Idle, everything good
        case excited    // 🤩 Action triggered
        case sleepy     // 😴 Night mode / low activity
        case angry      // 😠 Security compromised!
        case thinking   // 🤔 Processing
        case idea       // 💡 Suggestion available
    }
    
    let mood: Mood
    let size: CGFloat
    
    init(mood: Mood = .happy, size: CGFloat = 60) {
        self.mood = mood
        self.size = size
    }
    
    var body: some View {
        Image("Mascot")
            .resizable()
            .scaledToFit()
            .frame(height: size)
    }
}

// MARK: - Preview

struct HomieCharacter_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HomieCharacter(size: 120)
            HomieCharacter(size: 60)
            HomieCharacter(size: 40)
        }
        .padding()
    }
}
