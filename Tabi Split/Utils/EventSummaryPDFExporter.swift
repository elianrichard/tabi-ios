//
//  EventSummaryPDFExporter.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/08/26.
//

import UIKit

/// Immutable snapshot of everything needed to render an event's summary as a PDF.
/// Extracted from `EventViewModel` so the exporter stays a pure, testable function.
struct EventSummaryPDFData {
    var eventName: String
    var userName: String
    var statusText: String
    var balance: Float
    var totalSpending: Float
    var transactions: [SummaryHistoryData]
}

/// Builds a paginated, shareable PDF of an event's summary page.
enum EventSummaryPDFExporter {

    // MARK: - Public API

    static func generatePDF(from data: EventSummaryPDFData) -> Data {
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 portrait
        let leftMargin: CGFloat = 40
        let rightMargin: CGFloat = 40
        let contentWidth = pageSize.width - leftMargin - rightMargin
        let pageBottom: CGFloat = pageSize.height - 55

        // Start the first page.
        var pageY: CGFloat = 40

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

        return renderer.pdfData { context in
            context.beginPage()

            // ---- Header ----
            pageY = drawCenteredTitle("\(data.eventName) — Summary", maxY: pageY, contentWidth: contentWidth, pageWidth: pageSize.width)
            pageY = drawCenteredSubtitle(
                "Generated on \(Date().customDateFormat("dd MMM yyyy HH:mm").string(from: Date()))",
                maxY: pageY, contentWidth: contentWidth, pageWidth: pageSize.width
            )
            pageY += 20

            // ---- Balance card ----
            pageY = drawSectionTitle("Your Balance", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY = drawBalanceCard(statusText: data.statusText, balance: data.balance, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 16

            // ---- Total spending ----
            pageY = drawInfoRow(label: "Your total spending", value: data.totalSpending.formatPrice(), maxY: pageY,
                                leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            pageY += 24

            // ---- Transaction history ----
            pageY = drawSectionTitle("Your Transaction History", maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth)
            pageY += 6
            pageY = drawTransactionHeader(maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            pageY += 4

            if data.transactions.isEmpty {
                pageY = drawInfoRow(label: "No transactions yet.", value: "", maxY: pageY,
                                    leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            }

            for transaction in data.transactions {
                if pageY > pageBottom {
                    context.beginPage()
                    pageY = drawSectionTitle("Your Transaction History (cont.)", maxY: 40.0,
                                             leftMargin: leftMargin, contentWidth: contentWidth)
                    pageY += 6
                    pageY = drawTransactionHeader(maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
                    pageY += 4
                }
                pageY = drawTransactionRow(transaction, maxY: pageY, leftMargin: leftMargin, contentWidth: contentWidth, pageWidth: pageSize.width)
            }
        }
    }

    // MARK: - Drawing helpers

    private static func drawCenteredTitle(_ text: String, maxY: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.black,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: (pageWidth - size.width) / 2, y: maxY, width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        return maxY + size.height + 8
    }

    private static func drawCenteredSubtitle(_ text: String, maxY: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.gray,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: (pageWidth - size.width) / 2, y: maxY, width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        return maxY + size.height
    }

    private static func drawSectionTitle(_ text: String, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: leftMargin, y: maxY, width: contentWidth, height: size.height + 8)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        UIColor.separator.setFill()
        UIRectFill(CGRect(x: leftMargin, y: maxY + size.height + 2, width: contentWidth, height: 1))
        return maxY + size.height + 14
    }

    private static func drawBalanceCard(statusText: String, balance: Float, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let box = CGRect(x: leftMargin, y: maxY, width: contentWidth, height: 70)
        UIColor.systemGroupedBackground.setFill()
        UIRectFill(box)
        UIColor.separator.setStroke()
        UIBezierPath(rect: box).stroke()

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.darkGray,
        ]
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: balance >= 0 ? UIColor.systemGreen : UIColor.systemRed,
        ]

        (statusText as NSString).draw(in: CGRect(x: box.minX + 16, y: box.minY + 12, width: box.width - 32, height: 20),
                                      withAttributes: labelAttributes)
        (balance.formatPrice(isShowSign: true) as NSString).draw(
            in: CGRect(x: box.minX + 16, y: box.minY + 30, width: box.width - 32, height: 32),
            withAttributes: amountAttributes
        )
        return box.maxY
    }

    private static func drawInfoRow(label: String, value: String, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.darkGray,
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.black,
        ]
        let labelSize = (label as NSString).size(withAttributes: labelAttributes)
        (label as NSString).draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: labelAttributes)
        let valueSize = (value as NSString).size(withAttributes: valueAttributes)
        (value as NSString).draw(at: CGPoint(x: pageWidth - leftMargin - valueSize.width, y: maxY), withAttributes: valueAttributes)
        return maxY + max(labelSize.height, valueSize.height)
    }

    private static func drawTransactionHeader(maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        _ = contentWidth
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.gray,
        ]
        ("Expense" as NSString).draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: attributes)
        ("Date" as NSString).draw(at: CGPoint(x: leftMargin + 230, y: maxY), withAttributes: attributes)
        ("Amount" as NSString).draw(at: CGPoint(x: pageWidth - leftMargin - 60, y: maxY), withAttributes: attributes)
        UIColor.separator.setFill()
        UIRectFill(CGRect(x: leftMargin, y: maxY + 18, width: contentWidth, height: 1))
        return maxY + 24
    }

    private static func drawTransactionRow(_ transaction: SummaryHistoryData, maxY: CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageWidth: CGFloat) -> CGFloat {
        _ = contentWidth
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.black,
        ]
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.gray,
        ]
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: transaction.amount >= 0 ? UIColor.systemGreen : UIColor.systemRed,
        ]

        let maxNameWidth = leftMargin + 225 - leftMargin
        let drawName = (transaction.expenseName as NSString).truncated(toWidth: maxNameWidth, using: nameAttributes)

        drawName.draw(at: CGPoint(x: leftMargin, y: maxY), withAttributes: nameAttributes)

        (transaction.expenseDate.toProperText() as NSString).draw(
            at: CGPoint(x: leftMargin + 230, y: maxY), withAttributes: dateAttributes)

        let signedAmount = transaction.amount.formatPrice(isShowSign: true) as NSString
        let amountSize = signedAmount.size(withAttributes: amountAttributes)
        signedAmount.draw(at: CGPoint(x: pageWidth - leftMargin - max(amountSize.width, 60), y: maxY),
                          withAttributes: amountAttributes)

        return maxY + max(drawName.size(withAttributes: nameAttributes).height, 18) + 6
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