//
//  PrompterTextSplitter.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// splits script text into renderable lines, preserving blank lines between paragraphs.
/// pure and stateless, so it is usable from any isolation context.
nonisolated enum PrompterTextSplitter {
    /// the script text split on newlines, keeping empty lines as "" entries so paragraph
    /// spacing is preserved. line breaks are normalized via the shared ScriptTextCore policy
    /// (\r\n and lone \r become \n). empty input returns [].
    static func lines(from text: String) -> [String] {
        guard !text.isEmpty else {
            return []
        }
        return ScriptTextCore.normalizeLineBreaks(text).components(separatedBy: "\n")
    }
}
