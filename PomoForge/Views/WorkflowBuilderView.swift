// WorkflowBuilderView.swift
// Create and edit custom workflows with drag-to-reorder intervals

import SwiftUI

// MARK: - Workflow List View

struct WorkflowListView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingBuilder = false
    @State private var editingWorkflow: Workflow?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(timerManager.workflows) { workflow in
                    WorkflowRow(workflow: workflow)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingWorkflow = workflow
                        }
                        .swipeActions(edge: .trailing) {
                            if !workflow.isDefault {
                                Button(role: .destructive) {
                                    timerManager.deleteWorkflow(workflow, context: viewContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Workflows")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        let customCount = timerManager.workflows.filter { !$0.isDefault }.count
                        if subscriptionManager.canCreateWorkflow(currentCount: customCount) {
                            showingBuilder = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingBuilder) {
                WorkflowBuilderView(mode: .create) { workflow in
                    timerManager.saveWorkflow(workflow, context: viewContext)
                }
            }
            .sheet(item: $editingWorkflow) { workflow in
                WorkflowBuilderView(mode: .edit(workflow)) { updated in
                    timerManager.saveWorkflow(updated, context: viewContext)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .overlay {
                if timerManager.workflows.isEmpty {
                    ContentUnavailableView(
                        "No Workflows",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Tap + to create your first custom workflow.")
                    )
                }
            }
        }
    }
}

// MARK: - Workflow Row

struct WorkflowRow: View {
    let workflow: Workflow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workflow.name)
                    .font(.headline)

                Spacer()

                if workflow.isDefault {
                    Text("DEFAULT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                }
            }

            HStack(spacing: 12) {
                Label(workflow.formattedTotal, systemImage: "clock")
                Label(workflow.intervalSummary, systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Mini interval preview
            HStack(spacing: 3) {
                ForEach(Array(workflow.intervals.prefix(12).enumerated()), id: \.offset) { _, interval in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForType(interval.type))
                        .frame(width: CGFloat(interval.duration) / 60, height: 6)
                        .frame(maxWidth: 40)
                }
                if workflow.intervals.count > 12 {
                    Text("+\(workflow.intervals.count - 12)")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ type: IntervalType) -> Color {
        switch type {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}

// MARK: - Workflow Builder

enum WorkflowBuilderMode: Identifiable {
    case create
    case edit(Workflow)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let w): return w.id.uuidString
        }
    }
}

struct WorkflowBuilderView: View {
    let mode: WorkflowBuilderMode
    let onSave: (Workflow) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var intervals: [TimerInterval] = []
    @State private var showingAddInterval = false

    init(mode: WorkflowBuilderMode, onSave: @escaping (Workflow) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _intervals = State(initialValue: [
                TimerInterval(type: .work, duration: 1500),
                TimerInterval(type: .shortBreak, duration: 300)
            ])
        case .edit(let workflow):
            _name = State(initialValue: workflow.name)
            _intervals = State(initialValue: workflow.intervals)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("Workflow Name") {
                    TextField("e.g. Writer Flow", text: $name)
                        .font(.headline)
                }

                // Intervals (drag to reorder)
                Section {
                    ForEach($intervals) { $interval in
                        IntervalRow(interval: $interval)
                    }
                    .onMove { from, to in
                        intervals.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        intervals.remove(atOffsets: offsets)
                    }
                } header: {
                    HStack {
                        Text("Intervals")
                        Spacer()
                        Text(totalSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Add interval buttons
                Section {
                    Button(action: { addInterval(.work) }) {
                        Label("Add Focus Interval", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    Button(action: { addInterval(.shortBreak) }) {
                        Label("Add Short Break", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    Button(action: { addInterval(.longBreak) }) {
                        Label("Add Long Break", systemImage: "moon.fill")
                            .foregroundStyle(.blue)
                    }
                }

                // Quick templates
                Section("Quick Templates") {
                    Button("Classic 25/5 x4") {
                        applyTemplate(work: 25, shortBreak: 5, rounds: 4, longBreak: 15)
                    }
                    Button("Deep Work 52/17 x3") {
                        applyTemplate(work: 52, shortBreak: 17, rounds: 3, longBreak: 30)
                    }
                    Button("Sprint 15/3 x6") {
                        applyTemplate(work: 15, shortBreak: 3, rounds: 6, longBreak: 10)
                    }
                }
                .foregroundStyle(.orange)
            }
            .navigationTitle(isEditing ? "Edit Workflow" : "New Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || intervals.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var totalSummary: String {
        let total = intervals.reduce(0) { $0 + $1.duration } / 60
        return "\(total) min total"
    }

    private func addInterval(_ type: IntervalType) {
        let defaultDuration: Int
        switch type {
        case .work: defaultDuration = 1500
        case .shortBreak: defaultDuration = 300
        case .longBreak: defaultDuration = 900
        }
        intervals.append(TimerInterval(type: type, duration: defaultDuration))
    }

    private func applyTemplate(work: Int, shortBreak: Int, rounds: Int, longBreak: Int) {
        var newIntervals: [TimerInterval] = []
        for i in 0..<rounds {
            newIntervals.append(TimerInterval(type: .work, duration: work * 60))
            if i < rounds - 1 {
                newIntervals.append(TimerInterval(type: .shortBreak, duration: shortBreak * 60))
            }
        }
        newIntervals.append(TimerInterval(type: .longBreak, duration: longBreak * 60))
        intervals = newIntervals
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !intervals.isEmpty else { return }

        let workflow: Workflow
        switch mode {
        case .create:
            workflow = Workflow(
                id: UUID(),
                name: trimmedName,
                intervals: intervals,
                isDefault: false,
                createdAt: Date()
            )
        case .edit(let existing):
            workflow = Workflow(
                id: existing.id,
                name: trimmedName,
                intervals: intervals,
                isDefault: existing.isDefault,
                createdAt: existing.createdAt
            )
        }

        onSave(workflow)
        dismiss()
    }
}

// MARK: - Interval Row

struct IntervalRow: View {
    @Binding var interval: TimerInterval

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(colorForType(interval.type))
                .frame(width: 10, height: 10)

            // Type label
            Text(interval.type.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Duration stepper
            HStack(spacing: 8) {
                Button(action: {
                    if interval.duration > 60 {
                        interval.duration -= 60
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(interval.duration / 60)m")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .frame(width: 40)

                Button(action: {
                    interval.duration += 60
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    private func colorForType(_ type: IntervalType) -> Color {
        switch type {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}
