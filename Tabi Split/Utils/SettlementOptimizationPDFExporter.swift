//
//  SettlementOptimizationPDFExporter.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/08/26.
//

import UIKit

/// One participant's balance breakdown, mirroring `OptimizationPersonCard`.
struct OptimizationPersonPDFData {
    var name: String
    var isCurrentUser: Bool
    var lent: Float
    var debt: Float
    var balance: Float
    /// Human-readable status ("Should pay" / "Should receive" / "Settled").
    var statusText: String
}

/// One "who pays whom" line, mirroring a row of `OptimizationRecapCard`.
struct OptimizationRecapPDFData {
    var fromName: String
    var toName: String
    var amount: Float
}

/// One person sharing a line item, and how much of it they cover.
struct OptimizationAssigneePDFData {
    var name: String
    var share: Float
}

/// A single line item within an expense (e.g. "Chicken", "Rice"), and who shares it.
struct OptimizationExpenseItemPDFData {
    var name: String
    var quantity: Float
    var price: Float
    var assignees: [OptimizationAssigneePDFData]
}

/// An additional charge on an expense (e.g. Tax, Service, Discount).
struct OptimizationAdditionalChargePDFData {
    var typeName: String
    var amount: Float
}

/// One expense of the event: the receipt name, who paid for it, the total, the
/// split method, and — for custom splits — its finer line-item breakdown plus
/// any additional charges (tax / service / discount / other).
struct OptimizationExpensePDFData {
    var name: String
    /// When the expense was created; the list is sorted by this and it is shown under the title.
    var date: Date
    var payerName: String
    var amount: Float
    /// Whether the expense was split equally. Equal splits omit the item breakdown.
    var isEquallySplit: Bool
    /// For equal splits, the per-person amount (total ÷ participants); nil otherwise.
    var equalSplitPerPerson: Float?
    /// For equal splits, the participants sharing it (may be a subset of the event).
    var participantNames: [String]
    var items: [OptimizationExpenseItemPDFData]
    var additionalCharges: [OptimizationAdditionalChargePDFData]
}

/// An uploaded purchase receipt, already downloaded, rendered in the final
/// "Receipts" section with the expense it belongs to as its caption.
struct OptimizationReceiptPDFData {
    var expenseName: String
    var date: Date
    var amount: Float
    var image: UIImage
}

/// Immutable snapshot of everything needed to render the Settlement Optimization
/// page as a PDF. Extracted from `EventViewModel` so the exporter stays a pure,
/// testable function.
struct SettlementOptimizationPDFData {
    var eventName: String
    var generatedByName: String
    var persons: [OptimizationPersonPDFData]
    /// Netted "who pays whom" — the fewest-transfers view.
    var simplifiedRecap: [OptimizationRecapPDFData]
    /// Raw pairwise debts — every direct debt between two people, no netting.
    var detailedRecap: [OptimizationRecapPDFData]
    var expenses: [OptimizationExpensePDFData]
    /// Uploaded expense receipts, in expense order. Rendered as the final section.
    var receipts: [OptimizationReceiptPDFData] = []
}

/// Builds a paginated, shareable PDF of the Settlement Optimization page.
enum SettlementOptimizationPDFExporter {

    // MARK: - Theme

    /// Palette and type mirroring tabisplit.my.id (`globals.css`): a warm cream
    /// page, ink text, hairline sand rules, and a single blue accent. Figtree is
    /// bundled with the app; system fonts are only a safety net.
    private enum Theme {
        static let cream = UIColor(hex: "#fffdf7")
        static let ink = UIColor(hex: "#1d1d1d")
        static let inkSoft = UIColor(hex: "#55524c")
        static let muted = UIColor(hex: "#8a857c")
        static let line = UIColor(hex: "#ece5d7")
        static let blue = UIColor(hex: "#62abf6")
        static let green = UIColor(hex: "#00880d")
        static let pink = UIColor(hex: "#bb699b")
        static let red = UIColor(hex: "#e4100f")

        static let tagline = "Record together, split fairly, settle with the fewest payments."
        static let cardRadius: CGFloat = 12

