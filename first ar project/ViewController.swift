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




class MaterialText {
    var text: SCNText
    var material: SCNMaterial { return text.materials.first! }
    
    init(text: SCNText, material: SCNMaterial) {
        self.text = text
        self.text.materials = [material] //makes the objct into your text
    }
    
    func setColor(_ color: UIColor) {
        text.materials.first?.diffuse.contents = color //turns it a color
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!  //displaying a view of flight camera feed in which we are going to display our 3d objects
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var blockerView: UIView!
    @IBOutlet weak var startButtonContainer: UIView!
    @IBOutlet weak var startContainerBottomConstraint: NSLayoutConstraint!

    private var isStartingGame = true
    private var garbageScene = SCNScene()
    private let titleText = MaterialText(text: SCNText(string:"Garbage Game", extrusionDepth:0.7), material: SCNMaterial())

    //runs when view loads
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
      
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    
        titleText.setColor(UIColor.green)
        
        
        showStartButtonContainer(false, animated: false)
        startButton.setTitle("START THE GAME", for: .normal)
        
        // Set the view's delegate
        sceneView.delegate = self
       
        // Create and pass a text and a material object into our custom class
        titleText.setColor(UIColor.green)

        let nameNode = SCNNode(geometry: titleText.text)
        nameNode.position = SCNVector3(x: -0.05, y: 0.2, z: -3)
        nameNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.1)

        let developerText = MaterialText(text: SCNText(string:"By:inVeNT", extrusionDepth:0.7), material: SCNMaterial())
        developerText.setColor(UIColor.orange)
        
        let developerNode = SCNNode(geometry: developerText.text)
        developerNode.position = SCNVector3(x: -0.05, y: -0.25, z:-3)
        developerNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.1)

        sceneView.scene = garbageScene
        sceneView.scene.rootNode.addChildNode(nameNode)
        sceneView.scene.rootNode.addChildNode(developerNode)
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showStartButtonContainer(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func showStartButtonContainer(_ shouldShow: Bool, animated: Bool) {
        let duration = animated ? 1.0 : 0.0
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.startContainerBottomConstraint.constant = shouldShow ? CGFloat(0.0) :(self?.startButtonContainer.frame.size.height ?? CGFloat(60.0))
            self?.startButtonContainer.alpha = shouldShow ? 1.0 : 0.0
            self?.blockerView.alpha = shouldShow ? 0.5 : 0.0
            self?.view.layoutIfNeeded()
        })
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        sceneView.scene.rootNode.childNodes.forEach { (child) in
            child.removeFromParentNode()
        }
        // Chip sticks
        if let chipSticks = SCNScene(named: "art.scnassets/chips-sticks-open.dae") {
            sceneView.scene = chipSticks
            showStartButtonContainer(false, animated: true)
            adjustNodes()
        }
    }
    
    func adjustNodes() {
        sceneView.scene.rootNode.childNodes.forEach {
            print("node: ", $0)
//            $0.scale = SCNVector3(0.1, 0.1, 0.1)
        }
    }
    
    // MARK: - ARSCNViewDelegate
/*
    Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}



