import SwiftUI

// MARK: - Theme Colors

extension Color {
    static let calcRed = Color(red: 217 / 255, green: 56 / 255, blue: 58 / 255)
    static let calcYellow = Color(red: 247 / 255, green: 209 / 255, blue: 23 / 255)
    static let calcBlue = Color(red: 99 / 255, green: 164 / 255, blue: 218 / 255)
    static let calcInk = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    static let calcPaper = Color(red: 252 / 255, green: 248 / 255, blue: 237 / 255)
    static let calcPaperDark = Color(red: 232 / 255, green: 226 / 255, blue: 210 / 255)
    static let calcBg = Color(red: 45 / 255, green: 58 / 255, blue: 43 / 255)
}

// MARK: - Calculator Engine

@Observable
class CalculatorEngine {
    var displayText = "0"
    var historyText = ""

    private var currentInput = "0"
    private var previousInput = ""
    private var operation: String?
    private var shouldResetDisplay = false

    func numberPressed(_ num: String) {
        if currentInput == "0" || shouldResetDisplay {
            currentInput = num
            shouldResetDisplay = false
        } else if currentInput.count < 12 {
            currentInput += num
        }
        updateDisplay()
    }

    func operatorPressed(_ op: String) {
        if operation != nil { calculate() }
        previousInput = currentInput
        operation = op
        shouldResetDisplay = true
        updateDisplay()
    }

    func calculate() {
        guard let op = operation, !shouldResetDisplay else { return }
        guard let prev = Double(previousInput),
              let curr = Double(currentInput) else { return }

        var result: Double
        switch op {
        case "+": result = prev + curr
        case "-": result = prev - curr
        case "*": result = prev * curr
        case "/":
            guard curr != 0 else {
                currentInput = "Err"
                operation = nil
                previousInput = ""
                shouldResetDisplay = true
                updateDisplay()
                return
            }
            result = prev / curr
        default: return
        }

        let rounded = (result * 100_000_000).rounded() / 100_000_000
        if rounded.truncatingRemainder(dividingBy: 1) == 0 && abs(rounded) < 1e15 {
            currentInput = String(Int(rounded))
        } else {
            currentInput = String(rounded)
        }
        operation = nil
        previousInput = ""
        shouldResetDisplay = true
        updateDisplay()
    }

    func clear() {
        currentInput = "0"
        previousInput = ""
        operation = nil
        updateDisplay()
    }

    func delete() {
        if currentInput.count == 1 || currentInput == "Err" {
            currentInput = "0"
        } else {
            currentInput = String(currentInput.dropLast())
        }
        updateDisplay()
    }

    func decimal() {
        if shouldResetDisplay {
            currentInput = "0."
            shouldResetDisplay = false
        } else if !currentInput.contains(".") {
            currentInput += "."
        }
        updateDisplay()
    }

    func percent() {
        guard let val = Double(currentInput) else { return }
        let result = val / 100
        if result.truncatingRemainder(dividingBy: 1) == 0 && abs(result) < 1e15 {
            currentInput = String(Int(result))
        } else {
            currentInput = String(result)
        }
        updateDisplay()
    }

    private func updateDisplay() {
        if currentInput.count > 9, let val = Double(currentInput) {
            displayText = String(format: "%.4e", val)
        } else {
            displayText = currentInput
        }

        if let op = operation {
            let symbol: String
            switch op {
            case "/": symbol = "÷"
            case "*": symbol = "×"
            default: symbol = op
            }
            historyText = "\(previousInput) \(symbol)"
        } else {
            historyText = ""
        }
    }
}

// MARK: - Button Style

struct ScrapbookPress: ButtonStyle {
    var shadowColor: Color = .calcInk
    var shadowOffset: CGFloat = 4
    var pressTravel: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(
                color: shadowColor,
                radius: 0,
                x: configuration.isPressed ? shadowOffset - pressTravel : shadowOffset,
                y: configuration.isPressed ? shadowOffset - pressTravel : shadowOffset
            )
            .offset(
                x: configuration.isPressed ? pressTravel : 0,
                y: configuration.isPressed ? pressTravel : 0
            )
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Custom Shapes

struct StarBurst: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(to: CGPoint(x: w, y: h * 0.5),
                    control1: CGPoint(x: w * 0.5, y: h * 0.3),
                    control2: CGPoint(x: w * 0.7, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                    control1: CGPoint(x: w * 0.7, y: h * 0.5),
                    control2: CGPoint(x: w * 0.5, y: h * 0.7))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.5),
                    control1: CGPoint(x: w * 0.5, y: h * 0.7),
                    control2: CGPoint(x: w * 0.3, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                    control1: CGPoint(x: w * 0.3, y: h * 0.5),
                    control2: CGPoint(x: w * 0.5, y: h * 0.3))
        return p
    }
}

