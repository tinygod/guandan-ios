import Foundation
import GuandanCore

// Self-play laboratory: pit two bot configurations against each other over
// many matches and report win rates + play statistics.
//
//   swift run -c release guandan-lab <matches> <nsDiff>:<nsStyle> <ewDiff>:<ewStyle>
//   e.g. swift run -c release guandan-lab 100 hard:balanced normal:balanced

func parseBot(_ s: String) -> (BotDifficulty, BotStyle) {
    let parts = s.split(separator: ":").map(String.init)
    let d = BotDifficulty(rawValue: parts[0]) ?? .normal
    let st = parts.count > 1 ? (BotStyle(rawValue: parts[1]) ?? .balanced) : .balanced
    return (d, st)
}

let args = CommandLine.arguments
let matches = args.count > 1 ? Int(args[1]) ?? 50 : 50
let nsCfg = args.count > 2 ? parseBot(args[2]) : (.hard, .balanced)
let ewCfg = args.count > 3 ? parseBot(args[3]) : (.normal, .balanced)

print("LAB: \(matches) matches — NS=\(nsCfg.0.rawValue):\(nsCfg.1.rawValue) vs EW=\(ewCfg.0.rawValue):\(ewCfg.1.rawValue)")

var nsWins = 0, ewWins = 0
var totalHands = 0
var winnerMoves: [Int] = []
var bombsPerHand: [Int] = []

for m in 0..<matches {
    var match = MatchSession()
    var previous: [Seat]? = nil
    let bots: [Seat: any Bot] = [
        .south: HeuristicBot(difficulty: nsCfg.0, style: nsCfg.1),
        .north: HeuristicBot(difficulty: nsCfg.0, style: nsCfg.1),
        .east: HeuristicBot(difficulty: ewCfg.0, style: ewCfg.1),
        .west: HeuristicBot(difficulty: ewCfg.0, style: ewCfg.1),
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
