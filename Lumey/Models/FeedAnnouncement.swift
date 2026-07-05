//
//  FeedAnnouncement.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class FeedAnnouncement {
    var id: UUID = UUID()
    var remoteID: String = ""
    var title: String = ""
    var body: String = ""
    var userID: String = ""
    var username: String = ""
    var avatarURL: String?
    var avatarName: String?
    var isActive: Bool = true
    var createdDate: Date = Date()

    init(
        remoteID: String = "",
        title: String,
        body: String,
        userID: String,
        username: String,
        avatarURL: String? = nil,
        avatarName: String? = nil,
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = UUID()
        self.remoteID = remoteID
        self.title = title
        self.body = body
        self.userID = userID
        self.username = username
        self.avatarURL = avatarURL
        self.avatarName = avatarName
        self.isActive = isActive
        self.createdDate = createdDate
    }

    /// Creates a local model from a backend DTO.
    static func from(dto: ChallengeFeedAnnouncementDTO) -> FeedAnnouncement {
        FeedAnnouncement(
            remoteID: dto.id ?? "",
            title: dto.title,
            body: dto.body,
            userID: dto.userID,
            username: dto.username,
            avatarURL: dto.avatarURL,
            avatarName: dto.avatarName,
            isActive: dto.isActive,
            createdDate: dto.createdDate ?? Date()
        )
    }
}
