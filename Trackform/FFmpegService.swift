import Foundation

class FFmpegService {
    static let shared = FFmpegService()
    
    private init() {}
    
    private var ffmpegPath: String {
        if let resourcePath = Bundle.main.resourcePath {
            let ffmpegPath = resourcePath + "/ffmpeg"
            if FileManager.default.fileExists(atPath: ffmpegPath) {
                return ffmpegPath
            }
        }
        return "/opt/homebrew/bin/ffmpeg"
    }
    
    func readMetadata(from fileURL: URL) async throws -> MP3Metadata {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-i", fileURL.path, "-f", "ffmetadata", "-"]
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        var metadata = MP3Metadata()
        
        // Parse the FFmpeg output
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("title=") {
                metadata.title = String(line.dropFirst(6))
            } else if line.hasPrefix("artist=") {
                metadata.artist = String(line.dropFirst(7))
            } else if line.hasPrefix("date=") {
                metadata.year = String(line.dropFirst(5))
            } else if line.hasPrefix("genre=") {
                metadata.genre = String(line.dropFirst(6))
            }
        }
        
        return metadata
    }
    
    func writeMetadata(_ metadata: MP3Metadata, to file: URL) async throws -> URL {
        // Create a temporary output file in the app's temporary directory
        let tempOutputFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(file.lastPathComponent).temp.mp3")
        
        // Build FFmpeg arguments with direct metadata flags
        var arguments = ["-i", file.path]
        
        // Add metadata flags for non-empty fields
        if !metadata.title.isEmpty {
            arguments.append("-metadata")
            arguments.append("title=\(metadata.title)")
        }
        if !metadata.artist.isEmpty {
            arguments.append("-metadata")
            arguments.append("artist=\(metadata.artist)")
        }
        if !metadata.year.isEmpty {
            arguments.append("-metadata")
            arguments.append("date=\(metadata.year)")
        }
        if !metadata.genre.isEmpty {
            arguments.append("-metadata")
            arguments.append("genre=\(metadata.genre)")
        }
        
        // Add remaining arguments
        arguments.append(contentsOf: ["-codec", "copy", "-y", tempOutputFile.path])
        
        // Run FFmpeg to write metadata
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = arguments
        
        // Capture FFmpeg output for debugging
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        // Read FFmpeg output for debugging
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
            print("FFmpeg output: \(output)")
        }
        if let error = String(data: errorData, encoding: .utf8) {
            print("FFmpeg error: \(error)")
        }
        
        // Check if the original file exists and is accessible
        guard file.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "FFmpegService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access the original file"])
        }
        
        defer {
            file.stopAccessingSecurityScopedResource()
        }
        
        // Check if the temporary output file was created successfully
        guard FileManager.default.fileExists(atPath: tempOutputFile.path) else {
            throw NSError(domain: "FFmpegService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create temporary output file"])
        }
        
        // Remove the original file and move the temporary file to replace it
        try FileManager.default.removeItem(at: file)
        try FileManager.default.moveItem(at: tempOutputFile, to: file)
        
        return file
    }
}