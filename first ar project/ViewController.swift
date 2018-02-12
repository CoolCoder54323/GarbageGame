//
//  ViewController.swift
//  first ar project
//
//  Created by Nicholas Dixon on 12/27/17.
//  Copyright © 2017 Nicholas Dixon. All rights reserved.
//

import UIKit
import SceneKit//3d objects
import ARKit
import QuartzCore



struct Model: Equatable {
    var filename: String
    var id: UInt32
    var filter: String?
    var anchor: ARAnchor?
    var node: SCNNode?
    var desiredScale: SCNVector3

    init(filename: String, filter: String? = nil, desiredScale: SCNVector3 = SCNVector3(0.8,0.8,0.8)) {
        self.filename = filename
        self.filter = filter
        self.id = arc4random()
        self.desiredScale = desiredScale
    }
    static func ==(lhs: Model, rhs: Model) -> Bool {
        return lhs.filename == rhs.filename && lhs.id == rhs.id
    }
}

class MaterialText {
    var text: SCNText
    var material: SCNMaterial { return text.materials.first! }
    private var currentNode: SCNNode?

    init(text: SCNText, material: SCNMaterial, color: UIColor) {
        self.text = text
        self.text.materials = [material] //makes the objct into your text
        self.text.materials.first?.diffuse.contents = color //turns it a color
    }
    
    func setColor(_ color: UIColor) {
        text.materials.first?.diffuse.contents = color //turns it a color
    }

    func node(scale: SCNVector3 = SCNVector3(0.2,0.2,0.2), at position: SCNVector3 = SCNVector3(0.0,0.0,-1.0)) -> SCNNode {
        guard currentNode == nil else { return (self.currentNode)! }
        let newNode = SCNNode(geometry: self.text)
        newNode.scale = scale
        newNode.position = position
        self.currentNode = newNode
        return newNode
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var interactionView: UIView!
    @IBOutlet weak var hitLabel: UILabel!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var sceneView: ARSCNView!  //displaying a view of flight camera feed in which we are going to display our 3d objects
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var blockerView: UIView!
    @IBOutlet weak var startButtonContainer: UIView!
    @IBOutlet weak var startContainerBottomConstraint: NSLayoutConstraint!

    // We can just add the model file names to this array using the Model class and the load3DGarbageModels() function will add them to the scene
    var modelFound: Model?
    private var garbageModels = [Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick"),
                                 Model(filename: "art.scnassets/bottle.dae", filter: "Spot", desiredScale: SCNVector3(0.02,0.02,0.02))]
    private var isStartingGame = true
    private var garbageScene = SCNScene()
    private let titleText = MaterialText(text: SCNText(string:"Garbage Game", extrusionDepth:0.7), material: SCNMaterial(), color: UIColor.green)
    private let developerText = MaterialText(text: SCNText(string:"By:inVeNT", extrusionDepth:0.7), material: SCNMaterial(), color: UIColor.orange)



    //runs when view loads
    override func viewDidLoad() {
        super.viewDidLoad()
       
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // This visualization covers only detected planes.
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            // Create a SceneKit plane to visualize the node using its position and extent.
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // SCNPlanes are vertically oriented in their local coordinate space.
            // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            // ARKit owns the node corresponding to the anchor, so make the plane a child node.
            node.addChildNode(planeNode)
        }

        centerPoint = CGPoint(x: UIScreen.main.bounds.size.width/CGFloat(2.0), y: UIScreen.main.bounds.size.height/CGFloat(2.0))

        // Create a new scene and set the scene to the view,
        // set the scene view's delegate, show statistics, and debug info
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        // sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        // We were trying to add the ship to the scene directly here
        // but found out that we have to use this method OR the method of adding an anchor
        // to the sceneView.session and then return the corresponding node
        // in the "renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor)" function below
//        let nodeModel:SCNNode!
//        let nodeName = "ship"
//        let modelScene = SCNScene(named : "ship.scn")!
//        nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
//        sceneView.scene.rootNode.addChildNode(cigarette)

        showStartButtonContainer(false, animated: false)
        startButton.setTitle("START THE GAME", for: .normal)

        sceneView.scene.rootNode.addChildNode(titleText.node(scale: SCNVector3(x: 0.01, y: 0.01, z: 0.05), at: SCNVector3(x: -0.05, y: 0.2, z: -3)))
        sceneView.scene.rootNode.addChildNode(developerText.node(scale: SCNVector3(x: 0.01, y: 0.01, z: 0.05), at: SCNVector3(x: -0.05, y: 0.0, z:-3)))
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration and run the view's session
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)

