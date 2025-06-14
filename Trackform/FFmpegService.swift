import Foundation

/// Service responsible for handling MP3 metadata operations using FFmpeg
class FFmpegService {
    /// Shared instance for singleton access
    static let shared = FFmpegService()
    
    /// Custom errors that can occur during FFmpeg operations
    enum FFmpegError: Error {
        case fileAccessDenied
        case tempFileCreationFailed
        case ffmpegExecutionFailed(String)
        
        var localizedDescription: String {
            switch self {
            case .fileAccessDenied:
                return "Permission denied to access the file"
            case .tempFileCreationFailed:
                return "Failed to create temporary output file"
            case .ffmpegExecutionFailed(let message):
                return "FFmpeg execution failed: \(message)"
            }
        }
    }
    
    private init() {}
    
    /// Returns the path to the FFmpeg executable
    /// First checks the app bundle, then falls back to Homebrew installation
    private var ffmpegPath: String {
        if let resourcePath = Bundle.main.resourcePath {
            let ffmpegPath = resourcePath + "/ffmpeg"
            if FileManager.default.fileExists(atPath: ffmpegPath) {
                return ffmpegPath
            }
        }
        return "/opt/homebrew/bin/ffmpeg"
    }
    
    /// Reads metadata from an MP3 file using FFmpeg
    /// - Parameter fileURL: URL of the MP3 file to read
    /// - Returns: MP3Metadata object containing the file's metadata
    func readMetadata(from fileURL: URL) async throws -> MP3Metadata {
        // Ensure we have access to the file
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw FFmpegError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let process = Process()
        let pipe = Pipe()
        
        // Configure FFmpeg process to read metadata
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-i", fileURL.path, "-f", "ffmetadata", "-"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Parse FFmpeg output
            let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseMetadata(from: output)
        } catch {
            throw FFmpegError.ffmpegExecutionFailed(error.localizedDescription)
        }
    }
    
    /// Parses FFmpeg output into MP3Metadata
    private func parseMetadata(from output: String) -> MP3Metadata {
        var metadata = MP3Metadata()
        
        // Extract metadata fields from FFmpeg output
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let components = line.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else { continue }
            
            let key = components[0]
            let value = String(components[1])
            
            switch key {
            case "title": metadata.title = value
            case "artist": metadata.artist = value
            case "date": metadata.year = value
            case "genre": metadata.genre = value
            default: break
            }
        }
        
        return metadata
    }
    
    /// Writes metadata to an MP3 file using FFmpeg
    /// - Parameters:
    ///   - metadata: MP3Metadata object containing the metadata to write
    ///   - file: URL of the MP3 file to modify
    /// - Returns: URL of the modified file
    func writeMetadata(_ metadata: MP3Metadata, to file: URL) async throws -> URL {
        // Ensure we have access to the file
        guard file.startAccessingSecurityScopedResource() else {
            throw FFmpegError.fileAccessDenied
        }
        defer { file.stopAccessingSecurityScopedResource() }
        
        // Create temporary file for the modified version
        let tempOutputFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        // Build FFmpeg command arguments
        let arguments = buildFFmpegArguments(for: metadata, inputFile: file, outputFile: tempOutputFile)
        
        // Configure and run FFmpeg process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = arguments
        
        // Set up pipes for capturing output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Log FFmpeg output for debugging
            logFFmpegOutput(outputPipe: outputPipe, errorPipe: errorPipe)
            
            // Verify temporary file creation
            guard FileManager.default.fileExists(atPath: tempOutputFile.path) else {
                throw FFmpegError.tempFileCreationFailed
            }
            
            // Replace original file with modified version
            try FileManager.default.removeItem(at: file)
            try FileManager.default.moveItem(at: tempOutputFile, to: file)
            
            return file
        } catch {
            throw FFmpegError.ffmpegExecutionFailed(error.localizedDescription)
        }
    }
    
    /// Builds FFmpeg command line arguments for metadata writing
    private func buildFFmpegArguments(for metadata: MP3Metadata, inputFile: URL, outputFile: URL) -> [String] {
        var arguments = ["-i", inputFile.path]
        
        // Add metadata flags for non-empty fields
        if !metadata.title.isEmpty {
            arguments.append(contentsOf: ["-metadata", "title=\(metadata.title)"])
        }
        if !metadata.artist.isEmpty {
            arguments.append(contentsOf: ["-metadata", "artist=\(metadata.artist)"])
        }
        if !metadata.year.isEmpty {
            arguments.append(contentsOf: ["-metadata", "date=\(metadata.year)"])
        }
        if !metadata.genre.isEmpty {
            arguments.append(contentsOf: ["-metadata", "genre=\(metadata.genre)"])
        }
        
        // Add remaining arguments for copying codec and output
        arguments.append(contentsOf: ["-codec", "copy", "-y", outputFile.path])
        
        return arguments
    }
    
    /// Logs FFmpeg output and error messages for debugging
    private func logFFmpegOutput(outputPipe: Pipe, errorPipe: Pipe) {
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            print("FFmpeg output: \(output)")
        }
        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
            print("FFmpeg error: \(error)")
        }
    }
}