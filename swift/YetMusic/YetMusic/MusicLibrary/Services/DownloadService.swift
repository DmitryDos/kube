//
//  DownloadService.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 05.10.2025.
//

import Foundation

protocol DownloadService {
    func downloadFile(from url: URL, toFileName: String) async throws -> URL
}

class URLSessionDownloadService: DownloadService {
    func downloadFile(from url: URL, toFileName: String) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(toFileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        return destinationURL
    }
}
