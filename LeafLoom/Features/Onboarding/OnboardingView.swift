import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var permission: ReminderAuthorization = .notDetermined

    private struct Page {
        let illustration: String?
        let eyebrow: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(illustration: nil, eyebrow: "Welcome to", title: "LeafLoom",
             body: "Your calm, private companion for keeping plants thriving. Everything stays on your device — no account needed."),
        Page(illustration: "OnboardingCollection", eyebrow: "Your collection", title: "Every plant, beautifully organised",
             body: "Keep photos, care needs, locations and notes for each plant. Search, filter and favourite in seconds."),
        Page(illustration: "OnboardingIdentify", eyebrow: "AI-assisted", title: "Identify plants from a photo",
             body: "With a Core ML model installed, LeafLoom suggests what your plant might be, on device. Without one, a clearly labelled demo mode shows how it works."),
        Page(illustration: "OnboardingReminders", eyebrow: "Personal care", title: "Reminders that fit your plants",
             body: "Recurring watering, feeding and pruning schedules, with gentle reminders when something is due."),
    ]

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !isLast {
                    Button("Skip") { finish() }
                        .font(LeafFont.headline)
                        .foregroundStyle(LeafColor.primary)
                        .frame(minWidth: LeafSpacing.touchTarget, minHeight: LeafSpacing.touchTarget)
                        .accessibilityIdentifier("onboarding.skip")
                }
            }
            .frame(height: 52)
            .padding(.horizontal, LeafSpacing.screen)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(LeafMotion.animation(LeafMotion.gentle, reduceMotion: reduceMotion), value: page)

            VStack(spacing: LeafSpacing.md) {
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? LeafColor.primary : LeafColor.border)
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(page + 1) of \(pages.count)")
                .leafAnimation(value: page)

                Button {
                    if isLast { finish() } else { page += 1 }
                } label: {
                    Label(isLast ? "Get Started" : "Continue", systemImage: "arrow.right")
                        .labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(.leafPrimary)
                .accessibilityIdentifier(isLast ? "onboarding.getStarted" : "onboarding.continue")
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.lg)
        }
        .leafScreenBackground()
        .task { permission = await env.scheduler.authorizationStatus() }
    }

    @ViewBuilder
    private func pageView(_ p: Page, index: Int) -> some View {
        ScrollView {
            VStack(spacing: LeafSpacing.md) {
                Group {
                    if let illustration = p.illustration {
                        Image(illustration).resizable().scaledToFit()
                    } else {
                        Image("BrandMark").resizable().scaledToFit().padding(LeafSpacing.xl)
                            .background(Circle().fill(LeafColor.primarySoft))
                    }
                }
                .frame(maxWidth: 260, maxHeight: 220)
                .padding(.vertical, LeafSpacing.lg)
                .accessibilityHidden(true)

                Text(p.eyebrow).eyebrowStyle()
                Text(p.title)
                    .font(index == 0 ? LeafFont.largeTitle : LeafFont.title)
                    .foregroundStyle(LeafColor.text)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                if index == 0 {
                    Text("Grow with confidence.")
                        .font(.system(.title3, design: .serif).italic())
                        .foregroundStyle(LeafColor.accent)
                }
                Text(p.body)
                    .font(LeafFont.body)
                    .foregroundStyle(LeafColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if index == pages.count - 1 { reminderPrompt }
            }
            .padding(.horizontal, LeafSpacing.lg)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder private var reminderPrompt: some View {
        switch permission {
        case .authorized:
            Label("Reminders are on. You can change this any time in Settings.", systemImage: "checkmark.circle.fill")
                .font(LeafFont.footnote)
                .foregroundStyle(LeafColor.success)
                .padding(.top, LeafSpacing.sm)
        case .denied:
            Text("Reminders are off. LeafLoom still works fully — you can enable them later in Settings.")
                .font(LeafFont.footnote)
                .foregroundStyle(LeafColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, LeafSpacing.sm)
        case .notDetermined:
            Button {
                Task {
                    let granted = await env.scheduler.requestAuthorization()
                    permission = granted ? .authorized : .denied
                    preferences.remindersEnabled = granted
                    if granted { env.tasks.rescheduleAll() }
                }
            } label: {
                Label("Turn on care reminders", systemImage: "bell.badge")
            }
            .buttonStyle(.leafSecondary)
            .padding(.top, LeafSpacing.sm)
        }
    }

    private func finish() {
        preferences.onboardingComplete = true
    }
}

/// Title followed by the icon (used for "Continue →").
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: LeafSpacing.xs) {
            configuration.title
            configuration.icon
        }
    }
}
