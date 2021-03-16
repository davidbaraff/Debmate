//
//  Hbv.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import CoreGraphics

public struct Range2d {
    public let min: CGPoint
    public let max: CGPoint
    
    public var size: CGSize {
        CGSize(max.x - min.x, max.y - min.y)
    }

    public var cgRect: CGRect {
        CGRect(origin: min, size: size)
    }

    init() {
        min = .zero
        max = .zero
    }

    public init(cgRect: CGRect) {
        min = cgRect.origin
        max = CGPoint(cgRect.origin.x + cgRect.size.width,
                      cgRect.origin.y + cgRect.size.height)
    }

    public init(min: CGPoint, max: CGPoint) {
        self.min = min
        self.max = max
    }

    public func union(with r: Range2d) -> Range2d {
        return Range2d(min: CGPoint(Swift.min(r.min.x, min.x), Swift.min(r.min.y, min.y)),
                       max: CGPoint(Swift.max(r.max.x, max.x), Swift.max(r.max.y, max.y)))
    }
    
    public func isOutside(of range: Range2d) -> Bool {
        return range.max.x < min.x || range.max.y < min.y ||
               max.x < range.min.x || max.y < range.min.y
    }
    
    public func contains(point: CGPoint) -> Bool {
        return min.x < point.x && max.x > point.x &&
               min.y < point.y && max.y > point.y
    }
}

extension CGRect {
    var max: CGPoint { CGPoint(origin.x + size.width, origin.y + size.height) }
    var min: CGPoint { origin }
}

extension CGPoint {
    func coord(_ axis: Int) -> CGFloat {
        return axis == 0 ? x : y
    }
}



/// 2-D Hierarchical Bounding Volume
public class Hbv {
    // MARK: - Public API

    /// Tree root
    public private(set) var root = HbvNode(contents: .nonleaf([]))
    
    /// Depth of current tree.
    public private(set) var nlevels = 0

    
    /// The array of rectangles used to form the tree.
    ///
    /// Leaf nodes of the tree have an index which corresponds with
    /// the rectangle stored in this array.
    public private(set) var rects = [CGRect]()

    /// The parents of all leaf nodes.
    public internal(set) var leafParents = [HbvNode]()
    
    
    /// Construct an empty hierarchy.
    public init() {
    }
        
    /// Construct a hierarchy for a given set of rectangles.
    public init(rects: [CGRect]) {
        self.update(rects: rects)
    }
    
    /// Update the bounds for the tree
    /// - Parameter rects: array of rectangles.
    ///
    /// If rects length doesn't match the passed in rects,
    /// a new tree is formed (which is expensive, relatively speaking).
    public func update(rects: [CGRect]) {
        if self.rects.count != rects.count {
            (self.root, self.nlevels, self.leafParents) = Self.build(rects: rects)
            // _ = allNodeDepths()
        }

        self.rects = rects

        // update range for all bottom nodes
        for bottomNode in leafParents {
            if case let .nonleaf(children) = bottomNode.contents {
                for (index, child) in children.enumerated() {
                    if let childIndex = child.leafIndex {
                        let childRange = Range2d(cgRect: rects[childIndex])
                        child.range = childRange
                        bottomNode.range = (index == 0) ? childRange : bottomNode.range.union(with: childRange)
                    }
                }
            }
        }

        root.update(ranges: rects.map { Range2d(cgRect: $0) })
    }

    // For debugging.
    public func nodes(atLevel level: Int) -> [HbvNode] {
        var r = [HbvNode]()
        root.gatherNodes(atLevel: level, curLevel: 0, result: &r)
        return r
    }
    
    /// Find intersections of rect with all leaf nodes of the tree
    /// - Parameters:
    ///   - rect: area of interest
    ///   - callback: callback for each leaf intersecting rect
    public func findLeafIntersections(rect: CGRect, callback: (Int) -> ()) {
        return root.findIntersections(range: Range2d(cgRect: rect), callback: callback)
    }
    
    /// Find intersections of rect with nodes of the tree.
    /// - Parameters:
    ///   - rect: area of interest
    ///   - callback: callback for each node intersecting rect
    ///
    /// Note that whenever the callback function returns true for a node,
    /// then findIntersections will recurse through the node's children.
    /// Return false halts the walk at a node.
    public func findIntersections(rect: CGRect, callback: (HbvNode) -> Bool) {
        root.findIntersections(range: Range2d(cgRect: rect), callback: callback)
    }
    
