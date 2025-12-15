import Foundation

enum PregnancyWeekCalculator {
    /// Returns current pregnancy week for a given EDD (Estimated Due Date).
    /// Assumes a 40-week pregnancy (280 days) by default.
    static func week(edd: Date, now: Date = Date(), totalWeeks: Int = 40) -> Int {
        // Start of pregnancy is EDD - totalWeeks
        guard let start = Calendar.current.date(byAdding: .day, value: -(totalWeeks * 7), to: edd) else {
            return 1
        }
        let days = Calendar.current.dateComponents([.day], from: start, to: now).day ?? 0
        let computed = (days / 7) + 1
        return max(1, min(42, computed))
    }
}

