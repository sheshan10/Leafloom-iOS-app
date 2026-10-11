import SwiftUI

struct AboutView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView {
            VStack(spacing: LeafSpacing.lg) {
                VStack(spacing: LeafSpacing.sm) {
                    Image("BrandMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                        .accessibilityHidden(true)
                    Text("LeafLoom").font(LeafFont.largeTitle).foregroundStyle(LeafColor.text)
                    Text("Grow with confidence.").font(LeafFont.headline).foregroundStyle(LeafColor.primary)
                    Text("Version \(SettingsView.versionString)").font(LeafFont.footnote).foregroundStyle(LeafColor.textSecondary)
                }
                .padding(.top, LeafSpacing.lg)
                .accessibilityElement(children: .combine)

                card("Private by design", symbol: "lock.shield",
                     "Everything — plants, photos, journal and identifications — is stored only on this device with Core Data and file protection. There is no account, analytics or server.")

                card("About identification", symbol: "sparkle.magnifyingglass", identificationText)

                card("Care guidance", symbol: "leaf",
                     env.knowledgeBase.disclaimer.isEmpty
                     ? "Care information is general guidance for common houseplants, not professional advice."
                     : env.knowledgeBase.disclaimer)

                card("Credits", symbol: "heart",
                     "Illustrations, icons and the app icon are original artwork made for LeafLoom. Sample plant photos are AI-generated for demonstration. Built with SwiftUI, Core Data, Vision, Core ML, Swift Charts and UserNotifications.")

                Text("Created for SE4041 Mobile Application Design & Development — Assignment 02.")
                    .font(LeafFont.caption)
                    .foregroundStyle(LeafColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var identificationText: String {
        switch env.identifier.mode {
        case .demo:
            "No Core ML model is bundled in this build, so identification runs in a clearly labelled demo mode that does not analyse photos. Add a compatible image-classification model (see the Core ML guide in the project docs) for real on-device suggestions."
        case let .model(name):
            "Identification uses the on-device Core ML model “\(name)” through the Vision framework. Photos never leave the device. Results are suggestions and can be wrong."
        }
    }

    private func card(_ title: String, symbol: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.xs) {
            Label(title, systemImage: symbol).font(LeafFont.headline).foregroundStyle(LeafColor.text)
            Text(text).font(LeafFont.subheadline).foregroundStyle(LeafColor.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leafCard()
    }
}
