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
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.22), radius: 4, x: 0, y: 2)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
        } else {
            configuration.label
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(tint.opacity(0.6), lineWidth: 2)
                )
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
        }
    }
}
