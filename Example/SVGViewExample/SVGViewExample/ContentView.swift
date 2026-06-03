//
//  ContentView.swift
//  SVGViewExample
//
//  Created by Mathias Amnell on 2026-05-28.
//

import SwiftUI
import UniformTypeIdentifiers
import SVGView
import SVGViewTestAssets

struct ContentView: View {
    @State private var suites: [SVGSuiteGroup] = []
    @State private var selectedItem: DetailSelection?
    @State private var searchText = ""
    @State private var discoveryError: String?

    private var filteredSuites: [SVGSuiteGroup] {
        guard !searchText.isEmpty else { return suites }

        let needle = searchText.lowercased()

        var filtered: [SVGSuiteGroup] = []

        for suite in suites {
            var groups: [SVGFolderGroup] = []

            for group in suite.groups {
                let fixtures = group.fixtures.filter {
                    $0.name.lowercased().contains(needle)
                        || $0.relativePath.lowercased().contains(needle)
                }
                if !fixtures.isEmpty {
                    groups.append(SVGFolderGroup(name: group.name, fixtures: fixtures))
                }
            }

            if !groups.isEmpty {
                filtered.append(SVGSuiteGroup(name: suite.name, groups: groups))
            }
        }

        return filtered
    }

    private var selectedFixture: SVGFixture? {
        guard case .fixture(let selectedFixtureID) = selectedItem else { return nil }
        for suite in filteredSuites {
            for group in suite.groups {
                if let fixture = group.fixtures.first(where: { $0.id == selectedFixtureID }) {
                    return fixture
                }
            }
        }

        for suite in suites {
            for group in suite.groups {
                if let fixture = group.fixtures.first(where: { $0.id == selectedFixtureID }) {
                    return fixture
                }
            }
        }

        return nil
    }

