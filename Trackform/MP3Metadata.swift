import Foundation

/// Model representing MP3 file metadata
struct MP3Metadata: Equatable {
    /// The title of the track
    var title: String
    
    /// The artist or performer of the track
    var artist: String
    
    /// The year the track was released
    var year: String
    
    /// The genre of the track
    var genre: String
    
    /// Creates a new MP3Metadata instance with empty values
    init() {
        self.title = ""
        self.artist = ""
        self.year = ""
        self.genre = ""
    }
    
    /// Creates a new MP3Metadata instance with the specified values
    /// - Parameters:
    ///   - title: The title of the track
    ///   - artist: The artist or performer of the track
    ///   - year: The year the track was released
    ///   - genre: The genre of the track
    init(title: String, artist: String, year: String, genre: String) {
        self.title = title
        self.artist = artist
        self.year = year
        self.genre = genre
    }
    
    /// Returns true if all metadata fields are empty
    var isEmpty: Bool {
        title.isEmpty && artist.isEmpty && year.isEmpty && genre.isEmpty
    }
    
    /// Returns true if any metadata field is non-empty
    var hasAnyMetadata: Bool {
        !isEmpty
    }
}