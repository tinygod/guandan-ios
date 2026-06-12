import Foundation
import GuandanCore

// Self-play laboratory: pit two bot configurations against each other over
// many matches and report win rates + play statistics.
//
//   swift run -c release guandan-lab <matches> <nsDiff>:<nsStyle> <ewDiff>:<ewStyle>
//   e.g. swift run -c release guandan-lab 100 hard:balanced normal:balanced

func parseBot(_ s: String) -> any Bot {
    let parts = s.split(separator: ":").map(String.init)
    if parts[0] == "search" {
        return SearchBot(rollouts: parts.count > 1 ? Int(parts[1]) ?? 8 : 8)
    }
    let d = BotDifficulty(rawValue: parts[0]) ?? .normal
    let st = parts.count > 1 ? (BotStyle(rawValue: parts[1]) ?? .balanced) : .balanced
    return HeuristicBot(difficulty: d, style: st)
}

let args = CommandLine.arguments
let matches = args.count > 1 ? Int(args[1]) ?? 50 : 50
let nsName = args.count > 2 ? args[2] : "hard:balanced"
let ewName = args.count > 3 ? args[3] : "normal:balanced"
let nsBot = parseBot(nsName)
let ewBot = parseBot(ewName)

print("LAB: \(matches) matches — NS=\(nsName) vs EW=\(ewName)")

var nsWins = 0, ewWins = 0
var totalHands = 0
var winnerMoves: [Int] = []
var bombsPerHand: [Int] = []

for m in 0..<matches {
    var match = MatchSession()
    var previous: [Seat]? = nil
    let bots: [Seat: any Bot] = [
        .south: nsBot, .north: nsBot,
        .east: ewBot, .west: ewBot,
    ]
    var hands = 0
    while match.matchWinner == nil && hands < 200 {
        hands += 1
        guard let result = try? MatchRunner.playBotHand(
            seed: UInt64(m * 100_000 + hands * 17), level: match.activeLevel,
            previousFinishOrder: previous, bots: bots) else { break }
        match.recordHand(finishOrder: result.finishOrder)
        previous = result.finishOrder
        totalHands += 1
    }
    if match.matchWinner == .northSouth { nsWins += 1 }
    if match.matchWinner == .eastWest { ewWins += 1 }
    if (m + 1) % 20 == 0 {
        print("  \(m + 1)/\(matches)  NS \(nsWins) – \(ewWins) EW")
    }
}

let decided = nsWins + ewWins
print("""
RESULT
  NS wins: \(nsWins) (\(String(format: "%.1f", 100.0 * Double(nsWins) / Double(max(decided, 1))))%)
  EW wins: \(ewWins)
  avg hands/match: \(String(format: "%.1f", Double(totalHands) / Double(matches)))
""")
