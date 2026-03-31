// TimerManager.swift
// Central timer orchestrator — bridges TimerEngine with UI, haptics, sounds, persistence

import SwiftUI
import CoreData
import AVFoundation

@MainActor
class TimerManager: ObservableObject {
    @Published var engine = TimerEngine()
    @Published var selectedWorkflow: Workflow?
    @Published var workflows: [Workflow] = []
    @Published var isSessionActive = false

    private var audioPlayer: AVAudioPlayer?
    private var sessionStartTime: Date?
    private var observers: [NSObjectProtocol] = []

    // Settings
    @AppStorage("selectedSound") var selectedSound: String = "bell"
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true

    init() {
        setupObservers()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Workflow Management

    func loadWorkflows(context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDWorkflow")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            let results = try context.fetch(request)
            workflows = results.compactMap { Workflow.from(managedObject: $0) }

            // Select first workflow if none selected
            if selectedWorkflow == nil, let first = workflows.first {
                selectWorkflow(first)
            }
        } catch {
            print("Failed to load workflows: \(error)")
        }
    }

    func selectWorkflow(_ workflow: Workflow) {
        selectedWorkflow = workflow
        engine.load(intervals: workflow.intervals)
    }

    func saveWorkflow(_ workflow: Workflow, context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDWorkflow")
        request.predicate = NSPredicate(format: "id == %@", workflow.id as CVarArg)

        do {
            let results = try context.fetch(request)
            let managed: NSManagedObject

            if let existing = results.first {
                managed = existing
            } else {
                managed = NSEntityDescription.insertNewObject(forEntityName: "CDWorkflow", into: context)
                managed.setValue(workflow.id, forKey: "id")
                managed.setValue(workflow.createdAt, forKey: "createdAt")
            }

            managed.setValue(workflow.name, forKey: "name")
            managed.setValue(workflow.isDefault, forKey: "isDefault")

            let data = try JSONEncoder().encode(workflow.intervals)
            managed.setValue(data, forKey: "intervalsData")

            try context.save()
            loadWorkflows(context: context)
        } catch {
            print("Failed to save workflow: \(error)")
        }
    }

    func deleteWorkflow(_ workflow: Workflow, context: NSManagedObjectContext) {
        guard !workflow.isDefault else { return }

        let request = NSFetchRequest<NSManagedObject>(entityName: "CDWorkflow")
        request.predicate = NSPredicate(format: "id == %@", workflow.id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let managed = results.first {
                context.delete(managed)
                try context.save()
                loadWorkflows(context: context)

                if selectedWorkflow?.id == workflow.id {
                    selectedWorkflow = workflows.first
                    if let w = selectedWorkflow {
                        engine.load(intervals: w.intervals)
                    }
                }
            }
        } catch {
            print("Failed to delete workflow: \(error)")
        }
    }

    // MARK: - Timer Control

    func startTimer() {
        sessionStartTime = Date()
        isSessionActive = true
        engine.start()
        triggerHaptic(.heavy)
    }

    func pauseTimer() {
        engine.pause()
        triggerHaptic(.medium)
    }

    func resumeTimer() {
        engine.resume()
        triggerHaptic(.light)
    }

    func resetTimer() {
        engine.reset()
        isSessionActive = false
        triggerHaptic(.rigid)
    }

    func skipInterval() {
        engine.skip()
        triggerHaptic(.soft)
    }

    // MARK: - Session Persistence

    func saveCompletedSession(context: NSManagedObjectContext) {
        guard let startTime = sessionStartTime else { return }

        let session = NSEntityDescription.insertNewObject(forEntityName: "CDSession", into: context)
        session.setValue(UUID(), forKey: "id")
        session.setValue(startTime, forKey: "startedAt")
        session.setValue(Date(), forKey: "endedAt")
        session.setValue(Int32(engine.elapsedFocusSeconds), forKey: "totalFocusSeconds")
        session.setValue(Int32(engine.elapsedBreakSeconds), forKey: "totalBreakSeconds")
        session.setValue(Int16(engine.completedIntervalsCount), forKey: "completedIntervals")
        session.setValue(engine.state == .completed, forKey: "wasCompleted")
        session.setValue(selectedWorkflow?.name ?? "Unknown", forKey: "workflowName")

        // Link to workflow
        if let workflowId = selectedWorkflow?.id {
            let wfRequest = NSFetchRequest<NSManagedObject>(entityName: "CDWorkflow")
            wfRequest.predicate = NSPredicate(format: "id == %@", workflowId as CVarArg)
            if let wf = try? context.fetch(wfRequest).first {
                session.setValue(wf, forKey: "workflow")
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save session: \(error)")
        }

        sessionStartTime = nil
        isSessionActive = false
    }

    // MARK: - Sounds

    func playSound(_ name: String? = nil) {
        let soundName = name ?? selectedSound
        // Built-in sounds: bell, chime, crystal, pulse
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav")
                ?? Bundle.main.url(forResource: soundName, withExtension: "mp3")
                ?? Bundle.main.url(forResource: soundName, withExtension: "m4a") else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1007)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1007)
        }
    }

    // MARK: - Haptics

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Observers

    private func setupObservers() {
        let intervalObs = NotificationCenter.default.addObserver(
            forName: .intervalChanged, object: nil, queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task { @MainActor in
                self.playSound()
                if let interval = notification.object as? TimerInterval {
                    if interval.type == .work {
                        self.triggerNotificationHaptic(.warning)
                    } else {
                        self.triggerNotificationHaptic(.success)
                    }
                }
            }
        }

        let completedObs = NotificationCenter.default.addObserver(
            forName: .workflowCompleted, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.playSound()
                self.triggerNotificationHaptic(.success)
            }
        }

        observers = [intervalObs, completedObs]
    }
}
