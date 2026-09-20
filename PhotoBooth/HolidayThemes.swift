//
//  HolidayThemes.swift
//  PhotoBooth
//
//  Philippine holiday theming: a catalog of themes, the date logic that
//  auto-detects which one applies today, and a manager that lets the
//  user override the auto pick manually (persisted between launches).
//

import Combine
import Foundation
import SwiftUI

// MARK: - Theme definition

struct HolidayTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let paper: Color
    let ink: Color
    let accent: Color
    let secondaryAccent: Color
    let stripCaption: String

    static func == (lhs: HolidayTheme, rhs: HolidayTheme) -> Bool { lhs.id == rhs.id }
}

extension HolidayTheme {
    static let everyday = HolidayTheme(
        id: "everyday", name: "Everyday", emoji: "📸",
        paper: Color(red: 0.96, green: 0.93, blue: 0.87),
        ink: Color(red: 0.09, green: 0.09, blue: 0.08),
        accent: Color(red: 0.92, green: 0.36, blue: 0.29),
        secondaryAccent: Color(red: 0.20, green: 0.35, blue: 0.58),
        stripCaption: "PhotoBooth"
    )

    static let newYearsDay = HolidayTheme(
        id: "new-years-day", name: "New Year's Day", emoji: "🎆",
        paper: Color(red: 0.06, green: 0.07, blue: 0.10),
        ink: Color(red: 0.97, green: 0.95, blue: 0.85),
        accent: Color(red: 0.85, green: 0.68, blue: 0.20),
        secondaryAccent: Color(red: 0.97, green: 0.95, blue: 0.85),
        stripCaption: "Manigong Bagong Taon!"
    )

    static let newYearsEve = HolidayTheme(
        id: "new-years-eve", name: "New Year's Eve", emoji: "🎇",
        paper: Color(red: 0.06, green: 0.07, blue: 0.10),
        ink: Color(red: 0.97, green: 0.95, blue: 0.85),
        accent: Color(red: 0.85, green: 0.68, blue: 0.20),
        secondaryAccent: Color(red: 0.55, green: 0.14, blue: 0.14),
        stripCaption: "Media Noche"
    )

    static let holyWeek = HolidayTheme(
        id: "holy-week", name: "Holy Week", emoji: "🙏",
        paper: Color(red: 0.93, green: 0.91, blue: 0.92),
        ink: Color(red: 0.24, green: 0.14, blue: 0.28),
        accent: Color(red: 0.40, green: 0.20, blue: 0.42),
        secondaryAccent: Color(red: 0.28, green: 0.25, blue: 0.27),
        stripCaption: "Semana Santa"
    )

    static let arawNgKagitingan = HolidayTheme(
        id: "araw-ng-kagitingan", name: "Araw ng Kagitingan", emoji: "🎖️",
        paper: Color(red: 0.95, green: 0.95, blue: 0.96),
        ink: Color(red: 0.0, green: 0.11, blue: 0.32),
        accent: Color(red: 0.55, green: 0.08, blue: 0.13),
        secondaryAccent: Color(red: 0.72, green: 0.60, blue: 0.30),
        stripCaption: "Araw ng Kagitingan"
    )

    static let laborDay = HolidayTheme(
        id: "labor-day", name: "Labor Day", emoji: "🛠️",
        paper: Color(red: 0.96, green: 0.93, blue: 0.87),
        ink: Color(red: 0.12, green: 0.10, blue: 0.09),
        accent: Color(red: 0.80, green: 0.16, blue: 0.16),
        secondaryAccent: Color(red: 0.85, green: 0.68, blue: 0.20),
        stripCaption: "Araw ng Manggagawa"
    )