    private var fixtureCount: Int {
        suites.reduce(into: 0) { result, suite in
            result += suite.groups.reduce(into: 0) { groupCount, group in
                groupCount += group.fixtures.count
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("W3C SVG Fixture Browser")
                            .font(.headline)
                        Text("Bundled by SVGViewTestAssets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                if let discoveryError {
                    Section("Discovery") {
                        Text(discoveryError)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }

                Section("Playground") {
                    Text("Local SVG Playground")
                        .tag(DetailSelection.localPlayground)
                }

                ForEach(filteredSuites) { suite in
                    Section(suite.name) {
                        ForEach(suite.groups) { group in
                            DisclosureGroup(group.name) {
                                ForEach(group.fixtures) { fixture in
                                    Text(fixture.name)
                                        .tag(DetailSelection.fixture(fixture.id))
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search fixture names")
            .navigationTitle("Fixtures (\(fixtureCount))")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Reload") {
                        reloadCatalog()
                    }
                }
            }
        } detail: {
            if case .localPlayground = selectedItem {
                LocalSVGPlaygroundView()
            } else if let selectedFixture {
                SVGFixtureDetailView(fixture: selectedFixture)
            } else {
                ContentUnavailableView(
                    "Select an SVG Fixture",
                    systemImage: "doc.text.image",
                    description: Text("Choose a file from the list to parse and render it.")
                )
            }
        }
        .onAppear {
            reloadCatalog()
        }
    }

    private func reloadCatalog() {
        do {
            suites = try SVGFixtureCatalog.load()
            discoveryError = nil

            if selectedFixture == nil {
                if let firstFixture = suites.first?.groups.first?.fixtures.first {
                    selectedItem = .fixture(firstFixture.id)
                }
            }
        } catch {
            suites = []
            discoveryError = "Failed to load bundled fixtures: \(error.localizedDescription)"
        }
    }
}

private struct SVGFixtureDetailView: View {
    let fixture: SVGFixture

    @State private var loadState = SVGPreviewState.idle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(fixture.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(fixture.relativePath)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Divider()

                switch loadState {
                case .idle, .loading:
                    ProgressView("Parsing SVG…")
                        .frame(maxWidth: .infinity, alignment: .center)
                case .failed(let message):
                    ContentUnavailableView(
                        "Preview Failed",
                        systemImage: "xmark.octagon",
                        description: Text(message)
                    )
                case .loaded(let node):
                    comparisonView(svgNode: node)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(fixture.name)
        .task(id: fixture.id) {
            loadState = .loading
            let result = loadNode()
            switch result {
            case .success(let node):
                loadState = .loaded(node)
            case .failure(let error):
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    private func loadNode() -> Result<SVGNode, SVGPreviewLoadError> {
        do {
            let data = try Data(contentsOf: fixture.url)
            guard let node = SVGParser.parse(data: data) else {
                return .failure(.parserReturnedNil)
            }
            return .success(node)
        } catch {
            return .failure(.unableToReadFile(error.localizedDescription))
        }
    }

    private func aspectRatio(for node: SVGNode) -> CGFloat? {
        guard let viewport = node as? SVGViewport,
              let viewBox = viewport.viewBox,
              viewBox.width > 0,
              viewBox.height > 0
        else {
            return nil
        }

        return viewBox.width / viewBox.height
    }

    @ViewBuilder
    private func comparisonView(svgNode: SVGNode) -> some View {
        HStack(alignment: .top, spacing: 12) {
            previewPane(title: "SVGView") {
                SVGView(svg: svgNode)
                    .aspectRatio(aspectRatio(for: svgNode), contentMode: .fit)
            }

            previewPane(title: "W3C PNG") {
                if let pngURL = fixture.referencePNGURL {
                    AsyncImage(url: pngURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView("Loading PNG…")
                        case .success(let image):
                            image
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(aspectRatio(for: svgNode), contentMode: .fit)
                        case .failure:
                            ContentUnavailableView(
                                "PNG Missing",
                                systemImage: "photo",
                                description: Text("Reference image could not be loaded.")
                            )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No PNG Reference",
                        systemImage: "photo",
                        description: Text("This suite does not include a matching PNG reference.")
                    )
                }
            }
        }
    }

    private func previewPane<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
                .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct LocalSVGPlaygroundView: View {
    @State private var selectedURL: URL?
    @State private var remoteURLText = ""
    @State private var sourceDescription = "No source selected"
    @State private var loadState = SVGPreviewState.idle
    @State private var showingFileImporter = false
    @State private var isDropTargeted = false

    private var sourceLabel: String {
        sourceDescription
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Local SVG Playground")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(sourceLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    Button("Choose SVG") {
                        showingFileImporter = true
                    }
                    Button("Clear") {
                        selectedURL = nil
                        sourceDescription = "No source selected"
                        loadState = .idle
                    }
                    .disabled(selectedURL == nil && remoteURLText.isEmpty)
                }

                HStack(spacing: 8) {
                    TextField("https://example.com/icon.svg", text: $remoteURLText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            loadFromRemoteURLText()
                        }
                    Button("Load URL") {
                        loadFromRemoteURLText()
                    }
                    .disabled(remoteURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                dropZone

                Divider()

                switch loadState {
                case .idle:
                    ContentUnavailableView(
                        "No SVG Selected",
                        systemImage: "doc",
                        description: Text("Drop an SVG file above or choose one from disk.")
                    )
                case .loading:
                    ProgressView("Parsing SVG…")
                        .frame(maxWidth: .infinity, alignment: .center)
                case .failed(let message):
                    ContentUnavailableView(
                        "Preview Failed",
                        systemImage: "xmark.octagon",
                        description: Text(message)
                    )
                case .loaded(let node):
                    SVGView(svg: node)
                        .aspectRatio(aspectRatio(for: node), contentMode: .fit)
                        .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Local Playground")
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType(filenameExtension: "svg") ?? .xml, .xml],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedURL = url
                parseLocalURL(url)
            case .failure(let error):
                loadState = .failed("Failed to choose file: \(error.localizedDescription)")
            }
        }
        .onChange(of: selectedURL) { _, newValue in
            if let newValue {
                parseLocalURL(newValue)
            }
        }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .frame(height: 110)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                    Text("Drop SVG file here")
                        .font(.callout)
                    Text("or use Choose SVG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            )
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let droppedURL = item as? URL {
                url = droppedURL
            } else if let text = item as? String {
                url = URL(string: text)
            } else {
                url = nil
            }

            guard let url else { return }
            DispatchQueue.main.async {
                self.selectedURL = url
                self.parseLocalURL(url)
            }
        }

        return true
    }

    private func parseLocalURL(_ selectedURL: URL) {
        sourceDescription = selectedURL.path(percentEncoded: false)
        loadState = .loading
        do {
            let scoped = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: selectedURL)
            guard let node = SVGParser.parse(data: data) else {
                loadState = .failed("Parser returned nil for this SVG file.")
                return
            }
            loadState = .loaded(node)
        } catch {
            loadState = .failed("Unable to read file: \(error.localizedDescription)")
        }
    }

    private func loadFromRemoteURLText() {
        let trimmed = remoteURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            loadState = .failed("Please enter a URL.")
            return
        }

        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            loadState = .failed("Invalid URL.")
            return
        }

        if scheme == "file" {
            selectedURL = url
            parseLocalURL(url)
            return
        }

        guard scheme == "https" || scheme == "http" else {
            loadState = .failed("Only http, https, and file URLs are supported.")
            return
        }

        selectedURL = nil
        sourceDescription = trimmed
        loadState = .loading

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        loadState = .failed("Request failed with status code \(httpResponse.statusCode).")
                    }
                    return
                }

                guard let node = SVGParser.parse(data: data) else {
                    await MainActor.run {
                        loadState = .failed("Parser returned nil for this SVG data.")
                    }
                    return
                }

                await MainActor.run {
                    loadState = .loaded(node)
                }
            } catch {
                await MainActor.run {
                    loadState = .failed("Unable to load URL: \(error.localizedDescription)")
                }
            }
        }
    }

