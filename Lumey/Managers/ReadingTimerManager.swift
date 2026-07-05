//
//  ReadingTimerManager.swift
//  Lumey
//

import Foundation
import ActivityKit
import Combine

@MainActor
final class ReadingTimerManager: ObservableObject {

    static let shared = ReadingTimerManager()

    // MARK: - Published state

    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var bookTitle: String = ""

    // MARK: - Private

    private var activity: Activity<ReadingTimerAttributes>?
    private var tickTask: Task<Void, Never>?

    /// Wall-clock time at which the current running segment started.
    private var segmentStartDate: Date?
    /// Seconds accumulated from all previous (completed) running segments.
    private var accumulatedSeconds: Int = 0

    private init() {}

    // MARK: - Public API

    var isActive: Bool { isRunning || isPaused }

    func start(bookTitle: String = "") {
        print("[ReadingTimerManager] start() called with bookTitle: \(bookTitle)")
        guard !isActive else {
            print("[ReadingTimerManager] start() ignored because timer is already active")
            return
        }
        self.bookTitle = bookTitle
        accumulatedSeconds = 0
        elapsedSeconds = 0
        beginSegment()
        startLiveActivity()
    }

    func pause() {
        guard isRunning else { return }
        stopTick()
        accumulatedSeconds = elapsedSeconds
        segmentStartDate = nil
        isRunning = false
        isPaused = true
        updateLiveActivity()
    }

    func resume() {
        guard isPaused else { return }
        beginSegment()
        updateLiveActivity()
    }

    func stop() -> (minutes: Int, pages: Int) {
        let mins = elapsedSeconds / 60
        stopTick()
        accumulatedSeconds = 0
        elapsedSeconds = 0
        segmentStartDate = nil
        isRunning = false
        isPaused = false
        endLiveActivity()
        return (mins, 0)
    }

    // MARK: - Private helpers

    private func beginSegment() {
        segmentStartDate = Date()
        isRunning = true
        isPaused = false
        startTick()
    }

    private func startTick() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, let start = self.segmentStartDate else { return }
                    self.elapsedSeconds = self.accumulatedSeconds + Int(Date().timeIntervalSince(start))
                }
            }
        }
    }

    private func stopTick() {
        tickTask?.cancel()
        tickTask = nil
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        print("[ReadingTimerManager] startLiveActivity() reached")
        print("[ReadingTimerManager] areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[ReadingTimerManager] Live Activities are disabled")
            return
        }

        let attributes = ReadingTimerAttributes(bookTitle: bookTitle)
        let contentState = ReadingTimerAttributes.ContentState(
            startDate: segmentStartDate ?? Date(),
            elapsedSeconds: 0,
            isPaused: false,
            pausedElapsedSeconds: 0
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            print("[ReadingTimerManager] Live Activity requested successfully: \(String(describing: activity?.id))")
        } catch {
            // Live Activities not available (simulator, older device)
            print("[ReadingTimerManager] Live Activity failed: \(error)")
        }
    }

    private func updateLiveActivity() {
        guard let activity else {
            print("[ReadingTimerManager] updateLiveActivity() skipped because activity is nil")
            return
        }
        print("[ReadingTimerManager] updateLiveActivity() called. isPaused: \(isPaused), elapsedSeconds: \(elapsedSeconds), accumulatedSeconds: \(accumulatedSeconds)")
        let newState = ReadingTimerAttributes.ContentState(
            startDate: segmentStartDate ?? Date(),
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            pausedElapsedSeconds: accumulatedSeconds
        )
        Task {
            await activity.update(.init(state: newState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity else {
            print("[ReadingTimerManager] endLiveActivity() skipped because activity is nil")
            return
        }
        print("[ReadingTimerManager] endLiveActivity() called")
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