    // For debugging.
    func allNodeDepths() -> [Int] {
        var depths = [Int]()
        root.findDepths(depths: &depths, depth: 0)
        let avg = Double(depths.reduce(0, +)) / Double(depths.count)

        print("Got back \(depths.count) depths, avg = \(avg)")
        return depths
    }

    // MARK: - Private
    
    private static func build(rects: [CGRect]) -> (HbvNode, Int, [HbvNode]) {
        let bt = BoxTree(rects: rects)

        var fewest = 2000000
        var most = 0
        var leafParents = [HbvNode]()
        
        _ = bt.makeGroup(lim: 2, fewest: &fewest, most: &most, level: 0)
        let (root, nlevels) = HbvNode.buildTree(boxTree: bt, leafParents: &leafParents)

        // print("Build complete: \(nlevels) levels, fewest = \(fewest), most = \(most), \(root.nodeCount()) nodes")
        return (root, nlevels, leafParents)
    }
}

/// Tree structure used by Hbv.
public class HbvNode : ClassIdentityBase {
    // MARK: - Public API
    
    /// Each node is either a leaf or an internal (nonleaf) node with children.
    public enum Contents {
        case leaf (Int)
        case nonleaf ([HbvNode])
    }
    
    /// The contents of the node.
    public internal (set) var contents: Contents

    /// The bounding box for all the children of this node.
    /// For a leaf, the range is the same as the matching rect stored
    /// by the Hbv which constructed this node.
    public internal (set) var range = Range2d()
    
    /// The bounding box as a CGRect.
    public var cgRect: CGRect { range.cgRect }

    /// The parent of this node.
    public weak var parent: HbvNode?
    
    /// Per-node mutable user data as needed.
    public var userData: Any?
    
    /// The index of a node if it is a leaf.
    ///
    /// The index can be used to access the rects array store by the Hbv
    /// structure which holds this tree.
    public var leafIndex: Int? {
        if case .leaf(let n) = contents {
            return n
        }
        return nil
    }
    
    /// True if this node is a leaf.
    public var isLeaf: Bool {
        if case .leaf = contents {
            return true
        }
        return false
    }
    
    /// The children of a node if it is not a leaf.
    public var children: [HbvNode]? {
        if case .nonleaf(let children) = contents {
            return children
        }
        return nil
    }

    /// Computes the number of nodes in the tree.
    /// - Returns: total node count for the tree.
    public func nodeCount() -> Int {
        switch contents {
        case .leaf:
            return 1
        case .nonleaf(let children):
            return children.reduce(1) { $0 + $1.nodeCount() }
        }
    }
    
    
    /// Runs a callback for each leaf containing point.
    /// - Parameters:
    ///   - point: point in space
    ///   - callback: callback to be run
    public func findLeafIndicesContaining(point: CGPoint, callback: (Int) ->()) {
        guard range.contains(point: point) else {
            return
        }

        switch contents {
        case .leaf(let index):
            callback(index)
        case .nonleaf(let children):
            for child in children {
                child.findLeafIndicesContaining(point: point, callback: callback)
            }
        }
    }

    public func findLeavesContaining(point: CGPoint, callback: (HbvNode) ->()) {
        guard range.contains(point: point) else {
            return
        }

        switch contents {
        case .leaf:
            callback(self)
        case .nonleaf(let children):
            for child in children {
                child.findLeavesContaining(point: point, callback: callback)
            }
        }
    }

    /// Return the lowest ancestor matching a predicate.
    /// - Parameter predicate: predicate function
    /// - Returns: The closest ancestor matching predicate, or nil.
    public func closestAncestor(where predicate: (HbvNode) -> (Bool)) -> HbvNode? {
        var curNode = self
        while let p = curNode.parent {
            if predicate(p) {
                return p
            }
            curNode = p
        }
        return nil
    }
    
    /// Run a callback on every leaf node of the tree.
    /// - Parameter callback: callback to be run.
    /// The callback is passed the node and its index.
    public func findLeafNodes(callback: (HbvNode, Int) -> ()) {
        switch contents {
        case .leaf(let index):
            callback(self, index)
        case .nonleaf(let children):
            for child in children {
                child.findLeafNodes(callback: callback)
            }
        }
    }

