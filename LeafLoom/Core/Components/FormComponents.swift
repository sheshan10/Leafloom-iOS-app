import PhotosUI
import SwiftUI
import UIKit

/// Inline validation message, announced by VoiceOver when it appears.
struct FieldError: View {
    let message: String?

    var body: some View {
        if let message {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(LeafFont.footnote)
                .foregroundStyle(LeafColor.danger)
                .onAppear { UIAccessibility.post(notification: .announcement, argument: message) }
                .accessibilityIdentifier("fieldError")
        }
    }
}

/// Optional whole-number "every N days" field. Empty means "not set".
struct DayIntervalField: View {
    let title: String
    @Binding var value: Int?
    var placeholder = "e.g. 7"
    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { text = digits }
                    value = digits.isEmpty ? nil : Int(digits.prefix(4))
                }
                .accessibilityLabel(title)
                .accessibilityValue(value.map { "\($0) days" } ?? "Not set")
            Text("days").foregroundStyle(LeafColor.textSecondary)
        }
        .onAppear { text = value.map(String.init) ?? "" }
    }
}

/// Photo picker row with library (PhotosPicker, no permission needed) and camera (when available).
struct PhotoPickerSection: View {
    let currentImage: UIImage?
    let hasImage: Bool
    var onPick: (PhotosPickerItem?) async -> Void
    var onCamera: (UIImage) -> Void
    var onRemove: () -> Void
    var error: String?
    @State private var item: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: LeafSpacing.sm) {
            ZStack {
                if let currentImage {
                    Image(uiImage: currentImage).resizable().scaledToFill()
                } else {
                    VStack(spacing: LeafSpacing.xs) {
                        Image(systemName: "photo.badge.plus").font(.largeTitle).foregroundStyle(LeafColor.primary)
                        Text("Add a photo").font(LeafFont.subheadline).foregroundStyle(LeafColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LeafColor.primarySoft)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: LeafRadius.lg, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(hasImage ? "Selected photo" : "No photo selected")

            HStack(spacing: LeafSpacing.xs) {
                PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
                    Label(hasImage ? "Change" : "Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(SecondaryButtonStyle())
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showCamera = true } label: { Label("Camera", systemImage: "camera") }
                        .buttonStyle(SecondaryButtonStyle())
                }
                if hasImage {
                    Button(role: .destructive, action: onRemove) { Image(systemName: "trash") }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: false, tint: LeafColor.danger))
                        .accessibilityLabel("Remove photo")
                }
            }
            FieldError(message: error)
        }
        .onChange(of: item) { _, newItem in
            Task { await onPick(newItem) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in onCamera(image) }
                .ignoresSafeArea()
        }
        .listRowInsets(EdgeInsets(top: LeafSpacing.sm, leading: LeafSpacing.md, bottom: LeafSpacing.sm, trailing: LeafSpacing.md))
    }
}

/// UIKit camera wrapper — the only UIKit interop in the app. Only offered when a camera exists.
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
