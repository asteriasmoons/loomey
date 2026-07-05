//
//  ChallengeUserProfile.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeUserProfile {
    var id: UUID = UUID()
    var userID: String = ""
    var username: String = ""
    var avatarName: String?
    @Attribute(.externalStorage)
    var avatarURL: String?
    var avatarImageData: Data?
    var bio: String?
    var favoriteGenre: String?
    var readingStreak: Int = 0
    var challengePoints: Int = 0
    var challengesCompleted: Int = 0
    var followersCount: Int = 0
    var followingCount: Int = 0
    var isFollowing: Bool = false

    init(
        userID: String,
        username: String,
        avatarName: String? = nil,
        avatarImageData: Data? = nil,
        avatarURL: String? = nil,
        bio: String? = nil,
        favoriteGenre: String? = nil,
        isFollowing: Bool = false
    ) {
        self.id = UUID()
        self.userID = userID
        self.username = username
        self.avatarName = avatarName
        self.avatarImageData = avatarImageData
        self.avatarURL = avatarURL
        self.bio = bio
        self.favoriteGenre = favoriteGenre
        self.followersCount = 0
        self.followingCount = 0
        self.isFollowing = isFollowing
    }
}
