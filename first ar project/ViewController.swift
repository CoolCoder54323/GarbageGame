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

    @IBOutlet var sceneView: ARSCNView!//displaying a veiw of flight camerea feed in which we are going to display our 3d objects
    
    var isStartingGame = true
    
   //runs when view loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
       
        // Create and pass a text and a material object into our custom class
        let materialText = MaterialText(text: SCNText(string:"By:inVeNT", extrusionDepth:0.1),material: SCNMaterial())
        materialText.setColor(UIColor.orange)
        
        let node = SCNNode()
        
        node.position = SCNVector3(x: 0.05, y: -0.25, z:-3)
        node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.1)
        node.geometry = materialText.text
        
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.autoenablesDefaultLighting = true
        
        
        let text = SCNText(string: "Garbage Game ", extrusionDepth: 1)//extrusiondepth is the thickness of the object
        
        
        let materialtwo = SCNMaterial()//creates a material object
        
        materialtwo.diffuse.contents = UIColor.green//turns it a color
   
        
        text.materials = [materialtwo]//makes the objct into your text
    
        let nodetwo = SCNNode()
        
        nodetwo.position = SCNVector3(x: 0.02, y: 0.2, z: -3)
        nodetwo.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.1)
        nodetwo.geometry = text
    
        sceneView.scene.rootNode.addChildNode(nodetwo)
        sceneView.autoenablesDefaultLighting = true
    
        if isStartingGame {
            presentStartGameView()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func presentStartGameView() {
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
            let startVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "StartGameVC")
            self.present(startVC, animated: true)
            timer.invalidate()
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
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



