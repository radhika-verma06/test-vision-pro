import SwiftUI
import RealityKit
import simd

struct ImmersiveView: View {
    @EnvironmentObject var manager: SessionManager
    @EnvironmentObject var referenceController: ReferenceHandController
    @EnvironmentObject var handTrackingController: HandTrackingController
    
    // We retain references to the spawned entities so we can update them in the update block
    @State private var referenceHandEntity = Entity()
    @State private var userHandEntity = Entity()
    @State private var guidanceLineEntity = Entity()
    @State private var isInitialized = false
    
    // Cached materials to avoid allocating them every frame
    @State private var greenMaterial: RealityKit.Material = {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = PhysicallyBasedMaterial.BaseColor(tint: UIColor.green)
        mat.roughness = 0.15
        mat.metallic = 0.8
        mat.blending = .transparent(opacity: 0.75)
        mat.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .green)
        mat.emissiveIntensity = 1.5
        return mat
    }()
    
    @State private var orangeMaterial: RealityKit.Material = {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = PhysicallyBasedMaterial.BaseColor(tint: UIColor.orange)
        mat.roughness = 0.15
        mat.metallic = 0.8
        mat.blending = .transparent(opacity: 0.75)
        mat.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .orange)
        mat.emissiveIntensity = 1.5
        return mat
    }()
    
    @State private var lastAlignedState: Bool? = nil
    
    var body: some View {
        RealityView { content in
            // Build the 3D Reference Hand (Cyan guidance guide)
            let refHand = buildSkeletalHand(color: .cyan, isReference: true)
            referenceHandEntity = refHand
            content.add(refHand)
            
            // Build the 3D User Hand (updates green/orange depending on alignment)
            let userHand = buildSkeletalHand(color: .orange, isReference: false)
            userHandEntity = userHand
            content.add(userHand)
            
            // Build the guidance connector line (cylinder height 1.0, radius 1.5mm)
            let lineMesh = MeshResource.generateCylinder(height: 1.0, radius: 0.0015)
            let lineMat = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.4))
            let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
            line.name = "guidanceLine"
            content.add(line)
            guidanceLineEntity = line
            
            isInitialized = true
        } update: { content in
            guard isInitialized else { return }
            
            // 1. Update reference hand transform
            referenceHandEntity.position = referenceController.currentPosition
            referenceHandEntity.orientation = rotationBetween(
                from: SIMD3<Float>(0.0, 1.0, 0.0),
                to: referenceController.currentDirection
            )
            
            // 2. Update user hand transform
            userHandEntity.position = handTrackingController.userHandPosition
            userHandEntity.orientation = rotationBetween(
                from: SIMD3<Float>(0.0, 1.0, 0.0),
                to: handTrackingController.userHandDirection
            )
            
            // 3. Update guidance connector line between user and reference hand
            let p1 = handTrackingController.userHandPosition
            let p2 = referenceController.currentPosition
            let dist = simd_distance(p1, p2)
            
            if dist > 0.05 && !manager.isAligned {
                guidanceLineEntity.isEnabled = true
                guidanceLineEntity.position = (p1 + p2) / 2.0
                guidanceLineEntity.scale = [1, dist, 1]
                let direction = simd_normalize(p2 - p1)
                guidanceLineEntity.orientation = rotationBetween(
                    from: SIMD3<Float>(0.0, 1.0, 0.0),
                    to: direction
                )
            } else {
                guidanceLineEntity.isEnabled = false
            }
            
            // 4. Dynamic styling based on alignment (only when state changes)
            if lastAlignedState != manager.isAligned {
                lastAlignedState = manager.isAligned
                let material = manager.isAligned ? greenMaterial : orangeMaterial
                updateMaterialRecursively(for: userHandEntity, material: material)
            }
            
            // 5. Pose both hands dynamically according to the current exercise target
            let currentPoseName = referenceController.currentPose?.name ?? "Neutral"
            poseHand(entity: referenceHandEntity, poseName: currentPoseName)
            
            if handTrackingController.isSimulated {
                poseHand(entity: userHandEntity, poseName: currentPoseName)
            } else {
                poseHand(entity: userHandEntity, poseName: manager.isAligned ? currentPoseName : "Neutral")
            }
        }
    }
    
    // Helper to recursively find a child entity by name
    private func findChild(in entity: Entity, named name: String) -> Entity? {
        if entity.name == name { return entity }
        for child in entity.children {
            if let found = findChild(in: child, named: name) {
                return found
            }
        }
        return nil
    }
    
    // Pose joints based on the name of the therapy exercise target pose
    private func poseHand(entity: Entity, poseName: String) {
        let nameLower = poseName.lowercased()
        let fingers = ["thumb", "index", "middle", "ring", "pinky"]
        
        for finger in fingers {
            let mcpName = "\(finger)_mcp"
            let pipName = "\(finger)_pip"
            
            guard let mcp = findChild(in: entity, named: mcpName),
                  let pip = findChild(in: entity, named: pipName) else { continue }
            
            var mcpRot = simd_quaternion(0.0, SIMD3<Float>(1, 0, 0))
            var pipRot = simd_quaternion(0.0, SIMD3<Float>(1, 0, 0))
            
            if nameLower.contains("fist") || nameLower.contains("closed") {
                // Curl fingers into a fist
                if finger == "thumb" {
                    mcpRot = simd_quaternion(0.6, SIMD3<Float>(1, 0, 0)) * simd_quaternion(-0.3, SIMD3<Float>(0, 1, 0))
                    pipRot = simd_quaternion(0.5, SIMD3<Float>(1, 0, 0))
                } else {
                    mcpRot = simd_quaternion(1.2, SIMD3<Float>(1, 0, 0))
                    pipRot = simd_quaternion(1.2, SIMD3<Float>(1, 0, 0))
                }
            } else if nameLower.contains("spread") || nameLower.contains("wide") {
                // Spread fingers wide apart (abduction)
                if finger == "thumb" {
                    mcpRot = simd_quaternion(0.2, SIMD3<Float>(1, 0, 0)) * simd_quaternion(-0.5, SIMD3<Float>(0, 1, 0))
                } else if finger == "index" {
                    mcpRot = simd_quaternion(0.0, SIMD3<Float>(1, 0, 0)) * simd_quaternion(-0.15, SIMD3<Float>(0, 1, 0))
                } else if finger == "ring" {
                    mcpRot = simd_quaternion(0.0, SIMD3<Float>(1, 0, 0)) * simd_quaternion(0.12, SIMD3<Float>(0, 1, 0))
                } else if finger == "pinky" {
                    mcpRot = simd_quaternion(0.0, SIMD3<Float>(1, 0, 0)) * simd_quaternion(0.25, SIMD3<Float>(0, 1, 0))
                }
            }
            
            mcp.transform.rotation = mcpRot
            pip.transform.rotation = pipRot
        }
    }
    
    // Generates a high-fidelity 3D skeletal hand representation (visual joints & bones)
    private func buildSkeletalHand(color: UIColor, isReference: Bool) -> Entity {
        let root = Entity()
        
        // Define base material
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color)
        material.roughness = 0.2
        material.metallic = 0.8
        
        if isReference {
            // Emissive neon glow for holographic guide hand
            material.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .cyan)
            material.emissiveIntensity = 1.8
            material.blending = .transparent(opacity: 0.35)
        } else {
            // User hand is solid shiny glass/metal
            material.blending = .transparent(opacity: 0.90)
        }
        
        // Palm - a sleek rounded glass box plate
        let palmMesh = MeshResource.generateBox(size: [0.08, 0.012, 0.09], cornerRadius: 0.01)
        let palm = ModelEntity(mesh: palmMesh, materials: [material])
        palm.name = "palm"
        palm.position = [0, 0, -0.01]
        root.addChild(palm)
        
        let fingers = ["thumb", "index", "middle", "ring", "pinky"]
        
        // Knuckle locations on palm plate
        let knucklePositions: [String: SIMD3<Float>] = [
            "thumb":  [-0.038, 0.005, 0.010],
            "index":  [-0.030, 0.006, -0.045],
            "middle": [-0.010, 0.006, -0.048],
            "ring":   [0.012, 0.006, -0.046],
            "pinky":  [0.032, 0.006, -0.041]
        ]
        
        // Bone segment lengths [MCP-PIP, PIP-Tip]
        let boneLengths: [String: [Float]] = [
            "thumb":  [0.025, 0.022],
            "index":  [0.032, 0.025],
            "middle": [0.036, 0.028],
            "ring":   [0.032, 0.025],
            "pinky":  [0.026, 0.020]
        ]
        
        let jointRadius: Float = 0.008
        let jointMesh = MeshResource.generateSphere(radius: jointRadius)
        
        for finger in fingers {
            guard let knucklePos = knucklePositions[finger],
                  let lengths = boneLengths[finger] else { continue }
            
            // MCP Knuckle Joint
            let mcpJoint = ModelEntity(mesh: jointMesh, materials: [material])
            mcpJoint.name = "\(finger)_mcp"
            mcpJoint.position = knucklePos
            root.addChild(mcpJoint)
            
            // PIP Middle Joint
            let pipJoint = ModelEntity(mesh: jointMesh, materials: [material])
            pipJoint.name = "\(finger)_pip"
            pipJoint.position = [0, 0, -lengths[0]]
            mcpJoint.addChild(pipJoint)
            
            // DIP Fingertip Joint
            let tipJoint = ModelEntity(mesh: jointMesh, materials: [material])
            tipJoint.name = "\(finger)_tip"
            tipJoint.position = [0, 0, -lengths[1]]
            pipJoint.addChild(tipJoint)
            
            // Bone Cylinders
            let boneRadius: Float = 0.0035
            
            // Bone 1: MCP to PIP
            let bone1Mesh = MeshResource.generateCylinder(height: lengths[0], radius: boneRadius)
            let bone1 = ModelEntity(mesh: bone1Mesh, materials: [material])
            bone1.name = "\(finger)_bone1"
            bone1.position = [0, 0, -lengths[0] / 2.0]
            bone1.orientation = simd_quaternion(Float.pi / 2.0, [1, 0, 0])
            mcpJoint.addChild(bone1)
            
            // Bone 2: PIP to Tip
            let bone2Mesh = MeshResource.generateCylinder(height: lengths[1], radius: boneRadius)
            let bone2 = ModelEntity(mesh: bone2Mesh, materials: [material])
            bone2.name = "\(finger)_bone2"
            bone2.position = [0, 0, -lengths[1] / 2.0]
            bone2.orientation = simd_quaternion(Float.pi / 2.0, [1, 0, 0])
            pipJoint.addChild(bone2)
        }
        
        return root
    }
    
    // Recursively updates the material of all ModelEntities in the hierarchy
    private func updateMaterialRecursively(for entity: Entity, material: RealityKit.Material) {
        if let modelEntity = entity as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        for child in entity.children {
            updateMaterialRecursively(for: child, material: material)
        }
    }
    
    // Computes the quaternion rotation between a default vector and a target vector
    private func rotationBetween(from source: SIMD3<Float>, to target: SIMD3<Float>) -> simd_quatf {
        let u = simd_normalize(source)
        let v = simd_normalize(target)
        let dotVal = simd_dot(u, v)
        
        if dotVal > 0.9999 {
            return simd_quaternion(0.0, SIMD3<Float>(0.0, 1.0, 0.0))
        } else if dotVal < -0.9999 {
            var orth = simd_cross(u, SIMD3<Float>(1.0, 0.0, 0.0))
            if simd_length(orth) < 0.0001 {
                orth = simd_cross(u, SIMD3<Float>(0.0, 1.0, 0.0))
            }
            return simd_quaternion(.pi, simd_normalize(orth))
        }
        
        let crossVal = simd_cross(u, v)
        let w = 1.0 + dotVal
        return simd_normalize(simd_quaternion(crossVal.x, crossVal.y, crossVal.z, w))
    }
}
