//
//  ReadingLibrarySettings.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingLibrarySettings {

    // MARK: - Default Filter

    var defaultStatusFilterRawValue: String = ""

    // MARK: - Init

    init(
        defaultStatusFilterRawValue: String = "All"
    ) {
        self.defaultStatusFilterRawValue = defaultStatusFilterRawValue
    }

    // MARK: - Helpers

    var defaultStatusFilter: BookStatus? {
        get {
            guard defaultStatusFilterRawValue != "All" else {
                return nil
            }

            return BookStatus(rawValue: defaultStatusFilterRawValue)
        }
        set {
            defaultStatusFilterRawValue = newValue?.rawValue ?? "All"
        }
    }
}
