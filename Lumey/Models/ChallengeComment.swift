//
//  ChallengeComment.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeComment {
    var id: UUID = UUID()
    var submissionID: UUID = UUID()
    var userID: String = ""
    var username: String = ""
    var text: String = ""
    var createdDate: Date = Date()

    init(
        submissionID: UUID,
        userID: String,
        username: String,
        text: String
    ) {
        self.id = UUID()
        self.submissionID = submissionID
        self.userID = userID
        self.username = username
        self.text = text
        self.createdDate = Date()
    }
}
