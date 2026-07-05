//
//  ChallengeSeedData.swift
//  Lumey
//

import Foundation

// MARK: - Challenge Seed Data

enum ChallengeSeedData {

    /// Returns all seeded Lumey challenges.
    /// Call once at first launch to populate the database.
    static func allChallenges() -> [ReadingChallenge] {
        var all: [ReadingChallenge] = []
        all.append(contentsOf: readingHabitChallenges)
        all.append(contentsOf: pagesChallenges)
        all.append(contentsOf: bookCompletionChallenges)
        all.append(contentsOf: genreChallenges)
        all.append(contentsOf: reviewChallenges)
        all.append(contentsOf: ratingChallenges)
        all.append(contentsOf: seriesChallenges)
        all.append(contentsOf: authorChallenges)
        all.append(contentsOf: seasonalChallenges)
        all.append(contentsOf: bookLengthChallenges)
        all.append(contentsOf: collectionChallenges)
        all.append(contentsOf: funChallenges)
        return all
    }

    // MARK: - Reading Habit Challenges

    static let readingHabitChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "First Chapter",
            challengeDescription: "Every book begins with a single chapter. Open a new book and read the first chapter to officially begin a new reading adventure.",
            iconName: "openbook",
            category: .readingHabit,
            points: 25,
            durationDays: 1,
            requirementText: "Read the first chapter of a new book.",
            validationType: .readingSession,
            requiredSessionCount: 1
        ),
        ReadingChallenge(
            title: "Daily Reader",
            challengeDescription: "Set aside time for reading today and complete at least one reading session. A simple challenge designed to keep books part of your day.",
            iconName: "openbook",
            category: .readingHabit,
            points: 30,
            durationDays: 1,
            requirementText: "Complete at least one reading session today.",
            validationType: .readingSession,
            requiredSessionCount: 1
        ),
        ReadingChallenge(
            title: "Weekend Reader",
            challengeDescription: "Spend part of your weekend getting lost in a book. Read on both Saturday and Sunday to complete the challenge.",
            iconName: "openbook",
            category: .readingHabit,
            points: 75,
            durationDays: 2,
            requirementText: "Complete reading sessions on both Saturday and Sunday.",
            validationType: .readingSession,
            requiredSessionCount: 2,
            requiredDaysStreak: 2,
            isWeekly: true
        ),
        ReadingChallenge(
            title: "Consistent Reader",
            challengeDescription: "Reading isn't about speed—it's about showing up. Complete at least one reading session each day and build a steady reading rhythm.",
            iconName: "openbook",
            category: .readingHabit,
            points: 150,
            durationDays: 7,
            requirementText: "Read every day for 7 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 7,
            requiredDaysStreak: 7
        ),
        ReadingChallenge(
            title: "Early Bird Reader",
            challengeDescription: "Start your day with a story. Complete a reading session during the morning hours before the day fully gets underway.",
            iconName: "sun",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete a morning reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Night Owl Reader",
            challengeDescription: "Wind down with a good book before bed. Complete a reading session during the evening and end your day with a chapter or two.",
            iconName: "moonzs",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete an evening reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Lunch Break Reader",
            challengeDescription: "Turn a lunch break into reading time. Complete a reading session during the middle of your day instead of scrolling.",
            iconName: "openbook",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete a midday reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Read 3 Days",
            challengeDescription: "Read on three separate days without breaking your streak. A great starting point for building consistency.",
            iconName: "openbook",
            category: .readingHabit,
            points: 75,
            durationDays: 3,
            requirementText: "Read on 3 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 3,
            requiredDaysStreak: 3
        ),
        ReadingChallenge(
            title: "Read 7 Days",
            challengeDescription: "Spend an entire week showing up for your reading habit. Read every day for seven consecutive days.",
            iconName: "openbook",
            category: .readingHabit,
            points: 175,
            durationDays: 7,
            requirementText: "Read every day for 7 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 7,
            requiredDaysStreak: 7
        ),
        ReadingChallenge(
            title: "Read 14 Days",
            challengeDescription: "Two weeks of consistent reading can transform a habit. Read every day and keep the momentum alive.",
            iconName: "openbook",
            category: .readingHabit,
            points: 350,
            durationDays: 14,
            requirementText: "Read every day for 14 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 14,
            requiredDaysStreak: 14
        ),
        ReadingChallenge(
            title: "Read 30 Days",
            challengeDescription: "Commit to a full month of reading. Complete a reading session every day for thirty consecutive days.",
            iconName: "openbook",
            category: .readingHabit,
            points: 800,
            durationDays: 30,
            requirementText: "Read every day for 30 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 30,
            requiredDaysStreak: 30
        ),
        ReadingChallenge(
            title: "Read Every Day",
            challengeDescription: "Challenge yourself to make reading a non-negotiable part of your routine. Read daily and prove that consistency beats motivation.",
            iconName: "flame",
            category: .readingHabit,
            points: 500,
            durationDays: 21,
            requirementText: "Read every day for 21 days.",
            validationType: .readingSession,
            requiredSessionCount: 21,
            requiredDaysStreak: 21
        ),
        ReadingChallenge(
            title: "Build Momentum",
            challengeDescription: "Sometimes the hardest part is getting started. Complete reading sessions throughout the week and rebuild your reading flow one day at a time.",
            iconName: "sparkbolt",
            category: .readingHabit,
            points: 125,
            durationDays: 5,
            requirementText: "Complete reading sessions on 5 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 5
        ),
        ReadingChallenge(
            title: "Reading Routine",
            challengeDescription: "Create a reading schedule and stick to it. Complete a reading session during your chosen reading window each day.",
            iconName: "clockfill",
            category: .readingHabit,
            points: 250,
            durationDays: 10,
            requirementText: "Complete reading sessions on 10 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 10,
            requiredDaysStreak: 10
        ),
        ReadingChallenge(
            title: "Reading Comeback",
            challengeDescription: "Been away from books for a while? This challenge is all about returning to a habit you once enjoyed and rediscovering the joy of reading.",
            iconName: "openbook",
            category: .readingHabit,
            points: 100,
            durationDays: 5,
            requirementText: "Complete reading sessions on 5 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 5
        ),
    ]

    // MARK: - Pages Challenges

    static let pagesChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Read 50 Pages",
            challengeDescription: "Small progress is still progress. Read a total of 50 pages and take another meaningful step toward finishing your current book.",
            iconName: "linedpages",
            category: .pages,
            points: 50,
            durationDays: 7,
            requirementText: "Read 50 pages total.",
            validationType: .pageCount,
            requiredPageCount: 50
        ),
        ReadingChallenge(
            title: "Read 100 Pages",
            challengeDescription: "Settle into your story and make real progress. Read 100 pages across one or more reading sessions.",
            iconName: "linedpages",
            category: .pages,
            points: 100,
            durationDays: 7,
            requirementText: "Read 100 pages total.",
            validationType: .pageCount,
            requiredPageCount: 100
        ),
        ReadingChallenge(
            title: "Read 250 Pages",
            challengeDescription: "Dedicate yourself to consistent reading and work your way through 250 pages. A challenge that rewards persistence over time.",
            iconName: "linedpages",
            category: .pages,
            points: 250,
            durationDays: 14,
            requirementText: "Read 250 pages total.",
            validationType: .pageCount,
            requiredPageCount: 250
        ),
        ReadingChallenge(
            title: "Read 500 Pages",
            challengeDescription: "Half a thousand pages is no small accomplishment. Read 500 pages and prove your commitment to your reading goals.",
            iconName: "linedpages",
            category: .pages,
            points: 500,
            durationDays: 30,
            requirementText: "Read 500 pages total.",
            validationType: .pageCount,
            requiredPageCount: 500
        ),
        ReadingChallenge(
            title: "Read 1,000 Pages",
            challengeDescription: "Take on a major reading milestone. Complete 1,000 pages across your books and celebrate a truly impressive achievement.",
            iconName: "linedpages",
            category: .pages,
            points: 1000,
            durationDays: 60,
            requirementText: "Read 1,000 pages total.",
            validationType: .pageCount,
            requiredPageCount: 1000
        ),
        ReadingChallenge(
            title: "Page Turner",
            challengeDescription: "Find a book that keeps you hooked from beginning to end. Complete a longer-than-usual reading session and watch the pages fly by.",
            iconName: "linedpages",
            category: .pages,
            points: 75,
            durationDays: 1,
            requirementText: "Read 75 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 75
        ),
        ReadingChallenge(
            title: "Marathon Reader",
            challengeDescription: "Set aside dedicated reading time and immerse yourself in a book for an extended session. This challenge is all about endurance and focus.",
            iconName: "linedpages",
            category: .pages,
            points: 200,
            durationDays: 1,
            requirementText: "Read 120 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 120
        ),
        ReadingChallenge(
            title: "Power Reader",
            challengeDescription: "Push yourself beyond your normal reading pace. Read a substantial number of pages and show what focused reading can accomplish.",
            iconName: "linedpages",
            category: .pages,
            points: 300,
            durationDays: 1,
            requirementText: "Read 210 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 210
        ),
        ReadingChallenge(
            title: "Chapter Crusher",
            challengeDescription: "Some chapters are short, some are long, but every chapter completed moves the story forward. Finish multiple chapters and build momentum.",
            iconName: "linedpages",
            category: .pages,
            points: 100,
            durationDays: 1,
            requirementText: "Complete 4 chapters in a single day.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "One Sitting Wonder",
            challengeDescription: "Lose yourself in a book and keep reading until you're ready to put it down. Complete a substantial reading session in a single sitting.",
            iconName: "linedpages",
            category: .pages,
            points: 150,
            durationDays: 1,
            requirementText: "Read for at least 90 consecutive minutes in one session.",
            validationType: .readingSession,
            requiredSessionCount: 1,
            requiredSessionMinutes: 90
        ),
    ]

    // MARK: - Book Completion Challenges

    static let bookCompletionChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Finish One Book",
            challengeDescription: "Every finished book is an accomplishment worth celebrating. Read all the way to the final page and complete a book from your library.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 150,
            durationDays: 30,
            requirementText: "Finish 1 book.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish Three Books",
            challengeDescription: "Build momentum and keep turning pages. Finish three books and enjoy the satisfaction of multiple completed reading journeys.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 3 books.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Finish Five Books",
            challengeDescription: "Commit to a season of reading and make serious progress through your library. Finish five books and strengthen your reading habit.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 900,
            durationDays: 120,
            requirementText: "Finish 5 books.",
            validationType: .bookCompletion,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Finish Ten Books",
            challengeDescription: "A challenge for dedicated readers. Complete ten books and celebrate a major reading milestone that reflects consistency and commitment.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 2000,
            durationDays: 180,
            requirementText: "Finish 10 books.",
            validationType: .bookCompletion,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Finish a Duology",
            challengeDescription: "Some stories are best experienced from beginning to end. Finish both books in a duology and complete the full narrative arc.",
            iconName: "books",
            category: .bookCompletion,
            points: 400,
            durationDays: 90,
            requirementText: "Finish both books in a duology.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Finish a Trilogy",
            challengeDescription: "Follow a story across three books and see it through to its conclusion. Complete an entire trilogy from start to finish.",
            iconName: "books",
            category: .bookCompletion,
            points: 750,
            durationDays: 120,
            requirementText: "Finish all 3 books in a trilogy.",
            validationType: .series,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Complete a Series",
            challengeDescription: "Take on a larger reading adventure and finish every book in a series. Whether it's four books or fourteen, reach the final volume and complete the journey.",
            iconName: "books",
            category: .bookCompletion,
            points: 1500,
            durationDays: 365,
            requirementText: "Finish every book in a series.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Backlist Buster",
            challengeDescription: "That book has been waiting long enough. Finish a book that has been sitting in your library or TBR longer than most.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 250,
            durationDays: 30,
            requirementText: "Finish a book added to your library at least 6 months ago.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish Your Oldest Book",
            challengeDescription: "Everyone has that one neglected book they've been meaning to finish. Return to your oldest unfinished book and finally cross it off the list.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 300,
            durationDays: 45,
            requirementText: "Finish the oldest unfinished book currently in your library.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "TBR Slayer",
            challengeDescription: "Your to-be-read pile doesn't stand a chance. Finish multiple books from your TBR and make meaningful progress through your backlog.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 books marked as TBR.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Last Page Club",
            challengeDescription: "Join the club of readers who finish what they start. Complete a book and officially reach the last page.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 150,
            durationDays: 30,
            requirementText: "Finish any book.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Series Finisher",
            challengeDescription: "You've come this far—don't stop now. Finish the final unread book in a series and bring the story to its proper conclusion.",
            iconName: "books",
            category: .bookCompletion,
            points: 500,
            durationDays: 60,
            requirementText: "Complete the last remaining book in a series.",
            validationType: .series,
            requiredBookCount: 1
        ),
    ]

    // MARK: - Genre Challenges

    static let genreChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Fantasy Explorer",
            challengeDescription: "Step into worlds filled with magic, adventure, and wonder. Complete a fantasy book and immerse yourself in an unforgettable journey beyond reality.",
            iconName: "sparklybook",
            category: .genre,
            points: 150,
            durationDays: 30,
            requirementText: "Finish a Fantasy book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Fantasy"
        ),
        ReadingChallenge(
            title: "Romance Reader",
            challengeDescription: "Follow stories of connection, longing, and love. Finish a romance book and experience a heartfelt journey from beginning to end.",
            iconName: "heartfill",
            category: .genre,
            points: 150,
            durationDays: 30,
            requirementText: "Finish a Romance book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Romance"
        ),
        ReadingChallenge(
            title: "Mystery Hunter",
            challengeDescription: "Gather clues, uncover secrets, and solve the puzzle. Finish a mystery novel and see if you can piece everything together before the final reveal.",
            iconName: "searchsparkle",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Mystery or Thriller book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Thriller & Mystery"
        ),
        ReadingChallenge(
            title: "Horror Seeker",
            challengeDescription: "Face the unknown and embrace the eerie. Complete a horror book and survive every chilling twist along the way.",
            iconName: "moonzs",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Horror book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Horror"
        ),
        ReadingChallenge(
            title: "Sci-Fi Traveler",
            challengeDescription: "Explore distant futures, advanced technology, and worlds beyond imagination. Finish a science fiction book and venture into the possibilities of tomorrow.",
            iconName: "planet",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Science Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Science Fiction"
        ),
        ReadingChallenge(
            title: "Historical Journey",
            challengeDescription: "Travel to another place and time through the pages of a book. Complete a historical fiction or history title and experience the past through a new perspective.",
            iconName: "timebook",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Historical Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Historical Fiction"
        ),
        ReadingChallenge(
            title: "Nonfiction Explorer",
            challengeDescription: "Expand your knowledge and discover something new. Finish a nonfiction book focused on learning, growth, history, science, or real-world experiences.",
            iconName: "handbook",
            category: .genre,
            points: 200,
            durationDays: 45,
            requirementText: "Finish a Nonfiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Nonfiction"
        ),
        ReadingChallenge(
            title: "Genre Hopper",
            challengeDescription: "Break out of your usual reading patterns and try something different. Finish a book from a genre you haven't read recently.",
            iconName: "sparklybook",
            category: .genre,
            points: 250,
            durationDays: 30,
            requirementText: "Complete a book from a genre not read within the last 60 days.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredThemes: ["genre variety", "comfort zone"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Five Genre Challenge",
            challengeDescription: "Broaden your reading horizons and experience a variety of storytelling styles. Complete books from five different genres during the challenge period.",
            iconName: "sparklybook",
            category: .genre,
            points: 750,
            durationDays: 180,
            requirementText: "Finish books from 4 unique genres.",
            validationType: .genre,
            requiredBookCount: 4
        ),
        ReadingChallenge(
            title: "Read Outside Your Comfort Zone",
            challengeDescription: "Growth often starts with something unfamiliar. Choose a genre you rarely read and give it a genuine chance from first page to last.",
            iconName: "crossroads",
            category: .genre,
            points: 300,
            durationDays: 45,
            requirementText: "Finish a book from one of your least-read genres.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredThemes: ["comfort zone", "unfamiliar genre"],
            requiresAIValidation: true,
            isWeekly: true
        ),
    ]

    // MARK: - Review Challenges

    static let reviewChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "First Review",
            challengeDescription: "Every opinion matters. Write your first book review and share your thoughts, reactions, and overall experience with a completed read.",
            iconName: "writenote",
            category: .review,
            points: 50,
            durationDays: 7,
            requirementText: "Write 1 book review.",
            validationType: .review,
            requiredReviewCount: 1
        ),
        ReadingChallenge(
            title: "Review Writer",
            challengeDescription: "Turn your reading experience into reflection. Write reviews for multiple books and build the habit of capturing your thoughts after finishing a story.",
            iconName: "writenote",
            category: .review,
            points: 150,
            durationDays: 30,
            requirementText: "Write 3 book reviews.",
            validationType: .review,
            requiredReviewCount: 3
        ),
        ReadingChallenge(
            title: "Five Reviews",
            challengeDescription: "Become a consistent reviewer by sharing your thoughts on multiple books. Complete five reviews and start building your personal reading archive.",
            iconName: "writenote",
            category: .review,
            points: 300,
            durationDays: 60,
            requirementText: "Write 5 book reviews.",
            validationType: .review,
            requiredReviewCount: 5
        ),
        ReadingChallenge(
            title: "Ten Reviews",
            challengeDescription: "Develop a strong review-writing habit and document your reading journey in detail. Complete ten reviews and become a trusted voice in your own library.",
            iconName: "writenote",
            category: .review,
            points: 750,
            durationDays: 120,
            requirementText: "Write 10 book reviews.",
            validationType: .review,
            requiredReviewCount: 10
        ),
        ReadingChallenge(
            title: "Honest Critic",
            challengeDescription: "Not every book becomes a favorite, and that's okay. Write a thoughtful review that honestly reflects both the strengths and weaknesses of a book.",
            iconName: "writenote",
            category: .review,
            points: 100,
            durationDays: 14,
            requirementText: "Complete a review with both positive and constructive feedback.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredThemes: ["honest", "balanced", "constructive"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Thoughtful Reviewer",
            challengeDescription: "Go beyond a star rating and dig deeper into your reading experience. Write a detailed review that explores characters, plot, themes, or personal takeaways.",
            iconName: "writenote",
            category: .review,
            points: 150,
            durationDays: 14,
            requirementText: "Write a review containing at least 250 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 250
        ),
        ReadingChallenge(
            title: "Review Marathon",
            challengeDescription: "You've got opinions and it's time to share them. Write several reviews in a short period and catch up on books you've already finished.",
            iconName: "writenote",
            category: .review,
            points: 400,
            durationDays: 7,
            requirementText: "Write 5 reviews within one week.",
            validationType: .review,
            requiredReviewCount: 5
        ),
        ReadingChallenge(
            title: "Book Blogger",
            challengeDescription: "Create a substantial collection of reviews and reflections. This challenge celebrates readers who consistently document and preserve their thoughts about what they read.",
            iconName: "writenote",
            category: .review,
            points: 1000,
            durationDays: 180,
            requirementText: "Write 13 book reviews.",
            validationType: .review,
            requiredReviewCount: 13
        ),
    ]

    // MARK: - Rating Challenges

    static let ratingChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Five Star Finder",
            challengeDescription: "Every reader is searching for that unforgettable book. Read and rate a book five stars after finding a story that truly earns your highest praise.",
            iconName: "starfill",
            category: .rating,
            points: 150,
            durationDays: 60,
            requirementText: "Give one book a 5-star rating.",
            validationType: .rating,
            requiredBookCount: 1,
            requiredRating: 5
        ),
        ReadingChallenge(
            title: "Rating Collector",
            challengeDescription: "Keep your library complete by rating every book you finish. Build a collection of thoughtful ratings that reflects your reading journey.",
            iconName: "starfill",
            category: .rating,
            points: 300,
            durationDays: 60,
            requirementText: "Rate 10 completed books.",
            validationType: .rating,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Critical Reader",
            challengeDescription: "Look beyond whether you simply liked a book. Rate multiple books thoughtfully and develop the habit of evaluating each reading experience.",
            iconName: "starfill",
            category: .rating,
            points: 250,
            durationDays: 45,
            requirementText: "Rate 5 completed books.",
            validationType: .rating,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Star Giver",
            challengeDescription: "Every finished book deserves your final verdict. Rate books consistently and build a library where every completed read has a score.",
            iconName: "starfill",
            category: .rating,
            points: 150,
            durationDays: 30,
            requirementText: "Rate 5 books.",
            validationType: .rating,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Perfect Book Hunt",
            challengeDescription: "Search for the stories that stay with you long after you've turned the final page. Find and award five stars to several books that truly become favorites.",
            iconName: "starfill",
            category: .rating,
            points: 500,
            durationDays: 180,
            requirementText: "Award 5-star ratings to 5 different books.",
            validationType: .rating,
            requiredBookCount: 5,
            requiredRating: 5
        ),
    ]

    // MARK: - Series Challenges

    static let seriesChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Kingdom Conqueror",
            challengeDescription: "Some fictional worlds are worth exploring from beginning to end. Complete an entire fantasy series and earn your place among the kingdom's greatest readers.",
            iconName: "books",
            category: .series,
            points: 1000,
            durationDays: 180,
            requirementText: "Finish every book in a fantasy series.",
            validationType: .series,
            requiredBookCount: 2,
            requiredGenre: "Fantasy"
        ),
        ReadingChallenge(
            title: "Complete a Series",
            challengeDescription: "See a story through to its true ending. Read every book in a series and experience the complete journey from the first page to the final chapter.",
            iconName: "books",
            category: .series,
            points: 1000,
            durationDays: 365,
            requirementText: "Finish every book in any series.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Read a Quartet",
            challengeDescription: "Four books, one unforgettable adventure. Complete all four books in a quartet and enjoy the full story as it was meant to be experienced.",
            iconName: "books",
            category: .series,
            points: 900,
            durationDays: 180,
            requirementText: "Finish all four books in a single quartet.",
            validationType: .series,
            requiredBookCount: 4
        ),
        ReadingChallenge(
            title: "Read a Saga",
            challengeDescription: "Take on an epic reading journey spanning multiple books. Complete a long-running saga and celebrate an achievement that requires true dedication.",
            iconName: "books",
            category: .series,
            points: 1500,
            durationDays: 365,
            requirementText: "Finish a series containing at least 5 books.",
            validationType: .series,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Continue the Story",
            challengeDescription: "Don't leave a great story unfinished. Return to a series you've already started and complete the next book in the sequence.",
            iconName: "books",
            category: .series,
            points: 250,
            durationDays: 45,
            requirementText: "Finish the next unread book in an existing series.",
            validationType: .series,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish What You Started",
            challengeDescription: "Revisit a series that's been waiting on your shelf and bring it to a satisfying conclusion. Every unfinished adventure deserves an ending.",
            iconName: "books",
            category: .series,
            points: 750,
            durationDays: 180,
            requirementText: "Complete a series you've already begun.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Series Marathon",
            challengeDescription: "Stay immersed in one fictional world by reading several books from the same series back-to-back. Build momentum and keep the adventure going without switching stories.",
            iconName: "books",
            category: .series,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 3 consecutive books from the same series.",
            validationType: .series,
            requiredBookCount: 3
        ),
    ]

    // MARK: - Author Challenges

    static let authorChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Author Loyalist",
            challengeDescription: "When you find an author you love, one book is rarely enough. Read multiple books by the same author and explore more of their storytelling.",
            iconName: "pencilfill",
            category: .author,
            points: 300,
            durationDays: 90,
            requirementText: "Finish 3 books by the same author.",
            validationType: .author,
            requiredBookCount: 3,
            requiredSameAuthorCount: 3
        ),
        ReadingChallenge(
            title: "Read Three Authors",
            challengeDescription: "Expand your reading horizons by experiencing different writing styles and perspectives. Finish books by three different authors.",
            iconName: "pencilfill",
            category: .author,
            points: 250,
            durationDays: 60,
            requirementText: "Finish books by 3 unique authors.",
            validationType: .author,
            requiredBookCount: 3,
            requiredUniqueAuthorCount: 3
        ),
        ReadingChallenge(
            title: "Read Five Authors",
            challengeDescription: "Discover a wider variety of voices, worlds, and storytelling styles. Complete books by five different authors and broaden your library.",
            iconName: "pencilfill",
            category: .author,
            points: 500,
            durationDays: 120,
            requirementText: "Finish books by 5 unique authors.",
            validationType: .author,
            requiredBookCount: 5,
            requiredUniqueAuthorCount: 5
        ),
        ReadingChallenge(
            title: "Favorite Author Deep Dive",
            challengeDescription: "Spend time with the author whose stories you can't get enough of. Read several of their books and experience the depth of their work beyond a single title.",
            iconName: "pencilfill",
            category: .author,
            points: 600,
            durationDays: 180,
            requirementText: "Finish 5 books by the same author.",
            validationType: .author,
            requiredBookCount: 5,
            requiredSameAuthorCount: 5
        ),
        ReadingChallenge(
            title: "Author Explorer",
            challengeDescription: "Every new author offers a fresh perspective. Discover unfamiliar voices by reading books from authors you've never read before.",
            iconName: "pencilfill",
            category: .author,
            points: 350,
            durationDays: 90,
            requirementText: "Finish books by 3 new authors.",
            validationType: .author,
            requiredBookCount: 3,
            requiresAIValidation: false,
            requiredUniqueAuthorCount: 3
        ),
        ReadingChallenge(
            title: "New Voice",
            challengeDescription: "Take a chance on someone new. Step outside your usual favorites and discover an author making their first impression on your reading journey.",
            iconName: "pencilfill",
            category: .author,
            points: 100,
            durationDays: 30,
            requirementText: "Finish a book by an author you've never read before.",
            validationType: .author,
            requiredBookCount: 1,
            requiredUniqueAuthorCount: 1
        ),
    ]

    // MARK: - Seasonal Challenges

    static let seasonalChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Spring Reading Challenge",
            challengeDescription: "Celebrate renewal, growth, soft magic, blooming settings, fresh starts, and stories that feel alive with possibility. Complete spring-themed books that capture the feeling of new beginnings, nature returning, or life opening back up.",
            iconName: "flower",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 spring-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["spring", "renewal", "growth", "blooming", "fresh starts", "new beginnings"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Summer Reading Challenge",
            challengeDescription: "Dive into books filled with sunshine, travel, beaches, vacations, warm weather, adventure, freedom, or bright seasonal energy. Complete summer-themed books that feel like long days, golden light, and stories made for getting swept away.",
            iconName: "sun",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 summer-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["summer", "sunshine", "beach", "vacation", "adventure", "travel"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Autumn Reading Challenge",
            challengeDescription: "Settle into books with crisp air, cozy settings, falling leaves, harvest magic, school-year energy, witchy atmosphere, or reflective seasonal moods. Complete autumn-themed books that feel rich, moody, nostalgic, or deeply atmospheric.",
            iconName: "flower",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 autumn-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["autumn", "fall", "cozy", "harvest", "witchy", "atmospheric", "leaves"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Winter Reading Challenge",
            challengeDescription: "Curl up with books full of snow, cold weather, frost, isolation, winter magic, cozy interiors, survival, quiet reflection, or frozen landscapes. Complete winter-themed books that capture the stillness, beauty, danger, or comfort of the season.",
            iconName: "moonzs",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 winter-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["winter", "snow", "frost", "cozy", "cold", "frozen", "holiday"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Spooky Season Challenge",
            challengeDescription: "Embrace eerie, unsettling, haunted, witchy, gothic, monstrous, mysterious, or Halloween-coded stories. Complete books that feel made for candlelight, shadows, strange noises, and the delicious little thrill of being creeped out.",
            iconName: "moonzs",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 spooky, gothic, horror, paranormal, witchy, or Halloween-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["spooky", "gothic", "horror", "haunted", "witchy", "halloween", "paranormal"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Holiday Reading Challenge",
            challengeDescription: "Read books filled with winter holidays, festive traditions, family gatherings, seasonal romance, cozy celebration, holiday magic, or end-of-year warmth. Complete holiday-themed books that feel comforting, nostalgic, joyful, dramatic, or sparkling with seasonal charm.",
            iconName: "stargift",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 holiday-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["holiday", "christmas", "festive", "celebration", "seasonal warmth"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "February Romance Challenge",
            challengeDescription: "Celebrate love in all its forms with books centered on romance, emotional connection, longing, devotion, second chances, slow burns, or happily-ever-afters. Complete romance-themed books that make February feel sweeter, softer, or beautifully dramatic.",
            iconName: "heartfill",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 romance-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["romance", "love", "devotion", "connection", "slow burn"],
            requiresAIValidation: true
        ),
    ]

    // MARK: - Book Length Challenges

    static let bookLengthChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Quick Read",
            challengeDescription: "Not every great book needs hundreds of pages. Pick up a shorter read and enjoy the satisfaction of finishing a complete story in less time.",
            iconName: "flatbook",
            category: .bookLength,
            points: 100,
            durationDays: 30,
            requirementText: "Finish a book under 250 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMaxPages: 250
        ),
        ReadingChallenge(
            title: "Medium Read",
            challengeDescription: "The perfect balance between a quick read and an epic adventure. Complete a medium-length book and enjoy a story with plenty of room to unfold.",
            iconName: "flatbook",
            category: .bookLength,
            points: 200,
            durationDays: 45,
            requirementText: "Finish a book between 250–499 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 250,
            requiredMaxPages: 499
        ),
        ReadingChallenge(
            title: "Big Book Energy",
            challengeDescription: "Some stories demand a little more commitment. Finish a substantial novel and prove you're ready to tackle books that take readers on a longer journey.",
            iconName: "flatbook",
            category: .bookLength,
            points: 400,
            durationDays: 60,
            requirementText: "Finish a book between 500–699 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 500,
            requiredMaxPages: 699
        ),
        ReadingChallenge(
            title: "Epic Length",
            challengeDescription: "Accept the challenge of an unforgettable epic. Complete a massive book filled with rich world-building, unforgettable characters, and a story that rewards every page.",
            iconName: "flatbook",
            category: .bookLength,
            points: 700,
            durationDays: 90,
            requirementText: "Finish a book between 700–999 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 700,
            requiredMaxPages: 999
        ),
        ReadingChallenge(
            title: "Doorstopper Reader",
            challengeDescription: "The biggest books can be the most rewarding. Take on a truly enormous read and prove that no novel is too intimidating when you keep turning pages.",
            iconName: "flatbook",
            category: .bookLength,
            points: 1000,
            durationDays: 120,
            requirementText: "Finish a book with 800 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 800
        ),
        ReadingChallenge(
            title: "500 Page Club",
            challengeDescription: "Welcome to the club where bigger books become the norm. Complete a book that's at least 500 pages long and celebrate your growing reading endurance.",
            iconName: "flatbook",
            category: .bookLength,
            points: 500,
            durationDays: 60,
            requirementText: "Finish a book with 500 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 500,
            isFeatured: true
        ),
        ReadingChallenge(
            title: "700 Page Club",
            challengeDescription: "Only dedicated readers make it here. Finish a book with more than 700 pages and earn your place among readers who embrace lengthy adventures.",
            iconName: "flatbook",
            category: .bookLength,
            points: 800,
            durationDays: 90,
            requirementText: "Finish a book with 700 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 700
        ),
        ReadingChallenge(
            title: "1,000 Page Monster",
            challengeDescription: "Few books reach four digits, but the ones that do promise an unforgettable journey. Conquer a literary giant and complete a book with one thousand pages or more.",
            iconName: "flatbook",
            category: .bookLength,
            points: 1500,
            durationDays: 180,
            requirementText: "Finish a book with 1,000 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 1000
        ),
    ]

    // MARK: - Collection Challenges

    static let collectionChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Library Builder",
            challengeDescription: "Every great reading journey begins with a library worth exploring. Add books to your collection and build a personal library filled with stories you'll be excited to read for years to come.",
            iconName: "bookstand",
            category: .collection,
            points: 250,
            durationDays: 30,
            requirementText: "Add 25 books to your library.",
            validationType: .collection,
            requiredBookCount: 25
        ),
        ReadingChallenge(
            title: "Build Your TBR",
            challengeDescription: "Give your future self something to look forward to. Create a thoughtfully stocked To Be Read list filled with books that genuinely excite and inspire you.",
            iconName: "bookstand",
            category: .collection,
            points: 200,
            durationDays: 30,
            requirementText: "Add 20 books to your TBR.",
            validationType: .collection,
            requiredBookCount: 20
        ),
        ReadingChallenge(
            title: "Curated Collection",
            challengeDescription: "A meaningful library is more than a random assortment of books—it's a reflection of your interests. Organize and grow a collection that feels intentional, personal, and uniquely yours.",
            iconName: "bookstand",
            category: .collection,
            points: 400,
            durationDays: 60,
            requirementText: "Create 10 Reading Lists and add books to each one.",
            validationType: .collection,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Genre Collection",
            challengeDescription: "Celebrate the stories you love most by building a dedicated collection around a favorite genre.",
            iconName: "bookstand",
            category: .collection,
            points: 300,
            durationDays: 45,
            requirementText: "Add 20 books from the same genre to your library.",
            validationType: .collection,
            requiredBookCount: 20
        ),
        ReadingChallenge(
            title: "Author Collection",
            challengeDescription: "When one book isn't enough, build a collection around an author whose stories keep drawing you back.",
            iconName: "bookstand",
            category: .collection,
            points: 350,
            durationDays: 60,
            requirementText: "Add 10 books by the same author.",
            validationType: .collection,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Series Collection",
            challengeDescription: "Some adventures deserve an entire shelf of their own. Build a complete collection for a book series and keep every installment together.",
            iconName: "bookstand",
            category: .collection,
            points: 500,
            durationDays: 90,
            requirementText: "Add every available book from one series to your library.",
            validationType: .collection,
            requiredBookCount: 3
        ),
    ]

    // MARK: - Fun Challenges

    static let funChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Coffee & Chapters",
            challengeDescription: "Brew your favorite drink, find a comfortable place to settle in, and let a good book keep you company. Sometimes the perfect reading session starts with a warm mug and an open chapter.",
            iconName: "lovecup",
            category: .fun,
            points: 100,
            durationDays: 7,
            requirementText: "Complete 5 reading sessions while enjoying your favorite beverage.",
            validationType: .experience,
            requiredSessionCount: 5,
            requiredThemes: ["coffee", "tea", "beverage", "cozy reading"],
            requiresAIValidation: true,
            isWeekly: true
        ),
        ReadingChallenge(
            title: "Rainy Day Reader",
            challengeDescription: "There's something magical about reading while the world slows down outside. Whether it's rain tapping on the windows or simply a quiet afternoon, embrace the cozy atmosphere.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 30,
            requirementText: "Complete 3 reading sessions on rainy days.",
            validationType: .experience,
            requiredSessionCount: 3,
            requiredThemes: ["rain", "rainy day", "cozy", "atmosphere"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Cozy Reading Night",
            challengeDescription: "Blankets, pillows, soft lighting, and a great story—create the ultimate cozy reading experience and enjoy an evening that's impossible to rush.",
            iconName: "lovecup",
            category: .fun,
            points: 150,
            durationDays: 14,
            requirementText: "Complete 3 evening reading sessions lasting at least 45 minutes each.",
            validationType: .readingSession,
            requiredSessionCount: 3,
            requiredSessionMinutes: 45
        ),
        ReadingChallenge(
            title: "Candlelight Reader",
            challengeDescription: "Dim the lights, light a candle, and let the atmosphere become part of the story. Turn an ordinary reading session into something unforgettable.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 14,
            requirementText: "Complete 3 reading sessions with a cozy candlelight mood.",
            validationType: .experience,
            requiredSessionCount: 3,
            requiredThemes: ["candlelight", "candle", "cozy", "atmosphere"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Before Bed Reader",
            challengeDescription: "Trade late-night scrolling for a few peaceful chapters. End your evenings with stories instead of screens and create a relaxing bedtime ritual.",
            iconName: "moonzs",
            category: .fun,
            points: 200,
            durationDays: 14,
            requirementText: "Complete 10 bedtime reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 10
        ),
        ReadingChallenge(
            title: "Screen Free Reader",
            challengeDescription: "Disconnect from notifications and reconnect with stories. Give yourself uninterrupted reading time without the distractions of your digital world.",
            iconName: "openbook",
            category: .fun,
            points: 250,
            durationDays: 21,
            requirementText: "Complete 7 reading sessions with Focus Mode enabled.",
            validationType: .experience,
            requiredSessionCount: 7,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Read With Music",
            challengeDescription: "The right soundtrack can make every page feel cinematic. Pair your reading with music that enhances the mood and disappear into another world.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 14,
            requirementText: "Complete 5 reading sessions while using a reading playlist.",
            validationType: .experience,
            requiredSessionCount: 5,
            requiredThemes: ["music", "playlist", "soundtrack", "reading music"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Dragon Rider",
            challengeDescription: "Only the bold earn the trust of dragons. Venture into worlds filled with legendary beasts, ancient kingdoms, magical battles, and unforgettable adventures.",
            iconName: "sparklybook",
            category: .fun,
            points: 300,
            durationDays: 60,
            requirementText: "Finish 3 fantasy books featuring dragons.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["dragons", "dragon rider", "dragon fantasy"],
            requiresAIValidation: true,
            isFeatured: true
        ),
        ReadingChallenge(
            title: "Fantasy Apprentice",
            challengeDescription: "Every great mage starts somewhere. Begin your magical education with stories full of spells, enchanted worlds, magical creatures, and impossible adventures.",
            iconName: "wand",
            category: .fun,
            points: 250,
            durationDays: 45,
            requirementText: "Finish 2 fantasy books centered around magic.",
            validationType: .seasonalTheme,
            requiredBookCount: 2,
            requiredThemes: ["magic", "spells", "enchantment", "wizardry"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Royal Reader",
            challengeDescription: "Walk among queens, kings, princes, princesses, and noble houses. Read stories filled with courts, kingdoms, politics, power, and unforgettable rulers.",
            iconName: "sparklybook",
            category: .fun,
            points: 250,
            durationDays: 45,
            requirementText: "Finish 3 books featuring royalty or noble courts.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["royalty", "kings", "queens", "court", "kingdom", "noble"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Story Collector",
            challengeDescription: "Every finished book becomes another story you'll carry with you forever. Build a growing collection of completed adventures, unforgettable characters, and memorable worlds.",
            iconName: "bookstack",
            category: .fun,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 10 books from 10 different authors.",
            validationType: .author,
            requiredBookCount: 10,
            requiredUniqueAuthorCount: 10
        ),
        ReadingChallenge(
            title: "Bookworm",
            challengeDescription: "You don't just enjoy books—you live among them. Read consistently, explore new stories, and proudly embrace your inner bookworm.",
            iconName: "bookstack",
            category: .fun,
            points: 750,
            durationDays: 90,
            requirementText: "Complete 30 reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 30
        ),
        ReadingChallenge(
            title: "Bookworm In Training",
            challengeDescription: "Every lifelong reader starts with a single page. Build the habit one reading session at a time and watch your love of books continue to grow.",
            iconName: "bookstack",
            category: .fun,
            points: 200,
            durationDays: 60,
            requirementText: "Complete 15 reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 15
        ),
        ReadingChallenge(
            title: "Shelf Explorer",
            challengeDescription: "Hidden among your shelves are books waiting patiently for their turn. Rediscover forgotten titles and give overlooked stories the attention they deserve.",
            iconName: "bookstand",
            category: .fun,
            points: 300,
            durationDays: 90,
            requirementText: "Finish 3 books that have been in your library for over one year.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
    ]
}