        enum Weight: String {
            case regular = "Figtree-Regular"
            case medium = "Figtree-Medium"
            case semibold = "Figtree-SemiBold"
            case bold = "Figtree-Bold"

            var system: UIFont.Weight {
                switch self {
                case .regular: return .regular
                case .medium: return .medium
                case .semibold: return .semibold
                case .bold: return .bold
                }
            }
        }

        static func font(_ weight: Weight, _ size: CGFloat) -> UIFont {
            UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: weight.system)
        }

        /// Web headings are tight-tracked; a small negative kern gets the same feel.
        static func attributes(_ weight: Weight, _ size: CGFloat, _ color: UIColor, kern: CGFloat = 0) -> [NSAttributedString.Key: Any] {
            var attributes: [NSAttributedString.Key: Any] = [.font: font(weight, size), .foregroundColor: color]
            if kern != 0 { attributes[.kern] = kern }
            return attributes
        }
    }

    // MARK: - Money formatting

    /// Formats an amount the same way the app UI does: an `Rp` prefix plus an
    /// explicit `+`/`-` sign so positives and negatives read correctly even in
    /// grayscale (where the color coding is lost).
    private static func formatMoney(_ amount: Float, showSign: Bool = false) -> String {
        let magnitude = abs(amount).formatPrice(isShowSign: false)
        guard showSign else { return "Rp\(magnitude)" }
        let sign = amount < 0 ? "-" : "+"
        return "\(sign)Rp\(magnitude)"
    }

    // MARK: - Public API

    static func generatePDF(from data: SettlementOptimizationPDFData) -> Data {
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 portrait
        let leftMargin: CGFloat = 40
        let rightMargin: CGFloat = 40
        let contentWidth = pageSize.width - leftMargin - rightMargin
        // Content sits between the page header (ends at 64) and footer (starts at 796).
        let contentTop: CGFloat = 72
        let pageBottom: CGFloat = pageSize.height - 60

        var pageY: CGFloat = contentTop
        var pageNumber = 0

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

        return renderer.pdfData { context in
            /// Starts a new page with the cream background, wordmark header and
            /// tagline/page-number footer, then resets the cursor under the header.
            /// Every page break in the document goes through here.
            func newPage() {
                context.beginPage()
                pageNumber += 1
                pageY = drawPageChrome(eventName: data.eventName, pageNumber: pageNumber,
                                       pageSize: pageSize, leftMargin: leftMargin, contentWidth: contentWidth,
                                       contentTop: contentTop)
            }

            /// Page-breaks and repeats the section title when `needed` points won't fit.
            func ensureSpace(_ needed: CGFloat, continuing sectionTitle: String) {
                guard pageY + needed > pageBottom else { return }
                newPage()
                pageY = drawSectionTitle("\(sectionTitle) (cont.)", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
                pageY += 6
            }

            newPage()

            // ---- Title block ----
            pageY = drawTitleBlock(eventName: data.eventName, generatedBy: data.generatedByName,
                                   maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 22

            // ---- Participant balances ----
            pageY = drawSectionTitle("Participant Balances", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 4

            if data.persons.isEmpty {
                pageY = drawInfoRow(label: "No participants.", value: "", maxY: pageY,
                                    leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            }

            for person in data.persons {
                ensureSpace(84, continuing: "Participant Balances")
                pageY = drawPersonCard(person, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                pageY += 12
            }

            // ---- Recapitulation (who pays whom) — always starts on its own page ----
            // Two subsections: "Simplified" (netted) and "Detailed" (raw pairwise).
            newPage()
            pageY = drawSectionTitle("Recapitulation", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 6

            /// Draws one recap subsection (a subtitle, a column header, then the
            /// rows) with the same page-break handling as the rest of the doc.
            func drawRecapSubsection(_ title: String, subtitle: String, rows: [OptimizationRecapPDFData], emptyText: String) {
                // Keep the subtitle + header together with at least one row.
                ensureSpace(70, continuing: "Recapitulation")
                pageY = drawSubsectionTitle(title, subtitle: subtitle, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
                pageY += 4
                pageY = drawRecapHeader(maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                pageY += 4

                if rows.isEmpty {
                    pageY = drawInfoRow(label: emptyText, value: "", maxY: pageY,
                                        leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                }

                for entry in rows {
                    if pageY + 24 > pageBottom {
                        ensureSpace(24, continuing: "Recapitulation")
                        pageY = drawSubsectionTitle("\(title) (cont.)", subtitle: nil, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
                        pageY += 4
                        pageY = drawRecapHeader(maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                        pageY += 4
                    }
                    pageY = drawRecapRow(entry, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                }
            }

            drawRecapSubsection(
                "Simplified", subtitle: "Netted to the fewest transfers.",
                rows: data.simplifiedRecap,
                emptyText: "Everyone is settled — no payments needed."
            )
            pageY += 16
            drawRecapSubsection(
                "Detailed", subtitle: "Every direct debt, without netting.",
                rows: data.detailedRecap,
                emptyText: "Everyone is settled — no payments needed."
            )

            // ---- Expense list with per-item breakdown (always starts on its own page) ----
            newPage()
            pageY = drawSectionTitle("Expense List", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 6

            if data.expenses.isEmpty {
                pageY = drawInfoRow(label: "No expenses recorded.", value: "", maxY: pageY,
                                    leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            }

            for expense in data.expenses {
                // Keep the expense header with at least its first item on the same page.
                ensureSpace(54, continuing: "Expense List")
                pageY = drawExpenseGroupHeader(expense, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)

                // Equal splits carry no per-item detail, but list the participants sharing it
                // (which may be only a subset of the event's members).
                if expense.isEquallySplit {
                    if !expense.participantNames.isEmpty {
                        pageY = drawParticipantsRow(expense.participantNames, maxY: pageY, leftMargin: leftMargin, pageWidth: pageSize.width)
                    }
                } else {
                    if expense.items.isEmpty {
                        pageY = drawExpenseItemRow(name: "No itemised breakdown.", quantity: nil, price: nil,
                                                   maxY: pageY, leftMargin: leftMargin, pageWidth: pageSize.width)
                    }

                    for item in expense.items {
                        ensureSpace(20, continuing: "Expense List")
                        pageY = drawExpenseItemRow(name: item.name, quantity: item.quantity, price: item.price,
                                                   maxY: pageY, leftMargin: leftMargin, pageWidth: pageSize.width)

                        // Assignees (who shares this item) sit indented under it.
                        if !item.assignees.isEmpty {
                            ensureSpace(18, continuing: "Expense List")
                            pageY = drawAssigneesRow(item.assignees, maxY: pageY, leftMargin: leftMargin, pageWidth: pageSize.width)
                        }
                    }

                    // Additional charges (tax / service / discount / other) — no assignees.
                    for charge in expense.additionalCharges {
                        ensureSpace(20, continuing: "Expense List")
                        pageY = drawExpenseItemRow(name: charge.typeName, quantity: nil, price: charge.amount,
                                                   maxY: pageY, leftMargin: leftMargin, pageWidth: pageSize.width)
                    }
                }
                pageY += 14
            }

            // ---- Receipts (always the final section, on its own page) ----
            newPage()
            pageY = drawSectionTitle("Receipts", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 6

            if data.receipts.isEmpty {
                pageY = drawInfoRow(label: "No receipts were attached to this event's expenses.", value: "", maxY: pageY,
                                    leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            }

            // Receipts sit in a 2×2 grid, four per page. Every cell is caption-over-image;
            // the image is aspect-fit inside its cell so nothing is ever cropped.
            let columns = 2
            let rowsPerPage = 2
            let gutter: CGFloat = 16
            let captionHeight: CGFloat = 20
            let cellWidth = (contentWidth - gutter) / CGFloat(columns)

            for (index, receipt) in data.receipts.enumerated() {
                let slot = index % (columns * rowsPerPage)
                if index > 0 && slot == 0 {
                    newPage()
                    pageY = drawSectionTitle("Receipts (cont.)", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
                    pageY += 6
                }
                // Rows split the space left under the section title evenly, so cells line
                // up regardless of each image's shape. pageY stays put for the whole page.
                let rowHeight = (pageBottom - pageY - gutter) / CGFloat(rowsPerPage)
                let column = slot % columns
                let row = slot / columns
                let cell = CGRect(x: leftMargin + CGFloat(column) * (cellWidth + gutter),
                                  y: pageY + CGFloat(row) * (rowHeight + gutter),
                                  width: cellWidth,
                                  height: rowHeight)
                drawReceipt(receipt, in: cell, captionHeight: captionHeight)
            }
        }
    }

    // MARK: - Page chrome

    /// Paints the cream background, the wordmark + event header, and the tagline +
    /// page-number footer. Returns the y where content may start.
    private static func drawPageChrome(eventName: String, pageNumber: Int, pageSize: CGRect,
                                       leftMargin: CGFloat, contentWidth: CGFloat, contentTop: CGFloat) -> CGFloat {
        Theme.cream.setFill()
        UIRectFill(pageSize)

        // Header: wordmark left, "Event · Optimization Details" right, hairline under both.
        let logoHeight: CGFloat = 16
        let headerY: CGFloat = 30
        if let logo = UIImage(named: "tabiLogoHorizontal") {
            let logoWidth = logoHeight * (logo.size.width / max(logo.size.height, 1))
            logo.draw(in: CGRect(x: leftMargin, y: headerY, width: logoWidth, height: logoHeight))
        } else {
            // Asset missing (e.g. in a stripped test bundle): fall back to the name.
            ("Tabi" as NSString).draw(at: CGPoint(x: leftMargin, y: headerY - 2),
                                      withAttributes: Theme.attributes(.bold, 15, Theme.ink, kern: -0.3))
        }
        let headerAttributes = Theme.attributes(.medium, 10, Theme.muted)
        let headerText = ("\(eventName)  ·  Optimization Details" as NSString)
            .truncated(toWidth: contentWidth - 140, using: headerAttributes)
        let headerSize = headerText.size(withAttributes: headerAttributes)
        headerText.draw(at: CGPoint(x: pageSize.width - leftMargin - headerSize.width, y: headerY + (logoHeight - headerSize.height) / 2),
                        withAttributes: headerAttributes)
        Theme.line.setFill()
        UIRectFill(CGRect(x: leftMargin, y: headerY + logoHeight + 10, width: contentWidth, height: 1))

        // Footer: hairline, tagline left, page number right.
        let footerLineY = pageSize.height - 46
        UIRectFill(CGRect(x: leftMargin, y: footerLineY, width: contentWidth, height: 1))
        let footerAttributes = Theme.attributes(.regular, 9, Theme.muted)
        (Theme.tagline as NSString).draw(at: CGPoint(x: leftMargin, y: footerLineY + 8), withAttributes: footerAttributes)
        let pageText = "Page \(pageNumber)" as NSString
        let pageTextSize = pageText.size(withAttributes: footerAttributes)
        pageText.draw(at: CGPoint(x: pageSize.width - leftMargin - pageTextSize.width, y: footerLineY + 8), withAttributes: footerAttributes)

        return contentTop
    }

    /// First-page title: event name, generated-by stamp, and the brand's
    /// tri-colour "Scan. Split. Settle." line from the website hero.
    private static func drawTitleBlock(eventName: String, generatedBy: String, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let titleAttributes = Theme.attributes(.bold, 24, Theme.ink, kern: -0.5)
        let title = (eventName as NSString).truncated(toWidth: contentWidth, using: titleAttributes)
        title.draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: titleAttributes)
        var bottom = maxY + title.size(withAttributes: titleAttributes).height + 4

        let now = Date()
        let stampAttributes = Theme.attributes(.regular, 11, Theme.muted)
        ("Generated by \(generatedBy)  ·  \(now.customDateFormat("dd MMM yyyy HH:mm").string(from: now))" as NSString)
            .draw(at: CGPoint(x: leftMargin, y: bottom), withAttributes: stampAttributes)
        bottom += ("G" as NSString).size(withAttributes: stampAttributes).height + 8

        // "Scan." blue, "Split." green, "Settle." pink — same colouring as the web hero.
        var x = leftMargin
        for (word, color) in [("Scan.", Theme.blue), ("Split.", Theme.green), ("Settle.", Theme.pink)] {
            let attributes = Theme.attributes(.bold, 10, color, kern: 0.4)
            (word as NSString).draw(at: CGPoint(x: x, y: bottom), withAttributes: attributes)
            x += (word as NSString).size(withAttributes: attributes).width + 6
        }
        return bottom + 14
    }

    // MARK: - Drawing helpers

    private static func drawSectionTitle(_ text: String, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let attributes = Theme.attributes(.bold, 16, Theme.ink, kern: -0.3)
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: leftMargin, y: maxY, width: contentWidth, height: size.height + 8)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        Theme.line.setFill()
        UIRectFill(CGRect(x: leftMargin, y: maxY + size.height + 2, width: contentWidth, height: 1))
        return maxY + size.height + 14
    }

    /// A lighter heading for a subsection within a section (e.g. the "Simplified"
    /// and "Detailed" recap groups), with an optional one-line explanation.
    private static func drawSubsectionTitle(_ text: String, subtitle: String?, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let titleAttributes = Theme.attributes(.bold, 13, Theme.ink)
        let titleSize = (text as NSString).size(withAttributes: titleAttributes)
        (text as NSString).draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: titleAttributes)
        var bottom = maxY + titleSize.height + 2

        if let subtitle {
            let subtitleAttributes = Theme.attributes(.regular, 10, Theme.muted)
            (subtitle as NSString).draw(at: CGPoint(x: leftMargin, y: bottom), withAttributes: subtitleAttributes)
            bottom += (subtitle as NSString).size(withAttributes: subtitleAttributes).height + 2
        }
        return bottom + 2
    }

    /// Mirrors `OptimizationPersonCard`: name, lent/debt, and the balance status.
    /// Styled like the website's cards: cream fill, hairline ring, rounded corners.
    private static func drawPersonCard(_ person: OptimizationPersonPDFData, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 80
        let box = CGRect(x: leftMargin, y: maxY, width: contentWidth, height: cardHeight)
        let path = UIBezierPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerRadius: Theme.cardRadius)
        UIColor.white.setFill()
        path.fill()
        Theme.line.setStroke()
        path.stroke()

        let nameAttributes = Theme.attributes(.semibold, 15, Theme.ink)
        let labelAttributes = Theme.attributes(.regular, 11, Theme.muted)
        let lentAttributes = Theme.attributes(.medium, 13, Theme.green)
        let debtAttributes = Theme.attributes(.medium, 13, Theme.red)
        let statusAttributes = Theme.attributes(.bold, 13, person.balance < 0 ? Theme.red : Theme.green)

        let name = person.isCurrentUser ? "\(person.name) (You)" : person.name
        (name as NSString).draw(at: CGPoint(x: box.minX + 16, y: box.minY + 10), withAttributes: nameAttributes)

        // Lent / debt columns.
        let colWidth = (box.width - 32) / 2
        ("Total Lent" as NSString).draw(at: CGPoint(x: box.minX + 16, y: box.minY + 34), withAttributes: labelAttributes)
        (formatMoney(person.lent) as NSString).draw(at: CGPoint(x: box.minX + 16, y: box.minY + 48), withAttributes: lentAttributes)
        ("Total Debt" as NSString).draw(at: CGPoint(x: box.minX + 16 + colWidth, y: box.minY + 34), withAttributes: labelAttributes)
        (formatMoney(person.debt) as NSString).draw(at: CGPoint(x: box.minX + 16 + colWidth, y: box.minY + 48), withAttributes: debtAttributes)

        // Status + net balance, right-aligned.
        let statusLine = "\(person.statusText) \(formatMoney(person.balance, showSign: true))" as NSString
        let statusSize = statusLine.size(withAttributes: statusAttributes)
        statusLine.draw(at: CGPoint(x: box.maxX - 16 - statusSize.width, y: box.minY + 10), withAttributes: statusAttributes)

        return box.maxY
    }

    private static func drawRecapHeader(maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let attributes = Theme.attributes(.semibold, 11, Theme.muted)
        ("Payment" as NSString).draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: attributes)
        ("Amount" as NSString).draw(at: CGPoint(x: pageWidth - leftMargin - 80, y: maxY), withAttributes: attributes)
        Theme.line.setFill()
        UIRectFill(CGRect(x: leftMargin, y: maxY + 18, width: contentWidth, height: 1))
        return maxY + 24
    }

    private static func drawRecapRow(_ entry: OptimizationRecapPDFData, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let paymentAttributes = Theme.attributes(.medium, 13, Theme.inkSoft)
        let amountAttributes = Theme.attributes(.semibold, 13, Theme.ink)

        let maxNameWidth = (pageWidth - leftMargin - 90) - leftMargin
        let payment = ("\(entry.fromName)  →  \(entry.toName)" as NSString)
            .truncated(toWidth: maxNameWidth, using: paymentAttributes)
        payment.draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: paymentAttributes)

        let amount = formatMoney(entry.amount) as NSString
        let amountSize = amount.size(withAttributes: amountAttributes)
        amount.draw(at: CGPoint(x: pageWidth - leftMargin - max(amountSize.width, 80), y: maxY), withAttributes: amountAttributes)

        return maxY + max(payment.size(withAttributes: paymentAttributes).height, 18) + 6
    }

    /// The expense-level header: receipt name, who paid, and the total — the item
    /// rows drawn by `drawExpenseItemRow` sit indented beneath it.
    private static func drawExpenseGroupHeader(_ expense: OptimizationExpensePDFData, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let nameAttributes = Theme.attributes(.bold, 14, Theme.ink)
        let payerAttributes = Theme.attributes(.regular, 11, Theme.muted)
        let amountAttributes = Theme.attributes(.bold, 14, Theme.ink)

        let drawName = (expense.name as NSString).truncated(toWidth: 300, using: nameAttributes)
        drawName.draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: nameAttributes)

        let amount = formatMoney(expense.amount) as NSString
        let amountSize = amount.size(withAttributes: amountAttributes)
        amount.draw(at: CGPoint(x: pageWidth - leftMargin - max(amountSize.width, 80), y: maxY), withAttributes: amountAttributes)

        let payerY = maxY + drawName.size(withAttributes: nameAttributes).height + 1
        var splitLabel = expense.isEquallySplit ? "Split equally" : "Split custom"
        if expense.isEquallySplit, let perPerson = expense.equalSplitPerPerson {
            splitLabel += " (\(formatMoney(perPerson))/person)"
        }
        let dateText = expense.date.customDateFormat("dd MMM yyyy").string(from: expense.date)
        ("\(dateText)  •  Paid by \(expense.payerName)  •  \(splitLabel)" as NSString)
            .draw(at: CGPoint(x: leftMargin, y: payerY), withAttributes: payerAttributes)

        let bottom = payerY + ("Paid by" as NSString).size(withAttributes: payerAttributes).height + 6
        Theme.line.setFill()
        UIRectFill(CGRect(x: leftMargin, y: bottom, width: contentWidth, height: 1))
        return bottom + 6
    }

    /// One indented line item beneath an expense header. Pass nil quantity/price
    /// for placeholder text (e.g. "No itemised breakdown.").
    private static func drawExpenseItemRow(name: String, quantity: Float?, price: Float?, maxY: CGFloat, leftMargin: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let indent = leftMargin + 16
        let nameAttributes = Theme.attributes(.regular, 12, Theme.inkSoft)
        let priceAttributes = Theme.attributes(.medium, 12, Theme.ink)

        var label = name
        if let quantity, quantity > 0 {
            // Show whole quantities without a trailing ".0".
            let qtyText = quantity.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(quantity)) : String(quantity)
            label = "\(name)  ×\(qtyText)"
        }
        let drawName = (label as NSString).truncated(toWidth: 360, using: nameAttributes)
        drawName.draw(at: CGPoint(x: indent, y: maxY), withAttributes: nameAttributes)

        if let price {
            let priceText = formatMoney(price) as NSString
            let priceSize = priceText.size(withAttributes: priceAttributes)
            priceText.draw(at: CGPoint(x: pageWidth - leftMargin - max(priceSize.width, 70), y: maxY), withAttributes: priceAttributes)
        }

        return maxY + max(drawName.size(withAttributes: nameAttributes).height, 16) + 5
    }

    /// The list of people sharing an item, indented under the item row.
    private static func drawAssigneesRow(_ assignees: [OptimizationAssigneePDFData], maxY: CGFloat, leftMargin: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let indent = leftMargin + 32
        let attributes = Theme.attributes(.regular, 11, Theme.muted)
        let parts = assignees.map { assignee -> String in
            guard assignee.share > 0 else { return assignee.name }
            // Share is a multiplier/portion, not a price — show whole values without ".0".
            let shareText = assignee.share.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(assignee.share))
                : String(assignee.share)
            return "\(assignee.name) (\(shareText)x)"
        }
        let text = ("Shared by: " + parts.joined(separator: ", ") as NSString)
            .truncated(toWidth: pageWidth - leftMargin - indent, using: attributes)
        text.draw(at: CGPoint(x: indent, y: maxY), withAttributes: attributes)
        return maxY + text.size(withAttributes: attributes).height + 5
    }

    /// The participants sharing an equally-split expense, indented under its header.
    private static func drawParticipantsRow(_ names: [String], maxY: CGFloat, leftMargin: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let indent = leftMargin + 16
        let attributes = Theme.attributes(.regular, 11, Theme.muted)
        let text = ("Split between: " + names.joined(separator: ", ") as NSString)
            .truncated(toWidth: pageWidth - leftMargin - indent, using: attributes)
        text.draw(at: CGPoint(x: indent, y: maxY), withAttributes: attributes)
        return maxY + text.size(withAttributes: attributes).height + 5
    }

    private static func drawInfoRow(label: String, value: String, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let labelAttributes = Theme.attributes(.regular, 14, Theme.inkSoft)
        let valueAttributes = Theme.attributes(.medium, 14, Theme.ink)
        let labelSize = (label as NSString).size(withAttributes: labelAttributes)
        (label as NSString).draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: labelAttributes)
        let valueSize = (value as NSString).size(withAttributes: valueAttributes)
        (value as NSString).draw(at: CGPoint(x: pageWidth - leftMargin - valueSize.width, y: maxY), withAttributes: valueAttributes)
        return maxY + max(labelSize.height, valueSize.height) + 6
    }

    /// One grid cell: the caption (expense · date · total) on top, the receipt image
    /// aspect-fit in the space below and centred horizontally, clipped to the same
    /// rounded-corner + hairline card as the balances.
    private static func drawReceipt(_ receipt: OptimizationReceiptPDFData, in cell: CGRect, captionHeight: CGFloat) {
        let captionAttributes = Theme.attributes(.semibold, 11, Theme.inkSoft)
        let dateText = receipt.date.customDateFormat("dd MMM yyyy").string(from: receipt.date)
        let caption = ("\(receipt.expenseName)  ·  \(dateText)  ·  \(formatMoney(receipt.amount))" as NSString)
            .truncated(toWidth: cell.width, using: captionAttributes)
        caption.draw(at: CGPoint(x: cell.minX, y: cell.minY), withAttributes: captionAttributes)

        // Fit the image into the box under the caption without cropping or distorting.
        let box = CGRect(x: cell.minX, y: cell.minY + captionHeight,
                         width: cell.width, height: cell.height - captionHeight)
        let imageSize = receipt.image.size
        let scale = min(box.width / max(imageSize.width, 1), box.height / max(imageSize.height, 1))
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let frame = CGRect(x: box.midX - drawSize.width / 2, y: box.minY,
                           width: drawSize.width, height: drawSize.height)

        let path = UIBezierPath(roundedRect: frame, cornerRadius: Theme.cardRadius)
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        cg.saveGState()
        path.addClip()
        receipt.image.draw(in: frame)
        cg.restoreGState()
        Theme.line.setStroke()
        path.stroke()
    }
}

private extension NSString {
    /// Returns a copy of the receiver truncated (with an ellipsis) if it is wider than `maxWidth`.
    func truncated(toWidth maxWidth: CGFloat, using attributes: [NSAttributedString.Key: Any]) -> NSString {
        if size(withAttributes: attributes).width <= maxWidth { return self }
        var length = self.length
        while length > 0 {
            length -= 1
            let candidate = substring(to: length) + "…"
            if (candidate as NSString).size(withAttributes: attributes).width <= maxWidth {
                return candidate as NSString
            }
        }
        return "…" as NSString
    }
}
