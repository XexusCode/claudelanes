import LanesCore
import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: UUID?
    @State private var showImport = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(model.profiles) { profile in
                        HStack(spacing: 8) {
                            Image(nsImage: profile.icon(size: 20))
                            Text(profile.name)
                            Spacer()
                            if model.isRunning(profile) {
                                Circle().fill(.green).frame(width: 7, height: 7)
                                    .help("Open")
                            }
                        }
                        .tag(profile.id)
                    }
                    .onMove { model.move(from: $0, to: $1) }
                }
                Divider()
                HStack {
                    Menu {
                        Button("New Profile") { selection = model.addProfile().id }
                        Button("Import from Current Claude…") { showImport = true }
                            .disabled(!model.canImportDefaultClaude)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Add profile")
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: 200)

            Divider()

            Group {
                if let id = selection, let profile = model.profiles.first(where: { $0.id == id }) {
                    ProfileEditor(profile: profile)
                        .id(profile.id)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text(model.profiles.isEmpty ? "Add a profile for each Claude account." : "Select a profile.")
                            .foregroundStyle(.secondary)
                        if model.profiles.isEmpty {
                            Button("Add Profile") { selection = model.addProfile(name: "Personal").id }
                            if model.canImportDefaultClaude {
                                Button("Import from Current Claude…") { showImport = true }
                                    .buttonStyle(.link)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 380)
        }
        .frame(height: 360)
        .onAppear { if selection == nil { selection = model.profiles.first?.id } }
        .sheet(isPresented: $showImport) {
            ImportSheet { selection = $0.id }
                .environmentObject(model)
        }
        .alert("ClaudeLanes", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct ProfileEditor: View {
    @EnvironmentObject private var model: AppModel
    @State private var draft: Profile
    @State private var confirmDelete = false
    @State private var deleteData = false

    init(profile: Profile) {
        _draft = State(initialValue: profile)
    }

    private var running: Bool { model.isRunning(draft) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: draft.icon(size: 64))
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.launcherName).font(.headline)
                    Text(running ? "Open" : "Not running")
                        .font(.subheadline)
                        .foregroundStyle(running ? .green : .secondary)
                }
            }

            Form {
                TextField("Name", text: $draft.name)
                    .onSubmit(save)
                LabeledContent("Colour") {
                    HStack(spacing: 6) {
                        ForEach(ProfileColor.palette, id: \.self) { hex in
                            Swatch(hex: hex, selected: draft.colorHex.uppercased() == hex) {
                                draft.colorHex = hex
                                save()
                            }
                        }
                    }
                }
            }
            .formStyle(.columns)

            HStack {
                Button(running ? "Bring to Front" : "Open") {
                    save()
                    model.open(draft)
                }
                .keyboardShortcut(.defaultAction)
                if running {
                    Button("Quit") { model.quit(draft) }
                }
                Button("Show Launcher") { model.revealLauncher(draft) }
                Spacer()
                Button("Delete…", role: .destructive) { confirmDelete = true }
            }

            Text("The launcher lives in ~/Applications/ClaudeLanes. Drag it to the Dock to open this account directly.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(20)
        .onDisappear(perform: save)
        .sheet(isPresented: $confirmDelete) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Delete “\(draft.name)”?").font(.headline)
                Text("Its launcher is removed. Your session stays on disk unless you also delete its data.")
                    .fixedSize(horizontal: false, vertical: true)
                Toggle("Also move its session data to the Trash", isOn: $deleteData)
                HStack {
                    Spacer()
                    Button("Cancel") { confirmDelete = false }
                        .keyboardShortcut(.cancelAction)
                    Button("Delete", role: .destructive) {
                        confirmDelete = false
                        model.delete(draft, deleteData: deleteData)
                    }
                }
            }
            .padding(20)
            .frame(width: 360)
        }
    }

    private func save() {
        guard let current = model.profiles.first(where: { $0.id == draft.id }),
              current.name != draft.name || current.colorHex != draft.colorHex else { return }
        model.update(draft)
    }
}

/// Turns the normal Claude's sign-in, settings and history into a new profile.
private struct ImportSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Work"
    @State private var importing = false
    let onImported: (Profile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import from Current Claude").font(.headline)
            Text("Copies your current Claude's sign-in, settings and history into a new profile. Your normal Claude keeps its own data as a backup.")
                .fixedSize(horizontal: false, vertical: true)
            TextField("Profile name", text: $name)
            if model.defaultClaudeRunning {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Claude is open. Quit it first so its data is not copied half-written. Save anything you are working on.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Quit Claude") { model.quitDefaultClaude() }
            }
            HStack {
                if importing {
                    ProgressView().controlSize(.small)
                    Text("Copying…").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(importing)
                Button("Import") {
                    importing = true
                    Task {
                        let profile = await model.importDefaultClaude(name: name)
                        importing = false
                        if let profile {
                            onImported(profile)
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(importing || model.defaultClaudeRunning
                          || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

private struct Swatch: View {
    let hex: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let c = ProfileColor.components(hex) ?? (0, 0, 0)
        Button(action: action) {
            Circle()
                .fill(Color(.sRGB, red: c.red, green: c.green, blue: c.blue))
                .frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(.primary.opacity(selected ? 0.8 : 0), lineWidth: 2).padding(-3))
        }
        .buttonStyle(.plain)
        .help(hex)
    }
}
