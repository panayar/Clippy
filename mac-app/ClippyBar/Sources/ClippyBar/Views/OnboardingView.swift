import SwiftUI
import AppKit

// MARK: - Full Onboarding (new users)

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var accessibilityGranted = Permissions.isAccessibilityEnabled()
    @State private var pollTimer: Timer?
    var onComplete: () -> Void

    private let steps = [
        OnboardingStep(
            icon: "clipboard.fill",
            iconColor: .purple,
            title: "Welcome to ClippyBar",
            subtitle: "Everything you copy, instantly recalled.",
            body: "ClippyBar lives in your menu bar and remembers everything you copy. Search, pin, and paste with a single shortcut."
        ),
        OnboardingStep(
            icon: "hand.raised.fill",
            iconColor: .blue,
            title: "Enable Accessibility",
            subtitle: "Required for auto-paste to work.",
            body: "ClippyBar needs Accessibility permission to paste items into other apps. Without it, items are copied to your clipboard but won't auto-paste."
        ),
        OnboardingStep(
            icon: "keyboard.fill",
            iconColor: .orange,
            title: "Your Shortcut",
            subtitle: "Press Option + V anywhere.",
            body: "This opens the ClippyBar picker at your cursor. Search your history, select an item, and it's pasted instantly. You can customize this in Settings."
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

            if currentStep == 1 {
                accessibilityAction
                    .padding(.bottom, 12)
            }

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
                    let blocked = currentStep == 1 && !accessibilityGranted

                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text("Continue")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                blocked ? Color.secondary.opacity(0.4) : Color.accentColor,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(blocked)
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
        .onAppear {
            if currentStep == 1 { startPollingAccessibility() }
        }
        .onChange(of: currentStep) { step in
            if step == 1 { startPollingAccessibility() }
            else { stopPollingAccessibility() }
        }
        .onDisappear { stopPollingAccessibility() }
    }

    private func startPollingAccessibility() {
        accessibilityGranted = Permissions.isAccessibilityEnabled()
        stopPollingAccessibility()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                accessibilityGranted = Permissions.isAccessibilityEnabled()
                if accessibilityGranted { stopPollingAccessibility() }
            }
        }
        pollTimer = timer
    }

    private func stopPollingAccessibility() {
        pollTimer?.invalidate()
        pollTimer = nil
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

            if currentStep == 2 {
                HStack(spacing: 8) {
                    keycap("\u{2325}")
                    Text("+").foregroundStyle(.secondary).font(.system(size: 16))
                    keycap("V")
                }
                .padding(.top, 8)
            }
        }
    }

    private var accessibilityAction: some View {
        VStack(spacing: 12) {
            if accessibilityGranted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Accessibility is enabled")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.green)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: accessibilityGranted)
            } else {
                VStack(spacing: 12) {
                    AnimatedToggleHint()

                    Button(action: {
                        // Register the app in the Accessibility list (no dialog)
                        // so the user only has to flip the toggle in Settings.
                        Permissions.registerInAccessibilityList()

                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text("Open Accessibility Settings")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
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

// MARK: - Accessibility Prompt (returning users who lost access)

struct AccessibilityPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.orange)
                .frame(height: 50)

            Text("Accessibility Disabled")
                .font(.system(size: 20, weight: .semibold))

            Text("Auto-paste won't work without it.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text("ClippyBar needs Accessibility permission to paste items into other apps. Please re-enable it in System Settings.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer().frame(height: 8)

            AnimatedToggleHint()

            Button(action: {
                Permissions.registerInAccessibilityList()

                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                    Text("Open Accessibility Settings")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue, in: Capsule())
            }
            .buttonStyle(.plain)

            Text("It will auto-detect when you re-enable access")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 400, height: 380)
    }
}

// MARK: - Celebration Screen (after re-enabling access)

struct CelebrationView: View {
    @State private var confettiVisible = false
    @State private var scale: CGFloat = 0.5
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Confetti particles
            if confettiVisible {
                ForEach(0..<30, id: \.self) { i in
                    ConfettiParticle(index: i)
                }
            }

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "party.popper.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                    .scaleEffect(scale)

                Text("Welcome Back!")
                    .font(.system(size: 24, weight: .bold))
                    .scaleEffect(scale)

                Text("Enjoy ClippyBar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .scaleEffect(scale)

                Spacer()

                Button(action: onDismiss) {
                    Text("Let's Go")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.purple, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 360, height: 300)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                confettiVisible = true
            }
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                onDismiss()
            }
        }
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
        let shape = index % 3 // 0=circle, 1=rect, 2=diamond

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

// MARK: - Animated Toggle Hint

private struct AnimatedToggleHint: View {
    @State private var isOn = false
    @State private var timer: Timer?

    var body: some View {
        HStack {
            Text("ClippyBar")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 20)

                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                    .padding(.horizontal, 2)
            }
            .animation(.easeInOut(duration: 0.3), value: isOn)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
        .frame(width: 220)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { isOn = true }
            }
            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation { isOn.toggle() }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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

    /// Flow 1: Full onboarding for new users
    func showFullOnboarding(onComplete: @escaping () -> Void) {
        let view = OnboardingView {
            self.dismissIfShowing()
            onComplete()
        }
        showWindow(content: view, width: 440, height: 400)
    }

    /// Flow 2: Accessibility-only prompt for returning users
    func showAccessibilityPrompt() {
        let view = AccessibilityPromptView()
        showWindow(content: view, width: 400, height: 380)
    }

    /// Celebration screen after re-enabling access
    func showCelebration(onDismiss: @escaping () -> Void) {
        let view = CelebrationView {
            self.dismissIfShowing()
            onDismiss()
        }
        showWindow(content: view, width: 360, height: 300)
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
