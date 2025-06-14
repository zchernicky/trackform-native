import SwiftUI
import UniformTypeIdentifiers
import Foundation
import AppKit

// Import the FFmpegService module
@_exported import struct Foundation.URL

struct ContentView: View {
    @State private var metadata = MP3Metadata()
    @State private var selectedFile: URL?
    @State private var isFilePickerPresented = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingSaveConfirmation = false
    @State private var statusMessage: String?
    @AppStorage("shouldAlwaysAllow") private var shouldAlwaysAllow = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Trackform")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
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
                    
                    // File Selection Status
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
                
                // Scrollable Content
                ScrollView {
                    formFields
                }
                .background(Color.white)
            }
            .background(Color.white)
            .ignoresSafeArea(.all, edges: .all)
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
                switch result {
                case .success(let files):
                    if let file = files.first {
                        // Start accessing the security-scoped resource
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
            .onAppear {
                restoreBookmark()
            }
        }
    }
    
    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Text("Title")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .leading)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        TextField("Title", text: $metadata.title)
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
                HStack(spacing: 12) {
                    Text("Artist")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .leading)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        TextField("Artist", text: $metadata.artist)
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
                HStack(spacing: 12) {
                    Text("Year")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .leading)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        TextField("Year", text: $metadata.year)
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
                HStack(spacing: 12) {
                    Text("Genre")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .leading)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        TextField("Genre", text: $metadata.genre)
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
            .padding(.horizontal, 8)

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

            if let message = statusMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: 400)
        .background(Color.white)
    }
    
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
    
    private func loadMetadata(from fileURL: URL) async throws {
        isLoading = true
        do {
            let metadata = try await FFmpegService.shared.readMetadata(from: fileURL)
            self.metadata = metadata
        } catch {
            alertMessage = "Error loading metadata: \(error.localizedDescription)"
            showingAlert = true
        }
        isLoading = false
    }
    
    private func saveMetadata() async {
        guard let file = selectedFile else { return }
        
        isLoading = true
        statusMessage = nil
        do {
            // Ensure we have access to the file
            guard file.startAccessingSecurityScopedResource() else {
                alertMessage = "Permission denied to access the file"
                showingAlert = true
                isLoading = false
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
            
            // Create metadata object
            let metadata = MP3Metadata(
                title: self.metadata.title,
                artist: self.metadata.artist,
                year: self.metadata.year,
                genre: self.metadata.genre
            )
            
            // Write metadata and get the updated file URL
            let updatedFile = try await FFmpegService.shared.writeMetadata(metadata, to: file)
            
            // Update the selected file to the new URL
            selectedFile = updatedFile
            
            statusMessage = "Metadata saved successfully"
        } catch {
            alertMessage = "Error saving metadata: \(error.localizedDescription)"
            showingAlert = true
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
} 
