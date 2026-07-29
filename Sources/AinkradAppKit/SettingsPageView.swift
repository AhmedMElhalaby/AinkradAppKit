import SwiftUI
import AinkradAppKitContract
import AinkradAppKitUI

/// A settings page: one scrolling column of groups with sticky headers, an
/// optional "on this page" mini-map at width, and the deep-link scroll +
/// highlight target. No nested tabs anywhere — depth is the enemy here.
public struct SettingsPageView: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let page: SettingsPage
    private let matchedPaths: Set<SettingsPath>?
    private let highlightedPath: SettingsPath?

    public init(
        page: SettingsPage,
        matchedPaths: Set<SettingsPath>? = nil,
        highlightedPath: SettingsPath? = nil
    ) {
        self.page = page
        self.matchedPaths = matchedPaths
        self.highlightedPath = highlightedPath
    }

    public static func showsMiniMap(page: SettingsPage, width: CGFloat) -> Bool {
        page.groups.count >= 4 && width >= SettingsMetrics.miniMapBreakpoint
    }

    public var body: some View {
        GeometryReader { geo in
            let layout = SettingsRowLayout(detailWidth: geo.size.width)
            HStack(alignment: .top, spacing: 0) {
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
                            ForEach(page.groups) { group in
                                SettingsGroupView(
                                    group: group, layout: layout,
                                    matchedPaths: matchedPaths,
                                    highlightedPath: highlightedPath)
                            }
                        }
                        .padding(18)
                    }
                    .scrollContentBackground(.hidden)
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

                if Self.showsMiniMap(page: page, width: geo.size.width) {
                    miniMap
                }
            }
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
        .frame(width: 150, alignment: .topLeading)
        .padding(.top, 18)
        .padding(.trailing, 18)
    }
}