struct WaveLine: Shape {
    var inverted = false
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, midY = h / 2
        p.move(to: CGPoint(x: 0, y: midY))
        let segW = w / 4
        for i in 0..<4 {
            let sx = CGFloat(i) * segW
            let up = inverted ? (i % 2 != 0) : (i % 2 == 0)
            let ctrlY: CGFloat = up ? 0 : h
            p.addQuadCurve(
                to: CGPoint(x: sx + segW, y: midY),
                control: CGPoint(x: sx + segW / 2, y: ctrlY))
        }
        return p
    }
}

// MARK: - Background Doodles

struct BackgroundDoodles: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height

            StarBurst()
                .fill(.white)
                .overlay(StarBurst().stroke(Color.calcInk, lineWidth: 2))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-15))
                .position(x: w * 0.08, y: h * 0.10)

            StarBurst()
                .fill(Color.calcYellow)
                .overlay(StarBurst().stroke(Color.calcInk, lineWidth: 2))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(20))
                .position(x: w * 0.92, y: h * 0.85)

            WaveLine()
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 110, height: 25)
                .rotationEffect(.degrees(-30))
                .position(x: w * 0.93, y: h * 0.18)

            WaveLine()
                .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 110, height: 25)
                .rotationEffect(.degrees(-30))
                .offset(y: 12)
                .position(x: w * 0.93, y: h * 0.18)

            WaveLine(inverted: true)
                .stroke(Color.calcYellow, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 90, height: 22)
                .rotationEffect(.degrees(15))
                .position(x: w * 0.06, y: h * 0.90)

            Text("Maths!")
                .font(.custom("Noteworthy-Bold", size: 26))
                .foregroundColor(.calcYellow)
                .shadow(color: .calcInk, radius: 0, x: 2, y: 2)
                .rotationEffect(.degrees(-10))
                .position(x: w * 0.14, y: h * 0.25)

            Text("HEI!")
                .font(.custom("Noteworthy-Bold", size: 30))
                .foregroundColor(.white)
                .shadow(color: .calcInk, radius: 0, x: 2, y: 2)
                .rotationEffect(.degrees(15))
                .position(x: w * 0.88, y: h * 0.75)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Smiley Doodle

struct SmileyDoodle: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            var face = Path()
            face.addEllipse(in: CGRect(x: w * 0.1, y: h * 0.1, width: w * 0.8, height: h * 0.8))
            ctx.stroke(face, with: .color(.calcYellow), lineWidth: 3)

            var leftEye = Path()
            leftEye.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.30, width: w * 0.1, height: h * 0.1))
            ctx.fill(leftEye, with: .color(.calcYellow))

            var rightEye = Path()
            rightEye.addEllipse(in: CGRect(x: w * 0.58, y: h * 0.30, width: w * 0.1, height: h * 0.1))
            ctx.fill(rightEye, with: .color(.calcYellow))

            var smile = Path()
            smile.move(to: CGPoint(x: w * 0.28, y: h * 0.6))
            smile.addQuadCurve(
                to: CGPoint(x: w * 0.72, y: h * 0.6),
                control: CGPoint(x: w * 0.5, y: h * 0.88))
            ctx.stroke(smile, with: .color(.calcYellow), lineWidth: 3)

            var tongue = Path()
            tongue.move(to: CGPoint(x: w * 0.42, y: h * 0.68))
            tongue.addQuadCurve(
                to: CGPoint(x: w * 0.58, y: h * 0.68),
                control: CGPoint(x: w * 0.50, y: h * 0.82))
            tongue.closeSubpath()
            ctx.fill(tongue, with: .color(.calcRed))
            ctx.stroke(tongue, with: .color(.calcYellow), lineWidth: 1)
        }
        .frame(width: 42, height: 42)
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }
}

// MARK: - Arrow Doodle

struct ArrowDoodle: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let style = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)

            var line = Path()
            line.move(to: CGPoint(x: w * 0.2, y: h * 0.8))
            line.addQuadCurve(
                to: CGPoint(x: w * 0.8, y: h * 0.2),
                control: CGPoint(x: w * 0.5, y: h * 0.15))
            ctx.stroke(line, with: .color(.calcRed), style: style)

            var head = Path()
            head.move(to: CGPoint(x: w * 0.6, y: h * 0.2))
            head.addLine(to: CGPoint(x: w * 0.8, y: h * 0.2))
            head.addLine(to: CGPoint(x: w * 0.9, y: h * 0.42))
            ctx.stroke(head, with: .color(.calcRed), style: style)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Title

