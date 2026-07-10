//
//  EPUBReaderDestinationView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct EPUBReaderDestinationView: View {
    let fileURL: URL
    let bookID: UUID
    let onClose: () -> Void
    let onProgressChanged: ((String) -> Void)?
    let initialLocationJSON: String?

    @Environment(\.modelContext) private var modelContext

    private var themeBackground: Color {
        let descriptor = FetchDescriptor<ReaderSettings>()
        let settings = (try? modelContext.fetch(descriptor))?.first
        let uiColor = settings?.theme.backgroundColor ?? UIColor(red: 0.008, green: 0.012, blue: 0.016, alpha: 1.0)
        return Color(uiColor: uiColor)
    }

    var body: some View {
        ZStack {
            themeBackground
                .ignoresSafeArea()

            ReadiumEPUBReaderView(
                fileURL: fileURL,
                bookID: bookID,
                onClose: onClose,
                onProgressChanged: onProgressChanged,
                initialLocationJSON: initialLocationJSON
            )
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(true)
    }
}