    static let independenceDay = HolidayTheme(
        id: "independence-day", name: "Independence Day", emoji: "🇵🇭",
        paper: Color(red: 0.97, green: 0.97, blue: 0.98),
        ink: Color(red: 0.0, green: 0.16, blue: 0.44),
        accent: Color(red: 0.81, green: 0.07, blue: 0.15),
        secondaryAccent: Color(red: 0.90, green: 0.75, blue: 0.10),
        stripCaption: "Araw ng Kalayaan"
    )

    static let nationalHeroesDay = HolidayTheme(
        id: "national-heroes-day", name: "National Heroes Day", emoji: "🎗️",
        paper: Color(red: 0.97, green: 0.97, blue: 0.98),
        ink: Color(red: 0.0, green: 0.16, blue: 0.44),
        accent: Color(red: 0.81, green: 0.07, blue: 0.15),
        secondaryAccent: Color(red: 0.90, green: 0.75, blue: 0.10),
        stripCaption: "Araw ng mga Bayani"
    )

    static let undas = HolidayTheme(
        id: "undas", name: "Undas", emoji: "🕯️",
        paper: Color(red: 0.94, green: 0.90, blue: 0.82),
        ink: Color(red: 0.16, green: 0.10, blue: 0.07),
        accent: Color(red: 0.75, green: 0.45, blue: 0.13),
        secondaryAccent: Color(red: 0.35, green: 0.10, blue: 0.10),
        stripCaption: "Undas"
    )

    static let bonifacioDay = HolidayTheme(
        id: "bonifacio-day", name: "Bonifacio Day", emoji: "⚔️",
        paper: Color(red: 0.97, green: 0.97, blue: 0.98),
        ink: Color(red: 0.0, green: 0.16, blue: 0.44),
        accent: Color(red: 0.81, green: 0.07, blue: 0.15),
        secondaryAccent: Color(red: 0.90, green: 0.75, blue: 0.10),
        stripCaption: "Bonifacio Day"
    )

    static let christmasSeason = HolidayTheme(
        id: "christmas-season", name: "Christmas Season", emoji: "🎄",
        paper: Color(red: 0.97, green: 0.95, blue: 0.90),
        ink: Color(red: 0.08, green: 0.20, blue: 0.13),
        accent: Color(red: 0.75, green: 0.11, blue: 0.13),
        secondaryAccent: Color(red: 0.80, green: 0.63, blue: 0.18),
        stripCaption: "Maligayang Pasko"
    )

    static let christmasEve = HolidayTheme(
        id: "christmas-eve", name: "Christmas Eve", emoji: "🌟",
        paper: Color(red: 0.10, green: 0.06, blue: 0.08),
        ink: Color(red: 0.97, green: 0.95, blue: 0.90),
        accent: Color(red: 0.85, green: 0.68, blue: 0.20),
        secondaryAccent: Color(red: 0.75, green: 0.11, blue: 0.13),
        stripCaption: "Noche Buena"
    )

    static let christmasDay = HolidayTheme(
        id: "christmas-day", name: "Christmas Day", emoji: "🎅",
        paper: Color(red: 0.97, green: 0.95, blue: 0.90),
        ink: Color(red: 0.08, green: 0.20, blue: 0.13),
        accent: Color(red: 0.75, green: 0.11, blue: 0.13),
        secondaryAccent: Color(red: 0.80, green: 0.63, blue: 0.18),
        stripCaption: "Maligayang Pasko!"
    )

    static let rizalDay = HolidayTheme(
        id: "rizal-day", name: "Rizal Day", emoji: "🕊️",
        paper: Color(red: 0.97, green: 0.97, blue: 0.98),
        ink: Color(red: 0.0, green: 0.16, blue: 0.44),
        accent: Color(red: 0.60, green: 0.08, blue: 0.14),
        secondaryAccent: Color(red: 0.72, green: 0.60, blue: 0.30),
        stripCaption: "Rizal Day"
    )

