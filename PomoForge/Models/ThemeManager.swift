// ThemeManager.swift
// Centralized theme colors that actually affect the UI

import SwiftUI

struct AppThemeColors {
    let accent: Color
    let focusGradient: Color
    let breakGradient: Color
    let longBreakGradient: Color
    let background: Color

    static func forTheme(_ theme: String) -> AppThemeColors {
        switch theme {
        case "midnight":
            return AppThemeColors(
                accent: .indigo,
                focusGradient: Color.indigo.opacity(0.12),
                breakGradient: Color.purple.opacity(0.08),
                longBreakGradient: Color.blue.opacity(0.08),
                background: Color(red: 0.05, green: 0.02, blue: 0.15)
            )
        case "forest":
            return AppThemeColors(
                accent: .green,
                focusGradient: Color.green.opacity(0.10),
                breakGradient: Color.mint.opacity(0.08),
                longBreakGradient: Color.teal.opacity(0.08),
                background: Color(red: 0.02, green: 0.08, blue: 0.04)
            )
        case "ocean":
            return AppThemeColors(
                accent: .cyan,
                focusGradient: Color.cyan.opacity(0.10),
                breakGradient: Color.teal.opacity(0.08),
                longBreakGradient: Color.blue.opacity(0.08),
                background: Color(red: 0.02, green: 0.05, blue: 0.12)
            )
        default: // "dark"
            return AppThemeColors(
                accent: .orange,
                focusGradient: Color.orange.opacity(0.08),
                breakGradient: Color.green.opacity(0.08),
                longBreakGradient: Color.blue.opacity(0.08),
                background: .black
            )
        }
    }

    func gradientForInterval(_ type: IntervalType) -> Color {
        switch type {
        case .work: return focusGradient
        case .shortBreak: return breakGradient
        case .longBreak: return longBreakGradient
        }
    }
}

// Environment key for theme
struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppThemeColors.forTheme("dark")
}

extension EnvironmentValues {
    var theme: AppThemeColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
