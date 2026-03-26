//
//  LiquidGlassStyle.swift
//  SprintStart
//
//  Created by Assistant on 3/7/26.
//

import SwiftUI

enum GlassLayout {
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 24
    static let sectionSpacing: CGFloat = 18
}

enum AppTypography {
    static let screenTitle = Font.title.bold()
    static let screenSubtitle = Font.subheadline.weight(.semibold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let body = Font.subheadline
    static let bodyStrong = Font.subheadline.weight(.semibold)
    static let secondary = Font.footnote
    static let secondaryStrong = Font.footnote.weight(.semibold)
    static let caption = Font.caption
    static let captionStrong = Font.caption.weight(.semibold)
    static let captionEmphasis = Font.caption2.weight(.bold)
    static let metric = Font.system(size: 42, weight: .bold, design: .rounded)
    static let metricCompact = Font.system(size: 36, weight: .bold, design: .rounded)
}

struct AppIconTile: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint.opacity(0.14))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct AppStatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(AppTypography.captionEmphasis)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}

struct AppFeaturePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.captionStrong)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(.secondary)
    }
}

struct AppSectionHeader<Accessory: View>: View {
    let systemName: String
    let tint: Color
    let title: String
    let summary: String
    @ViewBuilder var accessory: Accessory

    init(
        systemName: String,
        tint: Color,
        title: String,
        summary: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.systemName = systemName
        self.tint = tint
        self.title = title
        self.summary = summary
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AppIconTile(systemName: systemName, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.cardTitle)
                if !summary.isEmpty {
                    Text(summary)
                        .font(AppTypography.secondary)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory
        }
    }
}

private struct AppInsetPanel: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let tint: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(colorScheme == .dark ? 0.18 : 0.16),
                                tint.opacity(colorScheme == .dark ? 0.08 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.35 : 0.22), lineWidth: 1)
            )
    }
}

private struct LiquidGlassCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(GlassLayout.cardPadding)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: GlassLayout.cardCornerRadius, style: .continuous))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 10, x: 0, y: 4)
        } else {
            content
                .padding(GlassLayout.cardPadding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GlassLayout.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GlassLayout.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 12, x: 0, y: 6)
        }
    }
}

extension View {
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCard())
    }

    func liquidGlassScreenBackground(theme: ThemeOption) -> some View {
        modifier(LiquidGlassScreenBackground(theme: theme))
    }

    func appInsetPanel(tint: Color, cornerRadius: CGFloat = 18) -> some View {
        modifier(AppInsetPanel(tint: tint, cornerRadius: cornerRadius))
    }
}

private struct LiquidGlassScreenBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let theme: ThemeOption

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.09, blue: 0.11), Color(red: 0.13, green: 0.14, blue: 0.17)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        theme.accentColor.opacity(0.12)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.985, blue: 0.99), Color(red: 0.94, green: 0.95, blue: 0.97)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        theme.accentColor.opacity(0.22)
                    }
                }
                .ignoresSafeArea()
            )
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(AppTypography.cardTitle)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 52)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .contentShape(Capsule())
                .shadow(color: Color.black.opacity(0.22), radius: 4, x: 0, y: 2)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
        } else {
            configuration.label
                .font(AppTypography.cardTitle)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 52)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(tint.opacity(0.6), lineWidth: 2)
                )
                .foregroundStyle(.white)
                .contentShape(Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
        }
    }
}
