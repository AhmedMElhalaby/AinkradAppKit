import SwiftUI
import AinkradAppKitContract
import AinkradAppKitUI

/// A settings page: one scrolling column of groups with sticky headers, an
/// optional "on this page" mini-map at width, and the deep-link scroll +
/// highlight target. Pages with three or more groups (measured against the
/// real catalog: Tools has 3, Permissions & Sandbox has 4) get a top tab bar
/// instead, one tab per group, so a tall page never becomes a long scroll —
/// see `usesTabs(page:)`. This is deliberately narrow: it separates groups
/// within one topic, not different topics, which stay flat top-level pages.
public struct SettingsPageView: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let page: SettingsPage
    private let matchedPaths: Set<SettingsPath>?
    private let highlightedPath: SettingsPath?

    @State private var selectedTab: Int = 0

    public init(
        page: SettingsPage,
        matchedPaths: Set<SettingsPath>? = nil,
        highlightedPath: SettingsPath? = nil
    ) {
        self.page = page
        self.matchedPaths = matchedPaths
        self.highlightedPath = highlightedPath
        // Seed the active tab on the FIRST render, not one frame later via
        // `.onChange` — otherwise a deep-link or a pre-filled search arriving
        // with the initial view already selects the wrong tab and the first
        // `scrollTo` targets a row that isn't in the hierarchy yet.
        var initialTab = 0
        if let highlightedPath, let index = Self.tabIndex(containing: highlightedPath, page: page) {
            initialTab = index
        } else if let matchedPaths, !matchedPaths.isEmpty, !page.groups.isEmpty,
                  Self.tabHitCount(group: page.groups[0], matchedPaths: matchedPaths) == 0,
                  let firstHit = page.groups.firstIndex(where: {
                      Self.tabHitCount(group: $0, matchedPaths: matchedPaths) > 0
                  }) {
            initialTab = firstHit
        }
        self._selectedTab = State(initialValue: initialTab)
    }

    public static func showsMiniMap(page: SettingsPage, width: CGFloat) -> Bool {
        page.groups.count >= 4 && width >= SettingsMetrics.miniMapBreakpoint
    }

    /// The mini-map's own occupied width: its fixed content width plus the
    /// trailing padding `miniMap` applies around itself. Kept as the single
    /// source of truth so `rowAreaWidth` and the `miniMap` view can't drift
    /// apart into two different numbers for the same column.
    public static let miniMapOccupiedWidth: CGFloat = 150 + 18

    /// The width actually available to rows: the page's total width minus
    /// whatever the mini-map is occupying, if it's showing at all. Pure and
    /// static so layout-breakpoint decisions near `wideBreakpoint` stay
    /// testable without rendering — the mini-map silently stealing ~168pt
    /// from the row column was previously ignored when picking
    /// `.sideBySide` vs. `.stacked`.
    public static func rowAreaWidth(page: SettingsPage, totalWidth: CGFloat) -> CGFloat {
        showsMiniMap(page: page, width: totalWidth) ? totalWidth - miniMapOccupiedWidth : totalWidth
    }

    /// Tall pages get a tab bar instead of a long scroll. Threshold measured
    /// against the real catalog: Tools has 3 groups and Permissions & Sandbox
    /// has 4; every other page has 1-2, and a tab bar over two groups is worse
    /// than none.
    public static func usesTabs(page: SettingsPage) -> Bool {
        page.groups.count >= tabThreshold
    }
    static let tabThreshold = 3

    /// Matches inside one group, for the badge on its tab. A filter must never
    /// be able to hide a match behind an unselected tab.
    public static func tabHitCount(group: SettingsGroup, matchedPaths: Set<SettingsPath>?) -> Int {
        guard let matchedPaths else { return 0 }
        return group.fields.filter { matchedPaths.contains($0.path) }.count
    }

    /// The tab holding `path`, so a deep-link can switch tabs before scrolling.
    public static func tabIndex(containing path: SettingsPath, page: SettingsPage) -> Int? {
        page.groups.firstIndex { group in
            group.path == path || group.fields.contains { $0.path == path }
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let layout = SettingsRowLayout(detailWidth: Self.rowAreaWidth(page: page, totalWidth: geo.size.width))
            let tabbed = Self.usesTabs(page: page)
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if tabbed {
                        tabBar
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            // Each `SettingsGroupView`'s body is itself a
                            // `Section` (header + content). Nesting those inside
                            // this `LazyVStack(pinnedViews: [.sectionHeaders])`
                            // is what actually pins the group headers while
                            // scrolling — `pinnedViews` only pins the headers of
                            // real `Section`s in the hierarchy, and SwiftUI
                            // resolves a custom view's declared `body` inline, so
                            // the `Section` returned by `SettingsGroupView.body`
                            // counts exactly as if it were written here directly.
                            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                                if !page.resettableFields.isEmpty {
                                    pageHeader
                                }
                                if tabbed {
                                    let index = min(selectedTab, page.groups.count - 1)
                                    SettingsGroupView(
                                        group: page.groups[index], layout: layout,
                                        matchedPaths: matchedPaths,
                                        highlightedPath: highlightedPath)
                                } else {
                                    ForEach(page.groups) { group in
                                        SettingsGroupView(
                                            group: group, layout: layout,
                                            matchedPaths: matchedPaths,
                                            highlightedPath: highlightedPath)
                                    }
                                }
                            }
                            .padding(18)
                        }
                        .scrollContentBackground(.hidden)
                        .onChange(of: highlightedPath) { _, path in
                            // A deep-link may name a field on an inactive tab;
                            // switch to it before the scroll, or the user is
                            // sent to an invisible row.
                            guard let path, tabbed,
                                  let index = Self.tabIndex(containing: path, page: page) else { return }
                            selectedTab = index
                        }
                        .onChange(of: matchedPaths) { _, matched in
                            // If the active tab has no matches but another
                            // does, move there. Otherwise a filter silently
                            // appears to match nothing.
                            guard tabbed, let matched, !matched.isEmpty else { return }
                            if Self.tabHitCount(group: page.groups[selectedTab], matchedPaths: matched) == 0,
                               let firstHit = page.groups.firstIndex(where: {
                                   Self.tabHitCount(group: $0, matchedPaths: matched) > 0
                               }) {
                                if reduceMotion {
                                    selectedTab = firstHit
                                } else {
                                    withAnimation(.easeOut(duration: AinkradMotion.durationBase)) {
                                        selectedTab = firstHit
                                    }
                                }
                            }
                        }
                        .onChange(of: highlightedPath) { _, path in
                            guard let path else { return }
                            if reduceMotion {
                                proxy.scrollTo(path, anchor: .center)
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(path, anchor: .center)
                                }
                            }
                        }
                    }
                }

                if !tabbed, Self.showsMiniMap(page: page, width: geo.size.width) {
                    miniMap
                }
            }
        }
    }

    /// Tab strip for tall pages, one tab per group, badged with its hit count
    /// while filtering so a search can never hide a match behind an
    /// unselected tab.
    private var tabBar: some View {
        AinkradTabs(tabs: Array(page.groups.indices), selection: $selectedTab) { index in
            let group = page.groups[index]
            let hits = Self.tabHitCount(group: group, matchedPaths: matchedPaths)
            return hits > 0 ? "\(group.title) (\(hits))" : group.title
        }
        .padding(.horizontal, AinkradSpacing.lg)
        .padding(.top, AinkradSpacing.lg)
    }

    /// Page-level reset control. Shown only when `resettableFields` is
    /// non-empty — i.e. at least one field on this page is both resettable
    /// and currently modified from its default.
    private var pageHeader: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: { page.resetAll() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 10))
                    Text("Reset this page")
                        .font(AinkradFontResolver.font(.caption, weight: .medium, typography: typo))
                }
                .foregroundStyle(tokens.accentSecondary.opacity(0.9))
            }
            .buttonStyle(.plain)
            .help("Restore all modified fields on this page to their defaults")
        }
    }

    private var miniMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ON THIS PAGE")
                .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
                .kerning(2.5)
                .foregroundStyle(tokens.foreground.opacity(0.4))
            ForEach(page.groups) { group in
                Text(group.title)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(tokens.foreground.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .frame(width: Self.miniMapOccupiedWidth - 18, alignment: .topLeading)
        .padding(.top, 18)
        .padding(.trailing, 18)
    }
}