    /// Run a callback on every "terminal" node of the tree.
    /// - Parameter stoppingWhen: callback that returns true for terminal nodes.
    /// - Parameter callback: callback to be run on each terminal node.
    public func findTerminalNodes(isTerminal: (HbvNode) -> (Bool), callback: (HbvNode) -> ()) {
        if isTerminal(self) {
            callback(self)
            return
        }

        if case .nonleaf(let children) = contents {
            for child in children {
                child.findTerminalNodes(isTerminal: isTerminal, callback: callback)
            }
        }
    }

    /// Run a callback on every node of the tree.
    /// - Parameter callback: callback to be run.
    public func findNodes(callback: (HbvNode) -> ()) {
        callback(self)
        if let children = children {
            for child in children {
                child.findNodes(callback: callback)
            }
        }
    }
    
    /// Run a callback on every node of the tree.
    /// - Parameter callback: callback to be run.
    /// If callback returns false, the search does not
    /// descend past that node.
    public func walk(callback: (HbvNode) -> (Bool)) {
        if !callback(self) {
            return
        }
        if let children = children {
            for child in children {
                child.walk(callback: callback)
            }
        }
    }

    /// Run a callback on ancestors of a node.
    /// - Parameters:
    ///   - includeSelf: If the callback should be invoked on self.
    ///   - callback: Callback to be run on ancestors.
    ///
    /// The callback is invoked until the root is reached or the callback returns false.
    /// If includeSelf is true (the default) the callback is run on the node the
    /// walk is started from.
    public func walkUp(includeSelf: Bool = true, callback: (HbvNode) -> (Bool)) {
        var curNode: HbvNode? = includeSelf ? self : parent
        while let node = curNode,
              callback(node) {
            curNode = node.parent
        }
    }

    /// Run a callback on ancestors of a node.
    /// - Parameters:
    ///   - includeSelf: If the callback should be invoked on self.
    ///   - callback: Callback to be run on ancestors.
    ///
    /// The callback is invoked until the root is reached.
    public func walkToRoot(includeSelf: Bool = true, callback: (HbvNode) -> ()) {
        var curNode: HbvNode? = includeSelf ? self : parent
        while let node = curNode {
            callback(node)
            curNode = node.parent
        }
    }

    // MARK: - Private

    init(contents: Contents) {
         self.contents = contents
         super.init()
         if case let .nonleaf(children) = contents {
             for child in children {
                 child.parent = self
             }
         }
     }
     
   // debuging
    func gatherNodes(atLevel level: Int, curLevel: Int, result: inout [HbvNode]) {
        if level == curLevel {
            result.append(self)
        }
        else if case let .nonleaf(children) = contents {
            for child in children {
                child.gatherNodes(atLevel: level, curLevel: curLevel + 1, result: &result)
            }
        }
    }
    
    func findIntersections(range: Range2d, callback: (Int) -> ()) {
        guard !self.range.isOutside(of: range) else {
            return
        }

        switch contents {
        case .leaf(let index):
            callback(index)
        case .nonleaf(let children):
            for child in children {
                child.findIntersections(range: range, callback: callback)
            }
        }
    }

    func findIntersections(range: Range2d, callback: (HbvNode) -> Bool) {
        guard !self.range.isOutside(of: range) else {
            return
        }

        if !callback(self) {
            return
        }

        switch contents {
        case .leaf:
            ()
        case .nonleaf(let children):
            for child in children {
                child.findIntersections(range: range, callback: callback)
            }
        }
    }
    

    func findDepths(depths: inout [Int], depth: Int) {
        switch contents {
        case .leaf:
            depths.append(1 + depth)
        case .nonleaf(let children):
            for child in children {
                child.findDepths(depths: &depths, depth: depth + 1)
            }
        }
    }
    
    func update(ranges: [Range2d]) {
        switch contents {
        case .leaf(let index):
            range = ranges[index]
        case .nonleaf(let children):
            if !children.isEmpty {
                if case .leaf = children[0].contents {
                    return      // bbox already done
                }
                
                children[0].update(ranges: ranges)
                range = children[0].range
                for child in children[1...] {
                    child.update(ranges: ranges)
                    range = range.union(with: child.range)
                }
            }
        }
    }
    
