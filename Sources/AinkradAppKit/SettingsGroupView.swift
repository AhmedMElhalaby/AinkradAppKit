import SwiftUI
import AinkradAppKitContract
import AinkradAppKitUI

/// A titled group of rows: accent-tick header, optional collapse,
/// optional footer note, and a hit count while a filter is active.
///
/// `body` is a `Section` (header + content) rather than a bare `VStack`.
/// SwiftUI resolves a custom view's `body` structurally at compile time, so
/// when a `SettingsGroupView` is placed inside a `LazyVStack(pinnedViews:
/// [.sectionHeaders])` (see `SettingsPageView`), the `Section` it returns is
/// exactly as pinnable as one written inline — the wrapping struct adds no
/// indirection SwiftUI can't see through. Used standalone (outside a
/// pinned-header container) a `Section` still lays out header-then-content
/// like a `VStack`, so this stays a legitimate solo view too.
public struct SettingsGroupView: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let group: SettingsGroup
    private let layout: SettingsRowLayout
    private let matchedPaths: Set<SettingsPath>?
    private let highlightedPath: SettingsPath?
    @State private var isExpanded: Bool

    public init(
        group: SettingsGroup,
        layout: SettingsRowLayout,
        matchedPaths: Set<SettingsPath>? = nil,
        highlightedPath: SettingsPath? = nil
    ) {
        self.group = group
        self.layout = layout
        self.matchedPaths = matchedPaths
        self.highlightedPath = highlightedPath
        _isExpanded = State(initialValue: group.disclosure == .always)
    }

    /// Non-matching rows dim; they are never removed. Half-hidden sections
    /// destroy the spatial memory that makes settings learnable.
    public static func opacity(for path: SettingsPath, matchedPaths: Set<SettingsPath>?) -> Double {
        guard let matchedPaths else { return 1.0 }
        return matchedPaths.contains(path) ? 1.0 : 0.35
    }

    public static func hitCount(group: SettingsGroup, matchedPaths: Set<SettingsPath>?) -> Int {
        guard let matchedPaths else { return 0 }
        return group.fields.filter { matchedPaths.contains($0.path) }.count
    }

    public var body: some View {
        Section {
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(group.fields) { field in
                        SettingsRow(field: field, layout: layout)
                            .opacity(Self.opacity(for: field.path, matchedPaths: matchedPaths))
                            .overlay(
                                ChamferShape(cut: AinkradRadius.md)
                                    .strokeBorder(
                                        highlightedPath == field.path
                                            ? tokens.accentSecondary.opacity(0.9) : .clear,
                                        lineWidth: 1.5))
                            .id(field.path)
                    }
                    if let note = group.footerNote {
                        Text(note)
                            .font(AinkradFontResolver.font(.caption, typography: typo))
                            .foregroundStyle(tokens.foreground.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 2)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isExpanded)
            }
        } header: {
            header
        }
    }

    private var header: some View {
        Group {
            if group.disclosure == .collapsedByDefault {
                Button {
                    isExpanded.toggle()
                } label: {
                    headerContent(showsChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                // `.always` groups are never interactive — a header that
                // looks clickable but does nothing is worse than one that
                // plainly isn't a control.
                headerContent(showsChevron: false)
            }
        }
        .id(group.path)
        .background(tokens.background)
    }

    private func headerContent(showsChevron: Bool) -> some View {
        HStack(spacing: 8) {
            AinkradSectionHeader(title: group.title)
            let hits = Self.hitCount(group: group, matchedPaths: matchedPaths)
            if hits > 0 {
                AinkradBadge(text: "\(hits)", tint: tokens.accentSecondary)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    // Sizes an SF Symbol glyph, not text — the
                    // AinkradFont-only rule governs text typography, not
                    // icon point size.
                    .font(.system(size: 10))
                    .foregroundStyle(tokens.foreground.opacity(0.45))
            }
        }
        .contentShape(Rectangle())
    }
}