        // Add the ship anchor and node only when we want to test putting the airplane model in the scene
        // createShip()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showStartButtonContainer(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        sceneView.scene.rootNode.childNodes.forEach { (child) in
            child.removeFromParentNode()
        }

        load3DGarbageModels(garbageModels)
        showStartButtonContainer(false, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        if let hit = sceneView.hitTest(touch.location(in: sceneView), options: nil).first {
            selectedNode = hit.node
            zDepth = sceneView.projectPoint(selectedNode.position).z
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectedNode != nil else { return }
        let touch = touches.first!
        let touchPoint = touch.location(in: sceneView)
        selectedNode.position = sceneView.unprojectPoint(
            SCNVector3(x: Float(touchPoint.x),
                       y: Float(touchPoint.y),
                       z: zDepth))
    }
    
    // This function is a way to load all the models we add to the project
    func load3DGarbageModels(_ models: [Model]) {
        var newXPosition: Float = Float(0.0)
        var newZPosition: Float = Float(1.0)

        let copyOfModels = models
        copyOfModels.forEach { [weak self] (model) in
            guard let sself = self, let currentFrame = sceneView.session.currentFrame, let modelScene = SCNScene(named: model.filename) else { return }
            // The next line is a VERY basic way to position the objects sequentially along the x axis but a fixed y coordinate
            // and should be improved later to logically determine the horizontal surfaces and more intelligently
            // position the nodes representing the models
            var translation = matrix_identity_float4x4
            translation.columns.3.x = newXPosition
            translation.columns.3.z = -newZPosition
            let newTransform = currentFrame.camera.transform * translation
            if let newNode = scaledNode(from: modelScene, scale: model.desiredScale, filteredName: model.filter), let index = sself.garbageModels.index(of: model) {
                garbageModels[index].node = newNode
                let newAnchor = ARAnchor.init(transform: newTransform)
                garbageModels[index].anchor = newAnchor
                sself.sceneView.session.add(anchor: newAnchor)
                sceneView.scene.rootNode.addChildNode(newNode)
            }
            newXPosition += Float(1.0)
            newZPosition += Float(0.2)
        }
    }

    // This allows us to extract and filter out the parts of the model, scale them, and create an SCNNode from them to put in the scene
    func scaledNode(from scene: SCNScene, scale: SCNVector3 = SCNVector3(1.0, 1.0, 1.0), filteredName: String? = nil) -> SCNNode? {
        guard !scene.rootNode.childNodes.isEmpty else { return nil }

        let node = SCNNode()
        node.scale = scale

        scene.rootNode.childNodes
            .filter {
                guard let name = $0.name else { return false }
                guard let filteredName = filteredName else { return true }
                let acceptanceString = !name.contains(filteredName) ? "accepting" : "rejecting"
                print(acceptanceString, " node: ",$0)
                return !name.contains(filteredName)
            }
            .forEach {
                print("adding node ", $0, " from the model file to the new node")
                $0.scale = SCNVector3(1.0, 1.0, 1.0)
                node.addChildNode($0)
            }
        return node
    }


    // MARK: - ARSessionDelegate functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Find out if there are any nodes 3D space that line up with the center of the scene view using the 2D center point
        let hitResults = sceneView.hitTest(centerView.center, options: nil)
        if !hitResults.isEmpty {
            hitResults.forEach { [weak self] (hitResult) in
                self?.garbageModels.forEach { (garbageModel) in
                    guard let rootNode = garbageModel.node else { return }
                    rootNode.childNodes.forEach({ (node) in
                        if hitResult.node.name == node.name {
                            modelFound = garbageModel
                            hitLabel.text = "Throw AWAY the TRASH"
                        }
                    })
                }
            }

        } else {
            hitLabel.text = "find it"
            modelFound = nil
            
        }
    }

    // MARK: - ARSCNViewDelegate functions

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        showError(title: "ERROR", message: "Please stop the app and try again.")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        showError(title: "ERROR", message: "Please stop the app and try again.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        showError(title: "ERROR", message: " Please stop the app and try again.")
    }

    // MARK: - Helper Functions

    // This gives us an easy way to put up an error message on the screen
    func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // This gives us an easy way to show and hide the start game button
    func showStartButtonContainer(_ shouldShow: Bool, animated: Bool) {
        let duration = animated ? 1.0 : 0.0
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.startContainerBottomConstraint.constant = shouldShow ? CGFloat(0.0) :(self?.startButtonContainer.frame.size.height ?? CGFloat(60.0))
            self?.startButtonContainer.alpha = shouldShow ? 1.0 : 0.0
            self?.blockerView.alpha = shouldShow ? 0.5 : 0.0
            self?.view.layoutIfNeeded()
        })
    }

    func processNodeFound(_ node: SCNNode) {
        hitLabel.text = "TRASH SPOTTED!"
    }

    // This version of the 'nodeFor' ARSCNViewDelegate function works with the new approach of adding
    // anchors corresponding to the garbage model objects we add to our app
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var nodeFound: SCNNode?

        garbageModels.forEach { (garbageModel) in
            if garbageModel.anchor == anchor { nodeFound = garbageModel.node }
        }
        return nodeFound
    }


    // MARK: - Functions we're not using now

    // This next ARSCNViewDelegate function that for now works only when the createShip() function is called
    // -- when the anchor is added to the session, this method is called to return a node
    // right now we're not using it
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
//        boxGeometry.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ship.scn")
//        let boxNode = SCNNode(geometry: boxGeometry)
//        boxNode.position = SCNVector3(0, 0, -1.5)
//        return boxNode
//    }


    // Our test functions that we're not using now
    func createShip(){
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                self?.createShip()
            })
            return
        }
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.0
        let shipTransform = cameraTransform * translation
        let ship = ARAnchor(transform: shipTransform)
        sceneView.session.add(anchor: ship)
    }

    @IBAction func panGestureTouched(_ sender: UIPanGestureRecognizer) {
        let touchLocation = sender.location(in: interactionView)
        print("pan gesture recognizer action method called! -- ", touchLocation)
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let model = modelFound, let anchor = model.anchor, let node = model.node else { return }
        sceneView.session.remove(anchor: anchor)
        
        node.removeFromParentNode()

    }

}