struct CalcTitle: View {
    private let letters: [(String, Color, Color, String, Double, CGFloat)] = [
        ("C", .calcRed, .white, "AmericanTypewriter-Bold", -8, 5),
        ("A", .calcPaper, .calcInk, "Chalkduster", 5, 0),
        ("L", .calcBlue, .white, "AmericanTypewriter-Bold", -3, 0),
        ("C", .calcYellow, .calcInk, "MarkerFelt-Wide", 10, -2),
    ]

    var body: some View {
        HStack(spacing: -3) {
            ForEach(Array(letters.enumerated()), id: \.offset) { idx, l in
                Text(l.0)
                    .font(.custom(l.3, size: 28))
                    .foregroundColor(l.2)
                    .frame(width: 44, height: 44)
                    .background(l.1)
                    .clipShape(RoundedRectangle(cornerRadius: idx == 3 ? 5 : 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: idx == 3 ? 5 : 0)
                            .stroke(Color.calcInk, lineWidth: 2)
                    )
                    .shadow(color: .calcInk, radius: 0, x: 4, y: 4)
                    .rotationEffect(.degrees(l.4))
                    .offset(y: l.5)
            }
        }
        .padding(.bottom, 14)
        .padding(.top, 6)
    }
}

// MARK: - Tape Strip

