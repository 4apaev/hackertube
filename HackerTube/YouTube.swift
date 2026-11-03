import Foundation

enum YouTube {
    /// Opens the video in the YouTube app on Apple TV.
    /// YouTube does not document this link format. Change it here if the YouTube app stops accepting it.
    static func appURL(_ vid: String) -> URL {
        URL(string: "youtube://watch/\(vid)")!
    }

    static func webURL(_ vid: String) -> URL {
        URL(string: "https://www.youtube.com/watch?v=\(vid)")!
    }

    /// hqdefault is 4:3 with black bars; crop it to 16:9. maxresdefault is 16:9 but some videos lack it.
    static func thumbnailURL(_ vid: String, quality: String = "hqdefault") -> URL? {
        URL(string: "https://i.ytimg.com/vi/\(vid)/\(quality).jpg")
    }
}