    private func aspectRatio(for node: SVGNode) -> CGFloat? {
        guard let viewport = node as? SVGViewport,
              let viewBox = viewport.viewBox,
              viewBox.width > 0,
              viewBox.height > 0
        else {
            return nil
        }

        return viewBox.width / viewBox.height
    }
}

private enum SVGPreviewLoadError: LocalizedError {
    case parserReturnedNil
    case unableToReadFile(String)

    var errorDescription: String? {
        switch self {
        case .parserReturnedNil:
            return "Parser returned nil for this SVG file."
        case .unableToReadFile(let description):
            return "Unable to read file: \(description)"
        }
    }
}

private enum SVGPreviewState {
    case idle
    case loading
    case loaded(SVGNode)
    case failed(String)
}

private struct SVGFixtureCatalog {
    static func load() throws -> [SVGSuiteGroup] {
        let grouped = Dictionary(grouping: try SVGTestAssets.fixtures(), by: { $0.suite })

        return grouped
            .map { suiteName, suiteFixtures in
                let folderGroups = Dictionary(grouping: suiteFixtures, by: { $0.folder })
                    .map { folderName, fixtures in
                        SVGFolderGroup(
                            name: folderName,
                            fixtures: fixtures
                                .map {
                                    SVGFixture(
                                        suite: $0.suite,
                                        folder: $0.folder,
                                        name: $0.name,
                                        relativePath: $0.relativePath,
                                        referencePNGURL: $0.referencePNGURL,
                                        url: $0.svgURL
                                    )
                                }
                                .sorted(by: { lhs, rhs in
                                    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                                })
                        )
                    }
                    .sorted(by: { lhs, rhs in
                        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    })

                return SVGSuiteGroup(name: suiteName, groups: folderGroups)
            }
            .sorted(by: { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            })
    }
}

private struct SVGSuiteGroup: Identifiable {
    let name: String
    let groups: [SVGFolderGroup]

    var id: String { name }
}

private struct SVGFolderGroup: Identifiable {
    let name: String
    let fixtures: [SVGFixture]

    var id: String { name }
}

private struct SVGFixture: Identifiable {
    let suite: String
    let folder: String
    let name: String
    let relativePath: String
    let referencePNGURL: URL?
    let url: URL

    var id: String { "\(suite)|\(folder)|\(name)" }
}

private enum DetailSelection: Hashable {
    case fixture(String)
    case localPlayground
}

#Preview {
    ContentView()
}
