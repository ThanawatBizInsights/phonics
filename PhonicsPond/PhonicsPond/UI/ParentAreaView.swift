import SwiftUI

/// Grown-up area (opened by a 3-second hold). Uses standard iPad controls and system text sizes.
struct ParentAreaView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var section: Section? = .progress
    @State private var confirmReset = false
    @State private var confirmResetAgain = false

    enum Section: String, CaseIterable, Identifiable {
        case progress = "Progress"
        case pages = "Books"
        case offline = "Off-screen activities"
        case settings = "Settings"
        case audio = "Recordings"
        case content = "Content check"
        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .progress: return "chart.bar"
            case .pages: return "book.pages"
            case .offline: return "figure.and.child.holdinghands"
            case .settings: return "gearshape"
            case .audio: return "waveform"
            case .content: return "checkmark.seal"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.systemImage).tag(item)
            }
            .navigationTitle("Grown-ups")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        } detail: {
            NavigationStack {
                detail
                    .navigationTitle(section?.rawValue ?? "")
            }
        }
        .tint(Palette.blue)
    }

    @ViewBuilder
    private var detail: some View {
        switch section ?? .progress {
        case .progress: progress
        case .pages: pages
        case .offline: offline
        case .settings: settings
        case .audio: AudioStatusView()
        case .content: contentCheck
        }
    }

    // MARK: Progress

    private var progress: some View {
        let thai = app.store.data.settings.thaiHelp
        let pronoun = app.store.data.settings.pronoun
        return List {
            SwiftUI.Section {
                Text("Your marks are what you saw. The app never listens or scores speech. Each mark is dated; the latest is shown.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            ForEach(Skill.allCases) { skill in
                SwiftUI.Section(thai ? "\(skill.title) · \(skill.thai)" : skill.title) {
                    ForEach(items(for: skill), id: \.self) { item in
                        HStack {
                            Text(item).font(Typeface.letter(28)).frame(width: 80, alignment: .leading)
                            if let last = app.store.data.latestMark(level: app.level, skill: skill, item: item) {
                                Text(last.mark.label(pronoun: pronoun)).fontWeight(.semibold)
                                Text(last.date, style: .date).foregroundStyle(.secondary)
                            } else {
                                Text("Not marked").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu("Mark") {
                                ForEach(Mark.allCases) { mark in
                                    Button(thai ? "\(mark.label(pronoun: pronoun)) · \(mark.thai)" : mark.label(pronoun: pronoun)) {
                                        app.store.update { $0.mark(mark, skill: skill, item: item, level: app.level) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            SwiftUI.Section("What the app saw (touch tasks only)") {
                appSeenRow("Letters traced", keys: app.levelLetters.map { "trace.\($0)" }, labels: app.levelLetters)
                appSeenRow("Last sound: right first time / tried again", keys: ["lastSound.correct", "lastSound.retry"], labels: ["right", "again"])
                appSeenRow("Word Builder: tiles moved back / help used", keys: ["builder.misplaced", "builder.help"], labels: ["moved", "help"])
                appSeenRow("Optional sound hunt done", keys: ["offline.soundHunt"], labels: ["times"])
                HStack {
                    Text("Stickers")
                    Spacer()
                    Text("\(app.store.data.stickers.count)").monospacedDigit()
                }
            }
        }
    }

    private func items(for skill: Skill) -> [String] {
        switch skill {
        case .soundRecognition, .letterFormation: return app.levelLetters
        case .blending: return ["sat", "tap", "pat", "at"]
        case .segmenting: return ["sat", "tap", "pat"]
        case .finalSoundClarity: return ["t", "p"]
        }
    }

    private func appSeenRow(_ title: String, keys: [String], labels: [String]) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(zip(labels, keys).map { "\($0.0) \(app.store.data.appSeen[$0.1] ?? 0)" }.joined(separator: " · "))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Pages

    /// Storybook progress for each book; open any unlocked book.
    private var pages: some View {
        List {
            SwiftUI.Section("Storybook") {
                ForEach(app.library.books.sorted { $0.level < $1.level }) { book in
                    let p = app.store.data.book(book.id)
                    let unlocked = app.store.data.isUnlocked(book, in: app.library)
                    HStack {
                        Text("Level \(book.level)").fontWeight(.semibold)
                        Text(book.title).foregroundStyle(.secondary)
                        Spacer()
                        Text(book.status == .draft ? "Story coming soon" :
                             "\(p.pageTrophies.count)/\(book.pages.count) pages\(p.levelTrophy ? " · big trophy" : "")")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Button("Open") {
                            dismiss()
                            app.openStory(book.id)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!unlocked)
                    }
                }
            }
            SwiftUI.Section {
                Text("Books open in order: finishing every page of a level earns its big trophy and opens the next book. Levels 2–12 open once their stories are written.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    /// Retired v1.0 lesson pages (not reachable from the child's navigation).
    private var legacyLessonPages: some View {
        List {
            SwiftUI.Section("Level 1 · s a t p") {
                ForEach(app.plan.pages, id: \.page) { page in
                    let p = app.store.data.progress(level: app.level, page: page.page)
                    HStack {
                        Text("Page \(page.page)").fontWeight(.semibold)
                        Text(p.done ? "Done" : (p.started ? "In progress · \(page.stages[min(p.stage, page.stages.count - 1)].stone.label)" : "Not started"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open") {
                            dismiss()
                            app.openPage(page.page)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            SwiftUI.Section {
                Picker("Stay on this page tomorrow", selection: Binding(
                    get: { app.store.data.settings.pinnedPage ?? 0 },
                    set: { value in app.store.update { $0.settings.pinnedPage = value == 0 ? nil : value } })) {
                    Text("Off (next page)").tag(0)
                    ForEach(app.plan.pages, id: \.page) { Text("Page \($0.page)").tag($0.page) }
                }
                Text("Today's button opens the pinned page until it is finished.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            SwiftUI.Section("Later levels") {
                ForEach(app.curriculum.levels.filter { $0.level > 1 }, id: \.level) { level in
                    HStack {
                        Text("Level \(level.level)").fontWeight(.semibold)
                        Text(level.title).foregroundStyle(.secondary)
                        Spacer()
                        Text("coming later").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Off-screen

    private var offline: some View {
        List {
            ForEach([OfflineCardKind.soundHunt, .tissueGame], id: \.self) { kind in
                SwiftUI.Section(OfflineCards.title(kind)) {
                    Text(OfflineCards.steps(kind))
                    if app.store.data.settings.thaiHelp { Text(OfflineCards.stepsThai(kind)) }
                }
            }
            SwiftUI.Section("Rice tray") {
                Text("Pour rice into a tray. Your child traces each letter with one finger and says the sound while writing, not after.")
                if app.store.data.settings.thaiHelp {
                    Text("เทข้าวสารลงในถาด ให้ลูกใช้นิ้วเขียนตัวอักษรบนข้าว และพูดเสียงไปพร้อมกับเขียน")
                }
            }
            if let focus = app.levelDefinition?.focus {
                SwiftUI.Section("Level 1 focus for Thai speakers") { Text(focus) }
            }
        }
    }

    // MARK: Settings

    private var settings: some View {
        Form {
            Toggle("Background music", isOn: Binding(get: { app.store.data.settings.musicOn }, set: { app.setMusic($0) }))
                .accessibilityIdentifier("settings.music")
            Toggle("Soft chime after a sticker", isOn: Binding(get: { app.store.data.settings.chime }, set: { app.setChime($0) }))
            Toggle("Thai help for grown-ups and meanings", isOn: Binding(
                get: { app.store.data.settings.thaiHelp },
                set: { value in app.store.update { $0.settings.thaiHelp = value } }))
            Picker("Progress labels", selection: Binding(
                get: { app.store.data.settings.pronoun },
                set: { value in app.store.update { $0.settings.pronoun = value } })) {
                Text("On her own").tag("her")
                Text("On his own").tag("his")
                Text("On their own").tag("their")
            }
            SwiftUI.Section {
                Button("Reset all progress on this iPad", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Progress, stickers and marks are stored only on this iPad. No account, camera, microphone or speech scoring.")
            }
        }
        .confirmationDialog("Reset progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Continue", role: .destructive) { confirmResetAgain = true }
        } message: {
            Text("This deletes all stickers, saved positions and grown-up marks on this iPad.")
        }
        .alert("Delete everything?", isPresented: $confirmResetAgain) {
            Button("Delete", role: .destructive) { app.store.reset(); app.setChime(true) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: Content check

    private var contentCheck: some View {
        List {
            SwiftUI.Section("Reading targets checked against taught letters and tricky words") {
                if app.contentIssues.isEmpty {
                    Label("Every reading target uses only taught correspondences.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Palette.success)
                } else {
                    ForEach(app.contentIssues, id: \.description) { Text($0.description) }
                }
            }
            SwiftUI.Section("Artwork still needed") {
                let missing = ArtworkNames.missing
                if missing.isEmpty {
                    Text("All artwork supplied.")
                } else {
                    ForEach(missing, id: \.self) { Text($0).font(.body.monospaced()) }
                }
            }
            SwiftUI.Section("Accent") { Text(app.curriculum.accent) }
        }
    }
}

/// Lists every Level 1 clip and whether a recording is in the app bundle.
struct AudioStatusView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ids = app.level1AudioIDs
        let missing = ids.filter { !app.audio.isAvailable($0) }
        List {
            SwiftUI.Section {
                Text("\(ids.count - missing.count) of \(ids.count) recordings are in the app.")
                    .fontWeight(.semibold)
                Text("Add .wav files named exactly as below to PhonicsPond/PhonicsPond/Resources/Audio/ and rebuild. Missing clips are skipped, so lessons still work.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            SwiftUI.Section("Clips") {
                ForEach(ids, id: \.self) { id in
                    HStack {
                        Image(systemName: app.audio.isAvailable(id) ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(app.audio.isAvailable(id) ? Palette.success : Palette.pending)
                        Text("\(id).wav").font(.body.monospaced())
                        Spacer()
                        if let prompt = Prompt(rawValue: id) {
                            Text("\u{201C}\(prompt.text)\u{201D}").foregroundStyle(.secondary).lineLimit(1)
                        }
                        Button {
                            app.audio.play(id)
                        } label: {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(!app.audio.isAvailable(id))
                        .accessibilityLabel("play \(id)")
                    }
                }
            }
        }
        .onDisappear { app.audio.leaveScreen() }
    }
}
