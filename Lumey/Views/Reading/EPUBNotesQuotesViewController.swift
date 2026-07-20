//
//  EPUBNotesQuotesViewController.swift
//  Lumey
//

import UIKit

final class EPUBNotesQuotesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var highlights: [EPUBHighlight]
    private let theme: ReaderTheme
    private let onSelect: (EPUBHighlight) -> Void
    private let onDelete: (EPUBHighlight) -> Void

    private let tableView = UITableView(frame: .zero, style: .plain)

    init(
        highlights: [EPUBHighlight],
        theme: ReaderTheme,
        onSelect: @escaping (EPUBHighlight) -> Void,
        onDelete: @escaping (EPUBHighlight) -> Void
    ) {
        self.highlights = highlights
        self.theme = theme
        self.onSelect = onSelect
        self.onDelete = onDelete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.chromeBackgroundColor
        navigationController?.setNavigationBarHidden(true, animated: false)

        let titleLabel = UILabel()
        titleLabel.text = "Notes & Quotes"
        titleLabel.textColor = theme.chromeTextColor
        titleLabel.font = UIFont.rounded(size: 24, weight: .black)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = LumeyGradientIconButton(assetName: "xmarkwavy")
        closeButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            titleLabel.heightAnchor.constraint(equalToConstant: 36),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        if highlights.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No notes or quotes yet.\nSelect text while reading to annotate."
            emptyLabel.textColor = theme.chromeTextColor.withAlphaComponent(0.4)
            emptyLabel.font = UIFont.rounded(size: 14, weight: .semibold)
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyLabel)

            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40)
            ])
            return
        }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EPUBHighlightCell.self, forCellReuseIdentifier: EPUBHighlightCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        highlights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EPUBHighlightCell.reuseID, for: indexPath) as! EPUBHighlightCell
        cell.configure(highlight: highlights[indexPath.row], theme: theme)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(highlights[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            let highlight = highlights[indexPath.row]
            onDelete(highlight)
            highlights.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    @objc private func closeSheet() {
        dismiss(animated: true)
    }
}

// MARK: - Highlight Cell

final class EPUBHighlightCell: UITableViewCell {
    static let reuseID = "EPUBHighlightCell"

    private let cardView = UIView()
    private let colorBar = UIView()
    private let passageLabel = UILabel()
    private let noteLabel = UILabel()
    private let metaLabel = UILabel()
    private let typeIcon = LumeyGradientIconImageView(assetName: "quote")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1
        cardView.clipsToBounds = true

        colorBar.translatesAutoresizingMaskIntoConstraints = false

        passageLabel.translatesAutoresizingMaskIntoConstraints = false
        passageLabel.font = UIFont(name: "Georgia-Italic", size: 14) ?? .italicSystemFont(ofSize: 14)
        passageLabel.numberOfLines = 3
        passageLabel.lineBreakMode = .byTruncatingTail

        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.font = UIFont.rounded(size: 13, weight: .semibold)
        noteLabel.numberOfLines = 2
        noteLabel.lineBreakMode = .byTruncatingTail

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = UIFont.rounded(size: 11, weight: .bold)
        metaLabel.numberOfLines = 1

        typeIcon.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(colorBar)
        cardView.addSubview(typeIcon)
        cardView.addSubview(passageLabel)
        cardView.addSubview(noteLabel)
        cardView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            colorBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            colorBar.topAnchor.constraint(equalTo: cardView.topAnchor),
            colorBar.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            colorBar.widthAnchor.constraint(equalToConstant: 4),

            typeIcon.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            typeIcon.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 12),
            typeIcon.widthAnchor.constraint(equalToConstant: 16),
            typeIcon.heightAnchor.constraint(equalToConstant: 16),

            passageLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            passageLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 8),
            passageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            noteLabel.topAnchor.constraint(equalTo: passageLabel.bottomAnchor, constant: 8),
            noteLabel.leadingAnchor.constraint(equalTo: passageLabel.leadingAnchor),
            noteLabel.trailingAnchor.constraint(equalTo: passageLabel.trailingAnchor),

            metaLabel.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 8),
            metaLabel.leadingAnchor.constraint(equalTo: passageLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: passageLabel.trailingAnchor),
            metaLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(highlight: EPUBHighlight, theme: ReaderTheme) {
        let color = highlight.highlightColor

        cardView.backgroundColor = theme.chromeTextColor.withAlphaComponent(0.055)
        cardView.layer.borderColor = theme.chromeBorderColor.cgColor
        colorBar.backgroundColor = color.uiColor

        passageLabel.textColor = theme.chromeTextColor.withAlphaComponent(0.8)
        passageLabel.text = highlight.highlightedText.isEmpty ? nil : "\"\(highlight.highlightedText)\""
        passageLabel.isHidden = highlight.highlightedText.isEmpty

        noteLabel.textColor = theme.chromeTextColor
        noteLabel.text = highlight.note.isEmpty ? nil : highlight.note
        noteLabel.isHidden = highlight.note.isEmpty

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var metaParts: [String] = []
        if highlight.isQuote { metaParts.append("Quote") }
        if !highlight.note.isEmpty && !highlight.isQuote { metaParts.append("Note") }
        if !highlight.chapterTitle.isEmpty { metaParts.append(highlight.chapterTitle) }
        if highlight.pageNumber > 0 { metaParts.append("pg \(highlight.pageNumber)") }
        metaParts.append(formatter.string(from: highlight.createdAt))

        metaLabel.text = metaParts.joined(separator: " · ")
        metaLabel.textColor = theme.chromeTextColor.withAlphaComponent(0.4)
    }
}
