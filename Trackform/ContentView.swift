import SwiftUI
import UniformTypeIdentifiers
import Foundation
import AppKit

// Import the FFmpegService module
@_exported import struct Foundation.URL

/// Main view for the Trackform application
struct ContentView: View {
    // MARK: - Properties
    
    /// Current metadata being edited
    @State private var metadata = MP3Metadata()
    
    /// Currently selected MP3 file
    @State private var selectedFile: URL?
    
    /// UI State
    @State private var isFilePickerPresented = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingSaveConfirmation = false
    @State private var statusMessage: String?
    @State private var showingInfoSheet = false
    
    /// User preferences
    @AppStorage("shouldAlwaysAllow") private var shouldAlwaysAllow = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                fileSelectionView
                ScrollView {
                    formFields
                }
                .background(Color.white)
            }
            .background(Color.white)
            .ignoresSafeArea(.all, edges: .all)
            .sheet(isPresented: $showingInfoSheet) {
                InfoSheetView(isPresented: $showingInfoSheet)
            }
            .alert("Message", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog(
                "Save Metadata",
                isPresented: $showingSaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save") {
                    Task {
                        await saveMetadata()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will overwrite the metadata in the selected file. Do you want to continue?")
            }
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [UTType.audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .onAppear {
                restoreBookmark()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Header view containing the app title and open file button
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Trackform")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                Button(action: { showingInfoSheet = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("About Trackform")
                Spacer()
                Button(action: { isFilePickerPresented = true }) {
                    Label("Open File", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.top, 20)
            .background(Color.white)
        }
    }
    
    /// View showing the currently selected file
    private var fileSelectionView: some View {
        Group {
            if let file = selectedFile {
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.lastPathComponent)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text(file.deletingLastPathComponent().path)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            Task {
                                do {
                                    try await loadMetadata(from: file)
                                    statusMessage = "Metadata reloaded"
                                } catch {
                                    alertMessage = "Error reloading metadata: \(error.localizedDescription)"
                                    showingAlert = true
                                }
                            }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Reload metadata from file")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .background(Color.white)
            }
        }
    }
    
    /// Form fields for editing metadata
    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                MetadataTextField(label: "Title", text: $metadata.title)
                MetadataTextField(label: "Artist", text: $metadata.artist)
                MetadataTextField(label: "Year", text: $metadata.year)
                MetadataTextField(label: "Genre", text: $metadata.genre)
            }
            .padding(.horizontal, 8)
            
            saveButton
            
            if let message = statusMessage {
                statusView(message: message)
            }
        }
        .padding(20)
        .frame(maxWidth: 400)
        .background(Color.white)
    }
    
    /// Save button with loading state
    private var saveButton: some View {
        Button(action: {
            if shouldAlwaysAllow {
                Task { await saveMetadata() }
            } else {
                showingSaveConfirmation = true
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .controlSize(.small)
                } else {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Metadata")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.accentColor)
        .disabled(selectedFile == nil || isLoading)
    }
    
    /// Status message view
    private func statusView(message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - File Operations
    
    /// Handles file selection from the file picker
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            if let file = files.first {
                guard file.startAccessingSecurityScopedResource() else {
                    alertMessage = "Permission denied to access the file"
                    showingAlert = true
                    return
                }
                
                selectedFile = file
                Task {
                    do {
                        try await loadMetadata(from: file)
                    } catch {
                        alertMessage = "Error loading metadata: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        case .failure(let error):
            alertMessage = "Error selecting file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    /// Restores the last accessed file bookmark
    private func restoreBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "bookmarkData") else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)
            
            if isStale {
                UserDefaults.standard.removeObject(forKey: "bookmarkData")
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            
            selectedFile = url
            Task {
                do {
                    try await loadMetadata(from: url)
                } catch {
                    alertMessage = "Error loading metadata: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: "bookmarkData")
        }
    }
    
    /// Loads metadata from the selected file
    private func loadMetadata(from fileURL: URL) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let metadata = try await FFmpegService.shared.readMetadata(from: fileURL)
            self.metadata = metadata
        } catch {
            alertMessage = "Error loading metadata: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    /// Saves metadata to the selected file
    private func saveMetadata() async {
        guard let file = selectedFile else { return }
        
        isLoading = true
        statusMessage = nil
        defer { isLoading = false }
        
        do {
            // Ensure we have access to the file
            guard file.startAccessingSecurityScopedResource() else {
                alertMessage = "Permission denied to access the file"
                showingAlert = true
                return
            }
            
            defer {
                file.stopAccessingSecurityScopedResource()
            }
            
            // If always allow is enabled, bookmark the file
            if shouldAlwaysAllow {
                do {
                    let bookmarkData = try file.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    UserDefaults.standard.set(bookmarkData, forKey: "bookmarkData")
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
            }
            
            // Write metadata and get the updated file URL
            let updatedFile = try await FFmpegService.shared.writeMetadata(metadata, to: file)
            
            // Update the selected file to the new URL
            selectedFile = updatedFile
            
            statusMessage = "Metadata saved successfully"
        } catch {
            alertMessage = "Error saving metadata: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Supporting Views

/// Text field for metadata input
struct MetadataTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 60, alignment: .leading)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                TextField(label, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .font(.system(size: 15))
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            .frame(height: 28)
        }
        .padding(.horizontal, 2)
    }
}

/// Info sheet view showing app information
struct InfoSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("About Trackform")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Trackform helps you manage MP3 metadata (ID3 tags) for your music files. Here's how it works:")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(number: "1", text: "Select an MP3 file using the button below")
                InfoRow(number: "2", text: "The app will attempt to extract existing metadata")
                InfoRow(number: "3", text: "Review and edit the metadata fields as needed")
                InfoRow(number: "4", text: "Click \"Set Tags\" to save your changes")
            }
            .padding()
            
            Button("Got it!") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
    }
}

/// Row in the info sheet
struct InfoRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.system(size: 15))
            Spacer()
        }
    }
}

#Preview {
    ContentView()
} 
