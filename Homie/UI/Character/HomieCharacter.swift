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
    
    @State private var isAnimating = false
    @State private var blinkTimer: Timer?
    @State private var isBlinking = false
    
    init(mood: Mood = .happy, size: CGFloat = 60) {
        self.mood = mood
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Face background
            Circle()
                .fill(faceColor)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Eyes
            HStack(spacing: size * 0.2) {
                Eye(isBlinking: isBlinking, mood: mood, size: size * 0.12)
                Eye(isBlinking: isBlinking, mood: mood, size: size * 0.12)
            }
            .offset(y: -size * 0.08)
            
            // Mouth
            MouthShape(mood: mood)
                .stroke(Color.black, lineWidth: 2)
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(y: size * 0.18)
            
            // Blush (when happy/excited)
            if mood == .happy || mood == .excited {
                HStack(spacing: size * 0.35) {
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: size * 0.12, height: size * 0.08)
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: size * 0.12, height: size * 0.08)
                }
                .offset(y: size * 0.05)
            }
            
            // Angry eyebrows
            if mood == .angry {
                HStack(spacing: size * 0.15) {
                    AngryBrow(isLeft: true)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: size * 0.12, height: size * 0.06)
                    AngryBrow(isLeft: false)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: size * 0.12, height: size * 0.06)
                }
                .offset(y: -size * 0.22)
            }
            
            // Zzz for sleepy
            if mood == .sleepy {
                Text("z")
                    .font(.system(size: size * 0.15, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(x: size * 0.35, y: -size * 0.25)
                    .opacity(isAnimating ? 0.3 : 1)
            }
            
            // Lightbulb for idea
            if mood == .idea {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: size * 0.2))
                    .foregroundColor(.yellow)
                    .offset(x: size * 0.35, y: -size * 0.35)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
        }
        .scaleEffect(bounceScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        .onAppear {
            startBlinking()
            startMoodAnimation()
        }
        .onDisappear {
            blinkTimer?.invalidate()
        }
    }
    
    private var faceColor: Color {
        switch mood {
        case .happy, .excited, .idea: return Color(red: 1, green: 0.9, blue: 0.7)
        case .sleepy: return Color(red: 0.9, green: 0.85, blue: 0.75)
        case .angry: return Color(red: 1, green: 0.7, blue: 0.7)
        case .thinking: return Color(red: 0.9, green: 0.9, blue: 0.95)
        }
    }
    
    private var bounceScale: CGFloat {
        switch mood {
        case .excited: return isAnimating ? 1.05 : 1.0
        case .angry: return isAnimating ? 1.02 : 0.98
        default: return 1.0
        }
    }
    
    private func startBlinking() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            if mood != .sleepy {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
    
    private func startMoodAnimation() {
        if mood == .excited || mood == .angry || mood == .sleepy || mood == .idea {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Eye

struct Eye: View {
    let isBlinking: Bool
    let mood: HomieCharacter.Mood
    let size: CGFloat
    
    var body: some View {
        Group {
            if isBlinking || mood == .sleepy {
                // Closed eye (line)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black)
                    .frame(width: size, height: 2)
            } else if mood == .angry {
                // Angry eye (smaller)
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.8, height: size * 0.8)
            } else {
                // Normal eye
                Circle()
                    .fill(Color.black)
                    .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Mouth Shape

struct MouthShape: Shape {
    let mood: HomieCharacter.Mood
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch mood {
        case .happy, .excited, .idea:
            // Smile
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.height + rect.height * 0.5)
            )
        case .angry:
            // Frown
            path.move(to: CGPoint(x: 0, y: rect.height * 0.7))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.7),
                control: CGPoint(x: rect.midX, y: -rect.height * 0.3)
            )
        case .sleepy:
            // Slight open (yawn-ish)
            path.addEllipse(in: CGRect(x: rect.midX - rect.width * 0.2, y: 0, width: rect.width * 0.4, height: rect.height * 0.8))
        case .thinking:
            // Wavy/uncertain
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addCurve(
                to: CGPoint(x: rect.width, y: rect.midY),
                control1: CGPoint(x: rect.width * 0.25, y: rect.height),
                control2: CGPoint(x: rect.width * 0.75, y: 0)
            )
        }
        
        return path
    }
}

// MARK: - Angry Brow

struct AngryBrow: Shape {
    let isLeft: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isLeft {
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        } else {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        }
        return path
    }
}

// MARK: - Preview

struct HomieCharacter_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(HomieCharacter.Mood.allCases, id: \.self) { mood in
                HStack {
                    HomieCharacter(mood: mood, size: 80)
                    Text(mood.rawValue.capitalized)
                        .frame(width: 80, alignment: .leading)
                }
            }
        }
        .padding()
    }
}