    static let chineseNewYear = HolidayTheme(
        id: "chinese-new-year", name: "Chinese New Year", emoji: "🧧",
        paper: Color(red: 0.96, green: 0.90, blue: 0.85),
        ink: Color(red: 0.35, green: 0.04, blue: 0.04),
        accent: Color(red: 0.80, green: 0.05, blue: 0.05),
        secondaryAccent: Color(red: 0.85, green: 0.68, blue: 0.20),
        stripCaption: "Kung Hei Fat Choi"
    )

    static let eidAlFitr = HolidayTheme(
        id: "eid-al-fitr", name: "Eid al-Fitr", emoji: "🌙",
        paper: Color(red: 0.94, green: 0.96, blue: 0.94),
        ink: Color(red: 0.05, green: 0.25, blue: 0.20),
        accent: Color(red: 0.05, green: 0.40, blue: 0.35),
        secondaryAccent: Color(red: 0.80, green: 0.63, blue: 0.18),
        stripCaption: "Eid Mubarak"
    )

    static let eidAlAdha = HolidayTheme(
        id: "eid-al-adha", name: "Eid al-Adha", emoji: "🌙",
        paper: Color(red: 0.94, green: 0.96, blue: 0.94),
        ink: Color(red: 0.05, green: 0.25, blue: 0.20),
        accent: Color(red: 0.05, green: 0.40, blue: 0.35),
        secondaryAccent: Color(red: 0.80, green: 0.63, blue: 0.18),
        stripCaption: "Eid Mubarak"
    )

    static let all: [HolidayTheme] = [
        .everyday, .christmasSeason, .christmasEve, .christmasDay,
        .newYearsEve, .newYearsDay, .holyWeek, .arawNgKagitingan,
        .laborDay, .independenceDay, .nationalHeroesDay, .undas,
        .bonifacioDay, .rizalDay, .chineseNewYear, .eidAlFitr, .eidAlAdha
    ]
}

// MARK: - Date detection

enum HolidayCalendar {

    // Movable holidays, computed fresh every year — no lookup table needed.

    static func easterSunday(year: Int) -> DateComponents {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return DateComponents(year: year, month: month, day: day)
    }

