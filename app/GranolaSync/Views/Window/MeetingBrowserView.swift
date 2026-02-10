import SwiftUI

struct MeetingBrowserView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .date
    @State private var selectedMeeting: MeetingSummary?
    @State private var selectedIds: Set<String> = []

    enum SortOrder: String, CaseIterable {
        case date = "Date"
        case title = "Title"
        case duration = "Duration"
    }

    private var filtered: [MeetingSummary] {
        var list = appState.meetings
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q)
                || $0.attendees.contains(where: { $0.lowercased().contains(q) })
            }
        }
        switch sortOrder {
        case .date: break // already sorted by date from Python
        case .title: list.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .duration: list.sort { ($0.durationSeconds ?? 0) > ($1.durationSeconds ?? 0) }
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Meetings")
                    .font(.largeTitle.bold())
                Spacer()
                if !selectedIds.isEmpty {
                    Button("Export Selected (\(selectedIds.count))") {
                        appState.exportSelected(ids: Array(selectedIds))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(appState.isExporting)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            // Search + sort
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search meetings...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Meeting list
            if appState.isLoadingMeetings && appState.meetings.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading meetings...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No meetings in cache" : "No matches")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filtered) { meeting in
                        MeetingListRow(
                            meeting: meeting,
                            isSelected: selectedIds.contains(meeting.id),
                            onToggle: {
                                if selectedIds.contains(meeting.id) {
                                    selectedIds.remove(meeting.id)
                                } else {
                                    selectedIds.insert(meeting.id)
                                }
                            },
                            onOpen: {
                                selectedMeeting = meeting
                            }
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .onAppear { appState.loadMeetings() }
        .sheet(item: $selectedMeeting) { meeting in
            MeetingDetailView(docId: meeting.docId)
                .environmentObject(appState)
        }
    }
}

struct MeetingListRow: View {
    let meeting: MeetingSummary
    let isSelected: Bool
    var onToggle: () -> Void = {}
    var onOpen: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            // Status badge
            Circle()
                .fill(meeting.isExported ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(meeting.dateDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !meeting.attendeeDisplay.isEmpty {
                        Text(meeting.attendeeDisplay)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            HStack(spacing: 6) {
                if meeting.hasTranscript {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if meeting.hasSummary {
                    Image(systemName: "text.alignleft")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if meeting.hasNotes {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let dur = meeting.durationDisplay {
                Text(dur)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            Button(action: onOpen) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
