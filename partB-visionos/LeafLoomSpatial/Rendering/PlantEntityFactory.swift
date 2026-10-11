import RealityKit
import UIKit

/// Builds stylised plants from RealityKit primitive meshes, so the prototype ships no third-party
/// 3D assets. Every plant is deterministic: the same plant id always grows the same shape.
@MainActor
enum PlantEntityFactory {
    static let potHeight: Float = 0.14
    static let potRadius: Float = 0.09
    static let fitRingName = "fitRing"

    private enum Palette {
        static let leaf = UIColor(red: 0.20, green: 0.48, blue: 0.27, alpha: 1)
        static let leafLight = UIColor(red: 0.42, green: 0.66, blue: 0.33, alpha: 1)
        static let leafEdge = UIColor(red: 0.78, green: 0.74, blue: 0.36, alpha: 1)
        static let stem = UIColor(red: 0.33, green: 0.47, blue: 0.24, alpha: 1)
        static let trunk = UIColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1)
        static let pot = UIColor(red: 0.80, green: 0.47, blue: 0.33, alpha: 1)
        static let soil = UIColor(red: 0.27, green: 0.19, blue: 0.13, alpha: 1)
        static let bloom = UIColor(white: 0.97, alpha: 1)
    }

    /// A plant standing on its pot. The origin is at the bottom centre of the pot.
    static func makePlant(_ plant: SpatialPlant) -> Entity {
        var rng = SeededGenerator(id: plant.id)
        let root = Entity()
        root.name = plant.id.uuidString
        root.addChild(makePot())

        let foliage = Entity()
        foliage.position.y = potHeight
        switch plant.shape {
        case .broadLeaf: addBroadLeaves(to: foliage, rng: &rng)
        case .upright: addUprightBlades(to: foliage, rng: &rng)
        case .trailing: addTrailingVines(to: foliage, rng: &rng)
        case .tree: addTree(to: foliage, rng: &rng)
        case .flowering: addFlowering(to: foliage, rng: &rng)
        case .rosette: addRosette(to: foliage, rng: &rng)
        case .herb: addHerb(to: foliage, rng: &rng)
        }
        root.addChild(foliage)
        root.addChild(makeFitRing())

        makeInteractive(root)
        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = LocalizedStringResource(stringLiteral: "\(plant.name), \(plant.commonName)")
        root.components.set(accessibility)
        return root
    }

    /// A translucent pane that stands for the room's window, with floor rings marking light zones.
    static func makeWindowMarker() -> Entity {
        let root = Entity()
        root.name = "window"

        var pane = UnlitMaterial(color: UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 1))
        pane.blending = .transparent(opacity: 0.35)
        let glass = ModelEntity(mesh: .generateBox(width: 1.0, height: 1.2, depth: 0.02, cornerRadius: 0.02), materials: [pane])
        glass.position.y = 1.2
        root.addChild(glass)

        let zones: [(Float, UIColor)] = [
            (LightZone.mediumLimit, UIColor(red: 0.55, green: 0.65, blue: 0.85, alpha: 1)),
            (LightZone.brightIndirectLimit, UIColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1)),
            (LightZone.fullSunLimit, UIColor(red: 1.0, green: 0.70, blue: 0.30, alpha: 1)),
        ]
        for (index, zone) in zones.enumerated() {
            var material = UnlitMaterial(color: zone.1)
            material.blending = .transparent(opacity: 0.12)
            let disc = ModelEntity(mesh: .generateCylinder(height: 0.002, radius: zone.0), materials: [material])
            disc.position.y = 0.001 * Float(index + 1)
            root.addChild(disc)
        }

        makeInteractive(glass)
        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = "Window marker. Drag to match your real window."
        glass.components.set(accessibility)
        return root
    }

    static func setFit(_ fit: LightFit, selected: Bool, on plantEntity: Entity) {
        guard let ring = plantEntity.findEntity(named: fitRingName) as? ModelEntity else { return }
        let color: UIColor = switch fit {
        case .good: UIColor(red: 0.30, green: 0.75, blue: 0.40, alpha: 1)
        case .acceptable: UIColor(red: 0.95, green: 0.75, blue: 0.25, alpha: 1)
        case .poor: UIColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1)
        }
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: selected ? 0.85 : 0.45)
        ring.model?.materials = [material]
        ring.scale = selected ? SIMD3(1.15, 1, 1.15) : .one
    }

    // MARK: Parts

    private static func makePot() -> Entity {
        let pot = Entity()
        let body = ModelEntity(mesh: .generateCylinder(height: potHeight, radius: potRadius),
                               materials: [SimpleMaterial(color: Palette.pot, roughness: 0.8, isMetallic: false)])
        body.position.y = potHeight / 2
        let rim = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: potRadius * 1.08),
                              materials: [SimpleMaterial(color: Palette.pot, roughness: 0.7, isMetallic: false)])
        rim.position.y = potHeight - 0.01
        let soil = ModelEntity(mesh: .generateCylinder(height: 0.005, radius: potRadius * 0.95),
                               materials: [SimpleMaterial(color: Palette.soil, roughness: 1, isMetallic: false)])
        soil.position.y = potHeight + 0.001
        pot.addChild(body)
        pot.addChild(rim)
        pot.addChild(soil)
        return pot
    }

    private static func makeFitRing() -> Entity {
        let ring = ModelEntity(mesh: .generateCylinder(height: 0.003, radius: potRadius * 1.6), materials: [UnlitMaterial(color: .white)])
        ring.name = fitRingName
        ring.position.y = 0.002
        return ring
    }

    /// Adds collision and hover so the entity can receive gestures. Bounds are computed after the
    /// children are attached so the whole plant is a single target.
    private static func makeInteractive(_ entity: Entity) {
        let bounds = entity.visualBounds(relativeTo: entity)
        let shape = ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())
    }

    private static func material(_ color: UIColor, roughness: Float = 0.6) -> SimpleMaterial {
        SimpleMaterial(color: color, roughness: .float(roughness), isMetallic: false)
    }

    /// A stem that leans `tilt` radians away from vertical, turned `yaw` radians around the pot.
    /// Returns the pivot (to add to the parent) and the tip (to hang a leaf or flower on).
    private static func branch(length: Float, radius: Float = 0.004, yaw: Float, tilt: Float, color: UIColor = Palette.stem) -> (pivot: Entity, tip: Entity) {
        let pivot = Entity()
        pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: tilt, axis: [1, 0, 0])
        let stem = ModelEntity(mesh: .generateCylinder(height: length, radius: radius), materials: [material(color)])
        stem.position.y = length / 2
        let tip = Entity()
        tip.position.y = length
        pivot.addChild(stem)
        pivot.addChild(tip)
        return (pivot, tip)
    }

    /// A flattened sphere reads as a leaf blade from any viewing angle.
    private static func leaf(radius: Float, stretch: SIMD3<Float>, color: UIColor) -> ModelEntity {
        let leaf = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material(color, roughness: 0.45)])
        leaf.scale = stretch
        return leaf
    }

    private static func addBroadLeaves(to parent: Entity, rng: inout SeededGenerator) {
        let count = Int.random(in: 5...7, using: &rng)
        for index in 0..<count {
            let yaw = Float(index) / Float(count) * 2 * .pi + Float.random(in: -0.2...0.2, using: &rng)
            let length = Float.random(in: 0.18...0.32, using: &rng)
            let (pivot, tip) = branch(length: length, yaw: yaw, tilt: Float.random(in: 0.35...0.8, using: &rng))
            let blade = leaf(radius: 0.07, stretch: [1.0, 0.08, 1.35], color: index.isMultiple(of: 2) ? Palette.leaf : Palette.leafLight)
            blade.orientation = simd_quatf(angle: 0.5, axis: [1, 0, 0])
            tip.addChild(blade)
            parent.addChild(pivot)
        }
    }

    private static func addUprightBlades(to parent: Entity, rng: inout SeededGenerator) {
        let count = Int.random(in: 6...8, using: &rng)
        for index in 0..<count {
            let height = Float.random(in: 0.25...0.42, using: &rng)
            let blade = ModelEntity(mesh: .generateBox(width: 0.035, height: height, depth: 0.008, cornerRadius: 0.004),
                                    materials: [material(index.isMultiple(of: 3) ? Palette.leafEdge : Palette.leaf)])
            let pivot = Entity()
            let yaw = Float(index) / Float(count) * 2 * .pi
            pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: Float.random(in: 0.05...0.2, using: &rng), axis: [1, 0, 0])
            pivot.position = SIMD3(cos(yaw), 0, sin(yaw)) * 0.03
            blade.position.y = height / 2
            pivot.addChild(blade)
            parent.addChild(pivot)
        }
    }

    private static func addTrailingVines(to parent: Entity, rng: inout SeededGenerator) {
        for index in 0..<5 {
            let (pivot, tip) = branch(length: 0.08, yaw: Float(index) * 1.25, tilt: 0.6)
            tip.addChild(leaf(radius: 0.035, stretch: [1, 0.1, 1.3], color: Palette.leafLight))
            parent.addChild(pivot)
        }
        for vine in 0..<3 {
            let yaw = Float(vine) * 2.1 + 0.4
            let direction = SIMD3<Float>(cos(yaw), 0, sin(yaw))
            let leaves = Int.random(in: 5...8, using: &rng)
            for step in 0..<leaves {
                let t = Float(step) / Float(leaves)
                let blade = leaf(radius: 0.025, stretch: [1, 0.12, 1.25], color: step.isMultiple(of: 2) ? Palette.leaf : Palette.leafEdge)
                blade.position = direction * (potRadius + 0.02 + t * 0.05) + SIMD3(0, -t * (potHeight + 0.05), 0)
                blade.orientation = simd_quatf(angle: Float.random(in: -0.6...0.6, using: &rng), axis: [0, 0, 1])
                parent.addChild(blade)
            }
        }
    }

    private static func addTree(to parent: Entity, rng: inout SeededGenerator) {
        let trunkHeight: Float = 0.5
        let trunk = ModelEntity(mesh: .generateCylinder(height: trunkHeight, radius: 0.012), materials: [material(Palette.trunk, roughness: 0.9)])
        trunk.position.y = trunkHeight / 2
        parent.addChild(trunk)
        for index in 0..<12 {
            let height = trunkHeight * Float.random(in: 0.55...1.0, using: &rng)
            let yaw = Float(index) * 2.4
            let blade = leaf(radius: 0.06, stretch: [1, 0.09, 1.25], color: index.isMultiple(of: 2) ? Palette.leaf : Palette.leafLight)
            blade.position = SIMD3(cos(yaw) * 0.07, height, sin(yaw) * 0.07)
            blade.orientation = simd_quatf(angle: -yaw, axis: [0, 1, 0]) * simd_quatf(angle: 0.6, axis: [0, 0, 1])
            parent.addChild(blade)
        }
    }

    private static func addFlowering(to parent: Entity, rng: inout SeededGenerator) {
        for index in 0..<7 {
            let (pivot, tip) = branch(length: Float.random(in: 0.14...0.22, using: &rng), yaw: Float(index) * 0.9, tilt: Float.random(in: 0.3...0.6, using: &rng))
            tip.addChild(leaf(radius: 0.05, stretch: [0.7, 0.08, 1.5], color: Palette.leaf))
            parent.addChild(pivot)
        }
        for index in 0..<3 {
            let (pivot, tip) = branch(length: Float.random(in: 0.3...0.36, using: &rng), radius: 0.003, yaw: Float(index) * 2.1, tilt: 0.15)
            let spathe = leaf(radius: 0.03, stretch: [0.8, 1.4, 0.35], color: Palette.bloom)
            spathe.position.y = 0.03
            tip.addChild(spathe)
            parent.addChild(pivot)
        }
    }

    private static func addRosette(to parent: Entity, rng: inout SeededGenerator) {
        for index in 0..<11 {
            let yaw = Float(index) * 2.4
            let height = Float.random(in: 0.14...0.22, using: &rng)
            let pivot = Entity()
            pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: Float(index % 3) * 0.25 + 0.2, axis: [1, 0, 0])
            let spike = ModelEntity(mesh: .generateCone(height: height, radius: 0.018), materials: [material(Palette.leafLight, roughness: 0.35)])
            spike.position.y = height / 2
            spike.scale = [1, 1, 0.45]
            pivot.addChild(spike)
            parent.addChild(pivot)
        }
    }

    private static func addHerb(to parent: Entity, rng: inout SeededGenerator) {
        for index in 0..<6 {
            let (pivot, tip) = branch(length: Float.random(in: 0.1...0.18, using: &rng), radius: 0.003, yaw: Float(index) * 1.05, tilt: Float.random(in: 0.1...0.45, using: &rng))
            for pair in 0..<3 {
                let blade = leaf(radius: 0.022, stretch: [1, 0.15, 1.3], color: Palette.leafLight)
                blade.position = SIMD3(pair.isMultiple(of: 2) ? 0.015 : -0.015, -Float(pair) * 0.035, 0)
                tip.addChild(blade)
            }
            parent.addChild(pivot)
        }
    }
}

/// SplitMix64, seeded from a plant's UUID bytes so shapes are stable across launches
/// (`UUID.hashValue` is randomised per process).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    init(id: UUID) {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        state = bytes.reduce(UInt64(0xCBF29CE484222325)) { ($0 ^ UInt64($1)) &* 0x100000001B3 }
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