    fileprivate static func buildTree(boxTree: BoxTree, leafParents: inout [HbvNode]) -> (HbvNode, Int) {
        if boxTree.atom {
            let node = HbvNode(contents: .nonleaf(boxTree.boxes.map { HbvNode(contents: Contents.leaf($0.index)) }))
            leafParents.append(node)
            return (node, 1)
        }
        else {
            let (child0, l0) = buildTree(boxTree: boxTree.child0, leafParents: &leafParents)
            let (child1, l1) = buildTree(boxTree: boxTree.child1, leafParents: &leafParents)

            return (HbvNode(contents: .nonleaf([child0, child1])), max(l0, l1) + 1)
        }
    }
}

/*
 * Temporary representation of the tree, replaced with Hbv.Node when complete.
 */
fileprivate class BoxTree {
    struct Box {
        let box: Range2d
        let index: Int
        var side = [0, 0]

        mutating func setWhichSide(mid: CGFloat, axis: Int) -> Int {
            if box.max.coord(axis) < mid {
                side[axis] = -1
                return -1
            }
            else if box.min.coord(axis) > mid {
                side[axis] = 1
                return 1
            }
            else {
                side[axis] = 0
                return 0
            }
        }
    }

    var atom: Bool { child0 == nil }
    var boxes: [Box]
    var child0: BoxTree!
    var child1: BoxTree!
    
    init(rects: [CGRect]) {
        boxes = rects.enumerated().map { Box(box: Range2d(cgRect: $0.element), index: $0.offset) }
    }

    init(boxes: [Box]) {
        self.boxes = boxes
    }

    func tryDivision(_ m: CGFloat, _ axis: Int) -> Int {
        var curdiv = 0
        for j in 0..<boxes.count {
            if boxes[j].setWhichSide(mid: m, axis: axis) == 1 {
                curdiv += 1
            }
        }
        return curdiv
    }

    func isOKDivision(div: Int, lim: Int) -> Bool {
        return min(div, boxes.count - div) >= max(lim, 3)
    }

    func makeGroup(lim: Int, fewest: inout Int, most: inout Int, level: Int) -> Int {
        assert(atom)
        if boxes.count < 2 * lim {
            fewest = min(fewest, boxes.count)
            most = max(most, boxes.count)
            return 1
        }

        var box = boxes[0].box
        for item in boxes[1...] {
            box = box.union(with: item.box)
        }
        
        let middle = 0.5 * (box.min + box.max)
        let delta = box.max - box.min
        var div = 0
        var axis = 0
        var order = [0, 1]

        if delta.coord(order[0]) < delta.coord(order[1]) {
            order.swapAt(0, 1)
        }

        var i = 0
        while i < 2 {
            axis = order[i]
            div = tryDivision(middle.coord(axis), axis)
            if isOKDivision(div: div, lim: lim) {
                break
            }
            i += 1
        }

        if i == 2 {
            /*
             * Haven't found a good division.  For each axis, try
             * subdividing at 1/8, 2/8, ... 7/8 along the axis and hope
             * that we get a good division.  First good division gets the
             * prize (we don't find the best one).
             */
        
            i = 0
            var found = false
            while i < 2 && !found {
                axis = order[i];

                for j in 1...7 {
                    let m = box.min.coord(axis) + CGFloat(j) * delta.coord(axis) / 8
                    div = tryDivision(m, axis)
                    if isOKDivision(div: div, lim: lim) {
                        found = true
                        break
                    }
                }

                i += 1
            }

            if !found {
                fewest = min(fewest, boxes.count)
                most = max(most, boxes.count)
                return 1
            }
        }

        child0 = BoxTree(boxes: boxes.filter { $0.side[axis] == 1 })
        child1 = BoxTree(boxes: boxes.filter { $0.side[axis] != 1 })
        boxes = []

        let l0 = child0.makeGroup(lim: lim, fewest: &fewest, most: &most, level: level + 1)
        let l1 = child1.makeGroup(lim: lim, fewest: &fewest, most: &most, level: level + 1)
        return max(l0, l1) + 1
    }
}
