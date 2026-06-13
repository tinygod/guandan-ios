import Foundation

/// All user-facing data strings route through here. The ENGLISH source text
/// is the catalog key, so untranslated strings gracefully fall back to
/// English. UI literals in SwiftUI Text("...") localize automatically via
/// the same catalog.
func tr(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
