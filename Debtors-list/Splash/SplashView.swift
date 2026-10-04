

import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var glowExpanded = false
    @State private var cardVisible = false
    @State private var lineProgress: [CGFloat] = [0, 0, 0]
    @State private var lentVisible = false
    @State private var borrowedVisible = false
    @State private var checkProgress: CGFloat = 0
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var isExiting = false
    @State private var checkDrawn = false

    private let titleCharacters = Array("Debtors list Lite")

    var body: some View {
        ZStack {
            InkBackground(glowExpanded: glowExpanded)

            VStack(spacing: 40) {
                ledgerCard
                titleBlock
            }
            .scaleEffect(isExiting ? 1.06 : 1)
            .opacity(isExiting ? 0 : 1)
            .blur(radius: isExiting ? 8 : 0)
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.impact(weight: .light), trigger: checkDrawn)
        .task {
            await runSequence()
        }
    }


    private var ledgerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.inkGlow.opacity(0.35), radius: 40, y: 18)

            VStack(spacing: 0) {
                ledgerRow(index: 0, alignment: .leading) {
                    amountPill("+ 50", color: .owedToMeBright)
                        .offset(x: lentVisible ? 0 : -150)
                        .opacity(lentVisible ? 1 : 0)
                }
                ledgerRow(index: 1, alignment: .trailing) {
                    amountPill("− 20", color: .iOweBright)
                        .offset(x: borrowedVisible ? 0 : 150)
                        .opacity(borrowedVisible ? 1 : 0)
                }
                ledgerRow(index: 2, alignment: .center) {
                    CheckmarkShape()
                        .trim(from: 0, to: checkProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .frame(width: 30, height: 22)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
        .frame(width: 236, height: 172)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .scaleEffect(cardVisible ? 1 : 0.82)
        .opacity(cardVisible ? 1 : 0)
        .rotation3DEffect(.degrees(cardVisible ? 0 : 16), axis: (x: 1, y: 0, z: 0))
        .accessibilityHidden(true)
    }

    private func ledgerRow<Content: View>(
        index: Int,
        alignment: Alignment,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .bottom) {
            content()
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)

            RuledLine()
                .trim(from: 0, to: lineProgress[index])
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(height: 1)
        }
        .frame(height: 48)
    }

    private func amountPill(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
    }


    private var titleBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(titleCharacters.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .opacity(titleVisible ? 1 : 0)
                        .offset(y: titleVisible ? 0 : 12)
                        .blur(radius: titleVisible ? 0 : 4)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(reduceMotion ? 0 : Double(index) * 0.035),
                            value: titleVisible
                        )
                }
            }
            .font(.custom("Noteworthy-Bold", size: 40, relativeTo: .largeTitle))
            .foregroundStyle(.white)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "Debtors list Lite"))

            Text("Track who owes you money")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
                .opacity(subtitleVisible ? 1 : 0)
                .offset(y: subtitleVisible ? 0 : 6)
        }
    }


    private func runSequence() async {
        if reduceMotion {
            cardVisible = true
            lineProgress = [1, 1, 1]
            lentVisible = true
            borrowedVisible = true
            checkProgress = 1
            titleVisible = true
            subtitleVisible = true
            await pause(1.8)
            withAnimation(.easeIn(duration: 0.3)) { isExiting = true }
            await pause(0.3)
            finish()
            return
        }

        withAnimation(.easeInOut(duration: 3)) { glowExpanded = true }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) { cardVisible = true }

        await pause(0.3)
        for index in lineProgress.indices {
            withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.14)) {
                lineProgress[index] = 1
            }
        }

        await pause(0.45)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { lentVisible = true }

        await pause(0.2)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { borrowedVisible = true }

        await pause(0.25)
        withAnimation(.easeInOut(duration: 0.4)) { checkProgress = 1 }

        await pause(0.35)
        checkDrawn = true
        titleVisible = true

        await pause(0.4)
        withAnimation(.easeOut(duration: 0.4)) { subtitleVisible = true }

        await pause(0.65)
        withAnimation(.easeIn(duration: 0.35)) { isExiting = true }

        await pause(0.35)
        finish()
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func finish() {
        guard !Task.isCancelled else { return }
        onFinish()
    }
}
