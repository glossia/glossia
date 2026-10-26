import SwiftUI

// Presentation-only joint motion, following Atlas Pip's painted-layer rig.
// Neither the clock nor touching Toki performs a request or changes a draft.
private struct TokiPose {
    var bodyAngle = 0.0
    var drop = 0.0
    var leftArm = 0.0
    var rightArm = 0.0

    func interpolated(to next: Self, progress: Double) -> Self {
        let t = progress * progress * (3 - 2 * progress)
        return Self(bodyAngle: bodyAngle + (next.bodyAngle - bodyAngle) * t,
                    drop: drop + (next.drop - drop) * t,
                    leftArm: leftArm + (next.leftArm - leftArm) * t,
                    rightArm: rightArm + (next.rightArm - rightArm) * t)
    }
}

private enum TokiMotion {
    static let duration = 2.4

    static func pose(at time: TimeInterval, delighted: Bool, from initial: TokiPose) -> TokiPose {
        let left = delighted ? 105.0 : 8.0
        let frames: [(Double, TokiPose)] = [
            (0, initial),
            (0.16, TokiPose(bodyAngle: -1, drop: 3, leftArm: -3, rightArm: 6)),
            (0.42, TokiPose(bodyAngle: 2, drop: -2, leftArm: left, rightArm: -110)),
            (0.70, TokiPose(bodyAngle: 1, drop: -1, leftArm: left, rightArm: -130)),
            (0.96, TokiPose(bodyAngle: 2, leftArm: left - 5, rightArm: -100)),
            (1.22, TokiPose(bodyAngle: 1, drop: -1, leftArm: left, rightArm: -128)),
            (1.48, TokiPose(bodyAngle: 0.5, leftArm: left - 4, rightArm: -105)),
            (1.85, TokiPose(bodyAngle: -0.5, drop: 1, leftArm: 3, rightArm: -15)),
            (2.12, TokiPose(bodyAngle: 0.3, rightArm: 3)),
            (duration, TokiPose()),
        ]
        guard time > 0 else { return initial }
        for index in 1..<frames.count where time <= frames[index].0 {
            let previous = frames[index - 1], next = frames[index]
            return previous.1.interpolated(to: next.1, progress: (time - previous.0) / (next.0 - previous.0))
        }
        return TokiPose()
    }
}

// The default plain-button highlight fades each painted layer and exposes
// the overlapping shoulder joints. Toki reacts through motion, not opacity.
private struct TokiButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

struct TokiSprite: View {
    var pose = "Wave"
    var interactive = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var started: Date?
    @State private var initial = TokiPose()
    @State private var idleStarted = Date()
    @State private var sequence = 0
    @State private var delighted = false
    @State private var greeting = false
    @State private var visible = false

    var body: some View {
        Group {
            if interactive {
                Button(action: activate) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || !visible || scenePhase != .active)) { timeline in
                        if reduceMotion {
                            image(greeting ? (delighted ? "Delighted" : "Wave") : "Curious")
                        } else {
                            let joints = current(at: timeline.date)
                            let breath = scenePhase == .active ? sin(timeline.date.timeIntervalSince(idleStarted) * 1.7) : 0
                            rig(joints)
                                .scaleEffect(x: 1 + breath * 0.004, y: 1 + breath * 0.008, anchor: .bottom)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(TokiButtonStyle())
                .accessibilityLabel("Toki")
                .accessibilityValue(greeting ? (delighted ? "Happy to see you" : "Waving hello") : "Ready to help")
                .accessibilityHint("Tap to say hello. Tap again for a different reaction.")
                .accessibilityIdentifier("toki-mascot")
                .accessibilityAction(named: "Say hello", activate)
            } else {
                image(pose).accessibilityHidden(true)
            }
        }
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
        .task(id: sequence) {
            guard greeting else { return }
            do {
                try await Task.sleep(for: .seconds(TokiMotion.duration))
                try Task.checkCancellation()
                settle()
            } catch { }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { idleStarted = Date() }
            else { settle() }
        }
        .onChange(of: reduceMotion) { _, _ in settle() }
        .onAppear { visible = true }
        .onDisappear { visible = false; settle() }
    }

    private func image(_ pose: String) -> some View {
        Image("Toki\(pose)").resizable().scaledToFit()
    }

    private func rig(_ joints: TokiPose) -> some View {
        GeometryReader { geometry in
            ZStack {
                image("LeftArm").rotationEffect(.degrees(joints.leftArm), anchor: UnitPoint(x: 137.0 / 512, y: 250.0 / 512))
                image("RightArm").rotationEffect(.degrees(joints.rightArm), anchor: UnitPoint(x: 375.0 / 512, y: 250.0 / 512))
                image("Body")
            }
            .rotationEffect(.degrees(joints.bodyAngle), anchor: UnitPoint(x: 0.5, y: 0.75))
            .offset(y: joints.drop * geometry.size.width / 512)
        }
    }

    private func current(at date: Date) -> TokiPose {
        started.map { TokiMotion.pose(at: date.timeIntervalSince($0), delighted: delighted, from: initial) } ?? TokiPose()
    }

    private func activate() {
        guard scenePhase == .active else { return }
        let now = Date()
        // Sample before replacing the gesture so another tap never snaps the arm.
        initial = current(at: now)
        delighted = greeting && !delighted
        started = reduceMotion ? nil : now
        greeting = true
        sequence += 1
    }

    private func settle() {
        started = nil; initial = TokiPose(); greeting = false
    }
}
