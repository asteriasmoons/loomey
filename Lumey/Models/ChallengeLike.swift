//
//  ChallengeLike.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeLike {
    var id: UUID = UUID()
    var submissionID: UUID = UUID()
    var userID: String = ""
    var createdDate: Date = Date()

    init(
        submissionID: UUID,
        userID: String
    ) {
        self.id = UUID()
        self.submissionID = submissionID
        self.userID = userID
        self.createdDate = Date()
    }
}
