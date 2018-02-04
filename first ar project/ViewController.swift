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


struct Model {
    var filename: String
    var filter: String?
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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!  //displaying a view of flight camera feed in which we are going to display our 3d objects
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var blockerView: UIView!
    @IBOutlet weak var startButtonContainer: UIView!
    @IBOutlet weak var startContainerBottomConstraint: NSLayoutConstraint!

    // We can just add the model file names to this array using the Model class and the load3DGarbageModels() function will add them to the scene
    private var garbageModels = [Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick")]
    private var isStartingGame = true
    private var garbageScene = SCNScene()
    private let titleText = MaterialText(text: SCNText(string:"Garbage Game", extrusionDepth:0.7), material: SCNMaterial(), color: UIColor.green)
    private let developerText = MaterialText(text: SCNText(string:"By:inVeNT", extrusionDepth:0.7), material: SCNMaterial(), color: UIColor.orange)

    let cigarette = SCNNode(geometry: nil)

    //runs when view loads
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a new scene and set the scene to the view,
        // set the scene view's delegate, show statistics, and debug info
        sceneView.scene = SCNScene()
        sceneView.delegate = self
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

        sceneView.scene = garbageScene
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

    // This function is a way to load all the models we add to the project
    func load3DGarbageModels(_ models: [Model]) {
        var newXPosition = 0.0
        models.forEach { (model) in
            guard let modelScene = SCNScene(named: model.filename) else { return }
            // The next line is a VERY basic way to position the objects sequentially along the x axis but a fixed y coordinate
            // and should be improved later to logically determine the horizontal surfaces and more intelligently
            // position the nodes representing the models
            let positionVector = SCNVector3(newXPosition,-1.0,-1.0)
            if let newNode = scaledNode(from: modelScene, at: positionVector, scale: SCNVector3(0.8, 0.8, 0.8), filteredName: model.filter ) {
                sceneView.scene.rootNode.addChildNode(newNode)
            }
            newXPosition += 1.0
        }
    }

    // This allows us to extract and filter out the parts of the model, scale them, and create an SCNNode from them to put in the scene
    func scaledNode(from scene: SCNScene, at position: SCNVector3, scale: SCNVector3 = SCNVector3(1.0, 1.0, 1.0), filteredName: String? = nil) -> SCNNode? {
        guard !scene.rootNode.childNodes.isEmpty else { return nil }

        let node = SCNNode()
        node.scale = scale
        node.position = position

        scene.rootNode.childNodes
            .filter {
                guard let name = $0.name else { return false }
                guard let filteredName = filteredName else { return true }
                return !name.contains(filteredName)
            }
            .forEach {
                print("adding node ", $0, " from the model file to the new node")
                $0.scale = SCNVector3(1.0, 1.0, 1.0)
                node.addChildNode($0)
            }
        return node
    }
    
    // MARK: - ARSCNViewDelegate functions

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        showError(title: "Sorry", message: "The AR session wasn't able to start. Please stop the app and try again.")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        showError(title: "Sorry", message: "The AR session was interrupted. Please stop the app and try again.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        showError(title: "Sorry", message: "The AR session ended. Please stop the app and try again.")
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

    // MARK: - Functions we're not using now

    // This next ARSCNViewDelegate function that for now works only when the createShip() function is called
    // -- when the anchor is added to the session, this method is called to return a node
    // right now we're not using it
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        boxGeometry.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ship.scn")
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.position = SCNVector3(0, 0, -1.5)
        return boxNode
    }


    // Our test helper function that we're not using now
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


}