    static func lastMondayOfAugust(year: Int) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Manila") ?? .current
        let aug31 = calendar.date(from: DateComponents(year: year, month: 8, day: 31)) ?? Date()
        let weekday = calendar.component(.weekday, from: aug31) // Sunday = 1 ... Saturday = 7
        let daysBack = (weekday - 2 + 7) % 7 // steps back to Monday (2)
        let lastMonday = calendar.date(byAdding: .day, value: -daysBack, to: aug31) ?? aug31
        return calendar.dateComponents([.year, .month, .day], from: lastMonday)
    }

    // Lunar holidays are set by lunar/moon-sighting calendars and can't be
    // computed with a formula. Confirmed for 2026-2027 from the Palace
    // proclamation and public holiday calendars — add future years here
    // once they're officially announced.

    static let chineseNewYear: [Int: (month: Int, day: Int)] = [
        2025: (1, 29),
        2026: (2, 17),
        2027: (2, 6)
    ]

    static let eidAlFitr: [Int: (month: Int, day: Int)] = [
        2026: (3, 20),
        2027: (3, 10)
    ]

    static let eidAlAdha: [Int: (month: Int, day: Int)] = [
        2026: (5, 27),
        2027: (5, 17)
    ]

    private static func dayKey(_ month: Int, _ day: Int) -> Int { month * 100 + day }

    private static func dayAfter(_ month: Int, _ day: Int, year: Int) -> (Int, Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Manila") ?? .current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              let next = calendar.date(byAdding: .day, value: 1, to: date) else {
            return (month, day)
        }
        let comps = calendar.dateComponents([.month, .day], from: next)
        return (comps.month ?? month, comps.day ?? day)
    }

    /// Resolves which holiday theme applies to a given date, in priority order:
    /// rare lunar days first, then specific single/short-range days, then the
    /// broad Christmas season as a catch-all, then the everyday default.
    static func activeTheme(for date: Date = Date()) -> HolidayTheme {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Manila") ?? .current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            return .everyday
        }

        let todayKey = dayKey(month, day)
        func matches(_ m: Int, _ d: Int) -> Bool { todayKey == dayKey(m, d) }
        func within(from: (Int, Int), to: (Int, Int)) -> Bool {
            todayKey >= dayKey(from.0, from.1) && todayKey <= dayKey(to.0, to.1)
        }

        if let d = chineseNewYear[year], matches(d.month, d.day) { return .chineseNewYear }

        if let d = eidAlFitr[year] {
            let end = dayAfter(d.month, d.day, year: year)
            if within(from: (d.month, d.day), to: end) { return .eidAlFitr }
        }

        if let d = eidAlAdha[year] {
            let end = dayAfter(d.month, d.day, year: year)
            if within(from: (d.month, d.day), to: end) { return .eidAlAdha }
        }

        if matches(1, 1) { return .newYearsDay }

        let easter = easterSunday(year: year)
        if let easterMonth = easter.month, let easterDay = easter.day,
           let easterDate = calendar.date(from: DateComponents(year: year, month: easterMonth, day: easterDay)),
           let palmSunday = calendar.date(byAdding: .day, value: -7, to: easterDate),
           let blackSaturday = calendar.date(byAdding: .day, value: -1, to: easterDate) {
            let palmComps = calendar.dateComponents([.month, .day], from: palmSunday)
            let blackComps = calendar.dateComponents([.month, .day], from: blackSaturday)
            if let pm = palmComps.month, let pd = palmComps.day,
               let bm = blackComps.month, let bd = blackComps.day,
               within(from: (pm, pd), to: (bm, bd)) {
                return .holyWeek
            }
        }

        if matches(4, 9) { return .arawNgKagitingan }
        if matches(5, 1) { return .laborDay }
        if matches(6, 12) { return .independenceDay }

        let heroesDay = lastMondayOfAugust(year: year)
        if let hm = heroesDay.month, let hd = heroesDay.day, matches(hm, hd) { return .nationalHeroesDay }

        if within(from: (11, 1), to: (11, 2)) { return .undas }
        if matches(11, 30) { return .bonifacioDay }
        if matches(12, 24) { return .christmasEve }
        if within(from: (12, 25), to: (12, 29)) { return .christmasDay }
        if matches(12, 30) { return .rizalDay }
        if matches(12, 31) { return .newYearsEve }
        if within(from: (9, 1), to: (12, 23)) { return .christmasSeason }

        return .everyday
    }
}

// MARK: - Theme manager

final class ThemeManager: ObservableObject {
    enum Mode: Equatable {
        case auto
        case manual(String)
    }

    @Published private(set) var mode: Mode
    @Published private(set) var current: HolidayTheme

    private let defaultsKey = "PhotoBooth.themeMode"

    init() {
        if let saved = UserDefaults.standard.string(forKey: defaultsKey),
           saved != "auto",
           let theme = HolidayTheme.all.first(where: { $0.id == saved }) {
            mode = .manual(theme.id)
            current = theme
        } else {
            mode = .auto
            current = HolidayCalendar.activeTheme()
        }
    }

    var autoDetectedTheme: HolidayTheme {
        HolidayCalendar.activeTheme()
    }

    func setAuto() {
        mode = .auto
        current = HolidayCalendar.activeTheme()
        UserDefaults.standard.set("auto", forKey: defaultsKey)
    }

    func setManual(_ theme: HolidayTheme) {
        mode = .manual(theme.id)
        current = theme
        UserDefaults.standard.set(theme.id, forKey: defaultsKey)
    }

    /// Call when the app becomes active, in case the date rolled over while in auto mode.
    func refreshIfNeeded() {
        if case .auto = mode {
            current = HolidayCalendar.activeTheme()
        }
    }
}
