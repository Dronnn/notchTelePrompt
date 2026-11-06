//
//  AppWindowFrameCalculator.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// finds a nearby clear position while keeping the entire window inside the usable screen.
nonisolated enum AppWindowFrameCalculator {
    static let gap: CGFloat = 12

    static func frame(preferred: CGRect, visibleFrame: CGRect, avoiding occupied: [CGRect]) -> CGRect {
        guard !visibleFrame.isEmpty else {
            return preferred
        }
        let size = CGSize(
            width: min(preferred.width, visibleFrame.width),
            height: min(preferred.height, visibleFrame.height)
        )
        let occupied = occupied.filter { $0.intersects(visibleFrame) }
        let obstacles = occupied.map { $0.insetBy(dx: -gap, dy: -gap) }
        let positionsX = [preferred.minX, visibleFrame.minX, visibleFrame.maxX - size.width]
            + obstacles.flatMap { [$0.minX - size.width, $0.maxX] }
        let positionsY = [preferred.minY, visibleFrame.minY, visibleFrame.maxY - size.height]
            + obstacles.flatMap { [$0.minY - size.height, $0.maxY] }
        var best = CGRect(origin: preferred.origin, size: size)
        var bestScore = [CGFloat.infinity]
        for x in positionsX {
            for y in positionsY {
                let candidate = CGRect(
                    x: min(max(x, visibleFrame.minX), visibleFrame.maxX - size.width),
                    y: min(max(y, visibleFrame.minY), visibleFrame.maxY - size.height),
                    width: size.width,
                    height: size.height
                )
                let dx = candidate.minX - preferred.minX
                let dy = candidate.minY - preferred.minY
                let score = [
                    overlapArea(candidate, with: occupied),
                    overlapArea(candidate, with: obstacles),
                    dx * dx + dy * dy
                ]
                if score.lexicographicallyPrecedes(bestScore) {
                    best = candidate
                    bestScore = score
                }
            }
        }
        return best
    }

    static func makingRoom(
        for preferred: CGRect,
        moving existing: CGRect,
        in visibleFrame: CGRect,
        avoiding fixed: [CGRect]
    ) -> (existing: CGRect, opening: CGRect)? {
        for x in [visibleFrame.minX, visibleFrame.maxX - existing.width] {
            for y in [visibleFrame.minY, visibleFrame.maxY - existing.height] {
                let moved = frame(
                    preferred: CGRect(origin: CGPoint(x: x, y: y), size: existing.size),
                    visibleFrame: visibleFrame,
                    avoiding: fixed
                )
                guard !fixed.contains(where: { $0.intersects(moved) }) else { continue }
                let opening = frame(preferred: preferred, visibleFrame: visibleFrame, avoiding: fixed + [moved])
                guard !(fixed + [moved]).contains(where: { $0.intersects(opening) }) else { continue }
                return (existing: moved, opening: opening)
            }
        }
        return nil
    }

    private static func overlapArea(_ frame: CGRect, with occupied: [CGRect]) -> CGFloat {
        occupied.reduce(CGFloat.zero) { area, obstacle in
            let intersection = frame.intersection(obstacle)
            return area + (intersection.isNull ? 0 : intersection.width * intersection.height)
        }
    }
}
