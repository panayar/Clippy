import SwiftUI
import AppKit

// MARK: - Onboarding

struct OnboardingView: View {
    @State private var currentStep = 0
    var onComplete: () -> Void

    private let steps = [
        OnboardingStep(
            icon: "clipboard.fill",
            iconColor: .purple,
            title: "Welcome to ClippyBar",
            subtitle: "Everything you copy, instantly recalled.",
            body: "ClippyBar lives in your menu bar and remembers everything you copy. Search, pin, and pull any snippet back in a second."
        ),
        OnboardingStep(
            icon: "keyboard.fill",
            iconColor: .orange,
            title: "Your Shortcut",
            subtitle: "Press Option + V anywhere.",
            body: "This opens the ClippyBar picker at your cursor. Pick an item with ↑ ↓ and ↵ to copy it, then press ⌘V to paste it into the app you're using."
        ),
        OnboardingStep(
            icon: "checkmark.circle.fill",
            iconColor: .green,
            title: "You're All Set",
            subtitle: "ClippyBar is ready to go.",
            body: "Look for the clipboard icon in your menu bar. Copy something to start building your history. Happy pasting!",
            showConfetti: true
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            ZStack {
                if steps[currentStep].showConfetti {
                    ForEach(0..<30, id: \.self) { i in
                        ConfettiParticle(index: i)
                    }
                }

                stepView(steps[currentStep])
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }

            Spacer()

            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text("Continue")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onComplete) {
                        Text("Get Started")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.green, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(width: 440, height: 400)
    }

    private func stepView(_ step: OnboardingStep) -> some View {
        VStack(spacing: 16) {
            Image(systemName: step.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(step.iconColor)
                .frame(height: 50)

            Text(step.title)
                .font(.system(size: 20, weight: .semibold))

            Text(step.subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text(step.body)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            if currentStep == 1 {
                HStack(spacing: 8) {
                    keycap("\u{2325}")
                    Text("+").foregroundStyle(.secondary).font(.system(size: 16))
                    keycap("V")
                }
                .padding(.top, 8)
            }
        }
    }

    private func keycap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .frame(width: 40, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Confetti Particle

private struct ConfettiParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private let colors: [Color] = [.purple, .orange, .blue, .green, .pink, .yellow]

    var body: some View {
        let size = CGFloat.random(in: 5...10)
        let color = colors[index % colors.count]
        let shape = index % 3

        Group {
            if shape == 0 {
                Circle().fill(color).frame(width: size, height: size)
            } else if shape == 1 {
                Rectangle().fill(color).frame(width: size, height: size * 0.6)
            } else {
                Rectangle().fill(color).frame(width: size, height: size)
                    .rotationEffect(.degrees(45))
            }
        }
        .opacity(opacity)
        .offset(x: xOffset, y: yOffset)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            let startX = CGFloat.random(in: -150...150)
            xOffset = startX
            yOffset = -20

            withAnimation(.easeOut(duration: Double.random(in: 1.5...2.5))) {
                yOffset = CGFloat.random(in: 100...200)
                xOffset = startX + CGFloat.random(in: -40...40)
                rotation = Double.random(in: -360...360)
                opacity = 0
            }
        }
    }
}

// MARK: - Data Model

private struct OnboardingStep {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let body: String
    var showConfetti: Bool = false
}

// MARK: - Window Controller

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    private init() {}

    func showFullOnboarding(onComplete: @escaping () -> Void) {
        let view = OnboardingView {
            self.dismissIfShowing()
            onComplete()
        }
        showWindow(content: view, width: 440, height: 400)
    }

    func dismissIfShowing() {
        window?.orderOut(nil)
        window = nil
    }

    private func showWindow<V: View>(content: V, width: CGFloat, height: CGFloat) {
        dismissIfShowing()

        let hostingView = NSHostingView(rootView: content)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.center()
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isMovableByWindowBackground = true
        w.contentView = hostingView
        w.level = .floating
        w.makeKeyAndOrderFront(nil)

        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        self.window = w
    }
}
