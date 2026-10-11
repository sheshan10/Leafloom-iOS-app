import CoreData
import PhotosUI
import SwiftUI

/// Identify tab: choose a photo (library, camera or bundled sample), run the identifier, review and save.
struct IdentifyView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var model = IdentificationViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var identifyTask: Task<Void, Never>?
    @FetchRequest(sortDescriptors: [SortDescriptor(\IdentificationRecord.dateCreated, order: .reverse)])
    private var history: FetchedResults<IdentificationRecord>

    private var samples: [PlantKnowledge] { env.knowledgeBase.entries.filter { $0.sampleAssetName != nil } }
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        let preview = model.previewImage
        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plant identification").eyebrowStyle()
                    Text("Identify").font(LeafFont.largeTitle).foregroundStyle(LeafColor.text).accessibilityAddTraits(.isHeader)
                }
                .padding(.top, LeafSpacing.md)

                modeCard

                switch model.phase {
                case let .result(result):
                    IdentificationResultView(
                        result: result,
                        image: preview,
                        selectedLabel: Binding(get: { model.selectedLabel }, set: { model.selectedLabel = $0 }),
                        onSave: saveToPlants,
                        onRetry: { model.clear() }
                    )
                default:
                    viewfinder
                    if preview == nil { sampleSection }
                }

                if !history.isEmpty { historySection }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickerItem) { _, item in
            Task { @MainActor in
                await model.loadPhoto(item)
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { model.setCameraImage($0) }.ignoresSafeArea()
        }
        .onDisappear { identifyTask?.cancel() }
        .accessibilityIdentifier("screen.identify")
    }

    // MARK: Sections

    @ViewBuilder
    private var modeCard: some View {
        switch env.identifier.mode {
        case .demo:
            EmptyView()
        case let .model(name):
            Label {
                Text("On-device model: \(name). Photos never leave your iPhone. Results are suggestions — always confirm before saving.")
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.textSecondary)
            } icon: {
                Image(systemName: "cpu").foregroundStyle(LeafColor.primary)
            }
            .leafCard(padding: LeafSpacing.sm)
        }
    }

    private var viewfinder: some View {
        let preview = model.previewImage
        let analysing = model.phase == .analysing
        let showRemove = preview != nil && !analysing
        let chooseTitle = preview == nil ? "Choose photo" : "Choose another"
        let identifyTitle = analysing ? "Analysing…" : "Identify plant"
        return VStack(spacing: LeafSpacing.md) {
            ZStack {
                if let preview {
                    Image(uiImage: preview).resizable().scaledToFill()
                        .accessibilityLabel("Selected photo")
                } else {
                    VStack(spacing: LeafSpacing.sm) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(LeafColor.primary)
                        Text("Frame a single plant in good light")
                            .font(LeafFont.subheadline)
                            .foregroundStyle(LeafColor.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                if analysing {
                    LeafColor.deep.opacity(0.45)
                    LoadingView(label: "Analysing…")
                        .colorScheme(.dark)
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .background(LeafColor.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: LeafRadius.xl, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if showRemove {
                    Button { model.clear() } label: { Image(systemName: "xmark") }
                        .buttonStyle(.leafIconOnImage)
                        .accessibilityLabel("Remove selected photo")
                        .padding(LeafSpacing.sm)
                }
            }

            if case let .failed(message) = model.phase {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("identify.error")
            }

            if preview != nil {
                Button {
                    identifyTask = Task { @MainActor in await model.identify(env: env) }
                } label: {
                    Label(identifyTitle, systemImage: "sparkle.magnifyingglass")
                }
                .buttonStyle(.leafPrimary)
                .disabled(analysing)
                .accessibilityIdentifier("identify.run")
            }

            HStack(spacing: LeafSpacing.xs) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label(chooseTitle, systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.leafSecondary)
                .accessibilityIdentifier("identify.library")
                if cameraAvailable {
                    Button { showCamera = true } label: { Label("Take photo", systemImage: "camera") }
                        .buttonStyle(.leafSecondary)
                }
            }
            .disabled(analysing)
        }
    }

    private var sampleSection: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Try a sample photo", subtitle: "Bundled with the app")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: LeafSpacing.xs)], spacing: LeafSpacing.xs) {
                ForEach(samples) { entry in
                    Button { model.selectSample(entry) } label: {
                        Image(entry.sampleAssetName ?? "")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 76)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use sample photo of \(entry.commonName)")
                    .accessibilityIdentifier("identify.sample.\(entry.key)")
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Recent identifications")
            VStack(spacing: 0) {
                ForEach(Array(history.prefix(5))) { record in
                    HistoryRow(record: record)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) { deleteRecord(record) }
                        }
                        .accessibilityAction(named: "Delete") { deleteRecord(record) }
                    if record.id != history.prefix(5).last?.id { Divider().padding(.leading, 64) }
                }
            }
            .leafCard(padding: LeafSpacing.sm)
        }
    }

    // MARK: Actions

    private func saveToPlants() {
        guard let prefill = model.plantPrefill() else { return }
        router.present(.addPlant(prefill: prefill, identificationID: model.recordID))
    }

    private func deleteRecord(_ record: IdentificationRecord) {
        do { try env.identifications.delete(record) } catch { env.toasts.showError(error) }
    }
}

private struct HistoryRow: View {
    @ObservedObject var record: IdentificationRecord

    var body: some View {
        HStack(spacing: LeafSpacing.sm) {
            PlantThumbnail(imageFilename: record.imageFilename, category: .foliage, cornerRadius: LeafRadius.sm)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.predictedLabel).font(LeafFont.headline).foregroundStyle(LeafColor.text)
                Text(record.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    .font(LeafFont.caption)
                    .foregroundStyle(LeafColor.textSecondary)
            }
            Spacer(minLength: 0)
            if record.isDemoResult {
                PillBadge(text: "Demo", systemImage: "info.circle", foreground: LeafColor.amberText, background: LeafColor.amberSoft)
            } else if let confidence = record.confidence {
                Text(confidence.formatted(.percent.precision(.fractionLength(0))))
                    .font(LeafFont.caption)
                    .foregroundStyle(LeafColor.textSecondary)
            }
            if record.plant != nil {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(LeafColor.success)
                    .accessibilityLabel("Saved to My Plants")
            }
        }
        .padding(.vertical, LeafSpacing.xxs)
        .accessibilityElement(children: .combine)
    }
}