struct TapeStrip: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(.white.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(.black.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}

// MARK: - Display Screen

struct DisplayScreen: View {
    let displayText: String
    let historyText: String

    var body: some View {
        ZStack {
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: 2, bottomLeadingRadius: 10,
                bottomTrailingRadius: 3, topTrailingRadius: 15)

            shape.fill(.white)
                .overlay(linedPaperLines.clipShape(shape))
                .overlay(shape.strokeBorder(Color.calcInk, lineWidth: 3))
                .shadow(color: .calcInk, radius: 0, x: 4, y: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text(historyText)
                    .font(.custom("Noteworthy-Bold", size: 18))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(minHeight: 22)

                Text(displayText)
                    .font(.custom("MarkerFelt-Wide", size: 48))
                    .foregroundColor(.calcInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .fixedSize(horizontal: false, vertical: true)
        .rotationEffect(.degrees(-1))
        .overlay(
            TapeStrip()
                .frame(width: 55, height: 22)
                .rotationEffect(.degrees(-5))
                .offset(x: -30, y: -10),
            alignment: .top
        )
        .overlay(
            TapeStrip()
                .frame(width: 60, height: 18)
                .rotationEffect(.degrees(15))
                .offset(x: 15, y: 8),
            alignment: .bottomTrailing
        )
        .padding(.bottom, 18)
    }

    private var linedPaperLines: some View {
        Canvas { ctx, size in
            var y: CGFloat = 20
            while y < size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(line, with: .color(.calcBlue.opacity(0.18)), lineWidth: 1)
                y += 20
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var engine = CalculatorEngine()
    @State private var floatPhase = false

    private let sp: CGFloat = 10
    private let btnH: CGFloat = 55

    var body: some View {
        ZStack {
            Color.calcBg.ignoresSafeArea()
            BackgroundDoodles()
            calculatorCard
                .offset(y: floatPhase ? -5 : 0)
                .rotationEffect(.degrees(floatPhase ? 1 : 0))
        }
        .onAppear { floatPhase = true }
        .animation(
            .easeInOut(duration: 3).repeatForever(autoreverses: true),
            value: floatPhase)
    }

    // MARK: - Calculator Card

    private var calculatorCard: some View {
        VStack(spacing: 0) {
            CalcTitle()
            DisplayScreen(displayText: engine.displayText, historyText: engine.historyText)
            keypadView
        }
        .padding(20)
        .background(cardBackground)
        .overlay(
            SmileyDoodle()
                .rotationEffect(.degrees(-20))
                .offset(x: -12, y: 80),
            alignment: .bottomLeading
        )
        .overlay(
            ArrowDoodle()
                .rotationEffect(.degrees(45))
                .offset(x: 20, y: -5),
            alignment: .topTrailing
        )
        .frame(maxWidth: 380)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.45), radius: 1, x: 5, y: 5)
    }

    private var cardBackground: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 30, bottomLeadingRadius: 30,
            bottomTrailingRadius: 20, topTrailingRadius: 40)
        let outerShape = UnevenRoundedRectangle(
            topLeadingRadius: 34, bottomLeadingRadius: 34,
            bottomTrailingRadius: 24, topTrailingRadius: 44)

        return ZStack {
            shape.fill(Color.calcPaper)
            shape.strokeBorder(.white, lineWidth: 8)
            outerShape.stroke(Color.calcInk, lineWidth: 4).padding(-6)
        }
    }

    // MARK: - Keypad Layout

    private var keypadView: some View {
        GeometryReader { geo in
            let colW = (geo.size.width - sp * 3) / 4
            let dblW = colW * 2 + sp

            VStack(spacing: sp) {
                row1(colW: colW)
                row2(colW: colW)
                row3(colW: colW)
                rows45(colW: colW, dblW: dblW)
                equalsRow(dblW: dblW)
            }
        }
        .frame(height: btnH * 6 + sp * 5)
    }

    // MARK: Row Builders

    private func row1(colW: CGFloat) -> some View {
        HStack(spacing: sp) {
            acButton(w: colW)
            auxBtn("del", bg: .white, w: colW, rot: 4, fontSize: 18) { engine.delete() }
            auxBtn("%", bg: .calcPaper, w: colW, rot: -3) { engine.percent() }
            opBtn("÷", color: .calcBlue, w: colW, rot: 5,
                  r: (10, 5, 2, 15)) { engine.operatorPressed("/") }
        }
    }

    private func row2(colW: CGFloat) -> some View {
        HStack(spacing: sp) {
            numBtn("7", w: colW, rot: -3)
            numBtn("8", w: colW, rot: 4, paper: true)
            numBtn("9", w: colW, rot: -2)
            opBtn("×", color: .calcRed, w: colW, rot: -4,
                  r: (5, 15, 10, 2)) { engine.operatorPressed("*") }
        }
    }

    private func row3(colW: CGFloat) -> some View {
        HStack(spacing: sp) {
            numBtn("4", w: colW, rot: 3, paper: true)
            numBtn("5", w: colW, rot: -4)
            numBtn("6", w: colW, rot: 2)
            opBtn("−", color: .calcYellow, fg: .calcInk, w: colW, rot: 3,
                  r: (15, 2, 5, 10)) { engine.operatorPressed("-") }
        }
    }

    private func rows45(colW: CGFloat, dblW: CGFloat) -> some View {
        HStack(alignment: .top, spacing: sp) {
            VStack(spacing: sp) {
                HStack(spacing: sp) {
                    numBtn("1", w: colW, rot: -3)
                    numBtn("2", w: colW, rot: 4)
                    numBtn("3", w: colW, rot: -2, paper: true)
                }
                HStack(spacing: sp) {
                    numBtn("0", w: dblW, rot: -1)
                    dotButton(w: colW)
                }
            }
            plusButton(w: colW)
        }
    }

    private func equalsRow(dblW: CGFloat) -> some View {
        HStack {
            equalsButton(w: dblW)
            Spacer()
        }
    }

    // MARK: - Number Button

    private func numBtn(_ label: String, w: CGFloat, rot: Double, paper: Bool = false) -> some View {
        let shape = blobShape(label)
        let bg: Color = paper ? .calcPaper : .white
        return Button { engine.numberPressed(label) } label: {
            Text(label)
                .font(.custom("MarkerFelt-Wide", size: 24))
                .foregroundColor(.calcInk)
                .frame(width: w, height: btnH)
                .background(shape.fill(bg))
                .clipShape(shape)
                .overlay(shape.stroke(Color.calcInk, lineWidth: 3))
        }
        .rotationEffect(.degrees(rot))
        .buttonStyle(ScrapbookPress())
    }

    private func blobShape(_ label: String) -> UnevenRoundedRectangle {
        switch label {
        case "0":
            return UnevenRoundedRectangle(
                topLeadingRadius: 30, bottomLeadingRadius: 15,
                bottomTrailingRadius: 22, topTrailingRadius: 8)
        case "1", "7":
            return UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 28,
                bottomTrailingRadius: 15, topTrailingRadius: 22)
        case "2", "8":
            return UnevenRoundedRectangle(
                topLeadingRadius: 28, bottomLeadingRadius: 15,
                bottomTrailingRadius: 22, topTrailingRadius: 18)
        case "3", "9":
            return UnevenRoundedRectangle(
                topLeadingRadius: 15, bottomLeadingRadius: 22,
                bottomTrailingRadius: 28, topTrailingRadius: 20)
        case "4":
            return UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 18,
                bottomTrailingRadius: 25, topTrailingRadius: 15)
        case "5":
            return UnevenRoundedRectangle(
                topLeadingRadius: 18, bottomLeadingRadius: 25,
                bottomTrailingRadius: 15, topTrailingRadius: 22)
        case "6":
            return UnevenRoundedRectangle(
                topLeadingRadius: 25, bottomLeadingRadius: 15,
                bottomTrailingRadius: 22, topTrailingRadius: 28)
        default:
            return UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 18,
                bottomTrailingRadius: 22, topTrailingRadius: 18)
        }
    }

    // MARK: - Aux Button (del, %)

    private func auxBtn(
        _ label: String, bg: Color, w: CGFloat, rot: Double,
        fontSize: CGFloat = 22, action: @escaping () -> Void
    ) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 18, bottomLeadingRadius: 22,
            bottomTrailingRadius: 16, topTrailingRadius: 24)
        return Button(action: action) {
            Text(label)
                .font(.custom("MarkerFelt-Wide", size: fontSize))
                .foregroundColor(.calcInk)
                .frame(width: w, height: btnH)
                .background(shape.fill(bg))
                .clipShape(shape)
                .overlay(shape.stroke(Color.calcInk, lineWidth: 3))
        }
        .rotationEffect(.degrees(rot))
        .buttonStyle(ScrapbookPress())
    }

    // MARK: - Operator Button

    private func opBtn(
        _ label: String, color: Color, fg: Color = .white,
        w: CGFloat, rot: Double,
        r: (CGFloat, CGFloat, CGFloat, CGFloat),
        action: @escaping () -> Void
    ) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: r.0, bottomLeadingRadius: r.2,
            bottomTrailingRadius: r.3, topTrailingRadius: r.1)
        return Button(action: action) {
            Text(label)
                .font(.custom("AmericanTypewriter-Bold", size: 26))
                .foregroundColor(fg)
                .frame(width: w, height: btnH)
                .background(shape.fill(color))
                .clipShape(shape)
                .overlay(shape.stroke(Color.calcInk, lineWidth: 3))
        }
        .rotationEffect(.degrees(rot))
        .buttonStyle(ScrapbookPress())
    }

    // MARK: - AC Button

    private func acButton(w: CGFloat) -> some View {
        Button { engine.clear() } label: {
            Text("AC")
                .font(.custom("MarkerFelt-Wide", size: 18))
                .foregroundColor(.white)
                .frame(width: w, height: btnH)
                .background(Capsule().fill(Color.calcInk))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 3))
        }
        .rotationEffect(.degrees(-10))
        .buttonStyle(ScrapbookPress())
    }

    // MARK: - Decimal Button

    private func dotButton(w: CGFloat) -> some View {
        Button { engine.decimal() } label: {
            Text(".")
                .font(.custom("MarkerFelt-Wide", size: 30))
                .foregroundColor(.calcInk)
                .frame(width: w * 0.82, height: btnH * 0.82)
                .background(Circle().fill(.white))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.calcInk, lineWidth: 3))
        }
        .rotationEffect(.degrees(15))
        .buttonStyle(ScrapbookPress())
    }

    // MARK: - Plus Button (tall, spans 2 rows)

    private func plusButton(w: CGFloat) -> some View {
        let tallH = btnH * 2 + sp
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 2, bottomLeadingRadius: 5,
            bottomTrailingRadius: 15, topTrailingRadius: 10)
        return Button { engine.operatorPressed("+") } label: {
            Text("+")
                .font(.custom("AmericanTypewriter-Bold", size: 30))
                .foregroundColor(.white)
                .frame(width: w, height: tallH)
                .background(shape.fill(Color.calcBlue))
                .clipShape(shape)
                .overlay(shape.stroke(Color.calcInk, lineWidth: 3))
        }
        .rotationEffect(.degrees(-2))
        .buttonStyle(ScrapbookPress())
    }

    // MARK: - Equals Button (double-ring)

    private func equalsButton(w: CGFloat) -> some View {
        Button { engine.calculate() } label: {
            Text("=")
                .font(.custom("AmericanTypewriter-Bold", size: 30))
                .foregroundColor(.white)
                .frame(width: w, height: btnH)
                .background(Capsule().fill(Color.calcRed))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 3))
                .padding(3)
                .background(Capsule().fill(Color.calcInk))
                .clipShape(Capsule())
        }
        .rotationEffect(.degrees(1))
        .buttonStyle(ScrapbookPress(
            shadowColor: .black.opacity(0.85),
            shadowOffset: 6,
            pressTravel: 4))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
