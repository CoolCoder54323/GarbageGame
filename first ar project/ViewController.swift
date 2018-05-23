//
//  ViewController.swift
//  first ar project
//
//  Created by Nicholas Dixon, Thomas , and Jack  on 12/27/17.
//  Copyright © 2017 Nicholas Dixon. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

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

    @IBOutlet weak var pauseButton: UIButton! {
        didSet {
            pauseButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
        }
    }
    @IBOutlet weak var exitButton: UIButton! {
        didSet{
            self.exitButton.setImage(#imageLiteral(resourceName: "exitButton"), for: .normal)
        }
    }
    
    @IBOutlet weak var trashCan: UIImageView!
    @IBOutlet weak var interactionView: UIView!
    @IBOutlet weak var hitLabel: UILabel!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var sceneView: ARSCNView!  //displaying a view of flight camera feed in which we are going to display our 3d objects
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var blockerView: UIView!
    @IBOutlet weak var startButtonContainer: UIView!
    @IBOutlet weak var startContainerBottomConstraint: NSLayoutConstraint!

    let configuration = ARWorldTrackingConfiguration()
    
    private var modelFound: Model?
    private var garbageModels = [Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick"),
                                 Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick"),
                                 Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick"),
                                 Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick"),
                                 Model(filename: "art.scnassets/chips-sticks-open.dae", filter: "stick")]
    
  
    private var startButtonPressed = false
    private var isStartingGame = true
    private var garbageScene = SCNScene()
    private let titleText = MaterialText(text: SCNText(string:"Garbage cleanup", extrusionDepth:1), material: SCNMaterial(), color: UIColor.green)
    private let developerText = MaterialText(text: SCNText(string:"By:inVeNT", extrusionDepth:1), material: SCNMaterial(), color: UIColor.orange)

    
    override func viewDidLoad() {
        super.viewDidLoad()

        configuration.planeDetection = .horizontal
        trashCan.image = #imageLiteral(resourceName: "trashClosed")
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true

        showStartButtonContainer(false, animated: false)
        startButton.setTitle("START THE GAME", for: .normal)

        sceneView.scene.rootNode.addChildNode(titleText.node(scale: SCNVector3(x: 0.01, y: 0.01, z: 0.3), at: SCNVector3(x: -0.05, y: 0.2, z: -3)))
        sceneView.scene.rootNode.addChildNode(developerText.node(scale: SCNVector3(x: 0.01, y: 0.01, z: 0.3), at: SCNVector3(x: -0.05, y: 0.0, z:-3)))
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showStartButtonContainer(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        sceneView.scene.rootNode.childNodes.forEach { (child) in
            child.removeFromParentNode()
        }
        
        load3DGarbageModels(garbageModels)
        showStartButtonContainer(false, animated: true)
        startButtonPressed = true
    }
    
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let model = modelFound, let anchor = model.anchor, let node = model.node else { return }
        sceneView.session.remove(anchor: anchor)
        node.removeFromParentNode()
        restartIfNecessary()
    }
    
    @IBAction func pausePressed(_ sender: Any) {
        if self.pauseButton.imageView?.image == #imageLiteral(resourceName: "pauseButton"){
            self.pauseButton.setImage(#imageLiteral(resourceName: "playButton"), for: .normal)
            self.sceneView.session.pause()
        } else {
            self.pauseButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
            self.sceneView.session.run(configuration)
        }
    }
    
    @IBAction func exitPressed(_ sender: Any) {
        let alertController = UIAlertController.init(title: "Exit", message: "Are you sure you want to exit", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        let exitAction = UIAlertAction(title: "exit" , style: .default) { (_) in
            self.exitApp()
        }

        alertController.addAction(exitAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func exitApp() {
        exit(0)
    }
    
    func load3DGarbageModels(_ models: [Model]) {
        var newXPosition: Float = Float(0.0)
        var newZPosition: Float = Float(1.0)

        let copyOfModels = models
        copyOfModels.forEach { [weak self] (model) in
            guard let sself = self, let currentFrame = sceneView.session.currentFrame, let modelScene = SCNScene(named: model.filename) else { return}
            var translation = matrix_identity_float4x4
            translation.columns.3.x = newXPosition
            translation.columns.3.y = -1.0
            translation.columns.3.z = -newZPosition
            let newTransform = currentFrame.camera.transform * translation
            if let newNode = scaledNode(from: modelScene, scale: model.desiredScale, filteredName: model.filter), let index = sself.garbageModels.index(of: model) {
                garbageModels[index].node = newNode
                let newAnchor = ARAnchor.init(transform: newTransform)
                garbageModels[index].anchor = newAnchor
                sself.sceneView.session.add(anchor: newAnchor)
                sceneView.scene.rootNode.addChildNode(newNode)
            }
            let newposition = arc4random_uniform(3) + 1
            newXPosition += Float(newposition)
            newZPosition += Float(0.2)
        }
    }

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
                tagNode($0)
                node.addChildNode($0)
            }
        return node
    }
    
    func tagNode(_ node: SCNNode) {
        node.name = (node.name ?? "TrashNode") + String(describing: arc4random())
    }
    
    func restartIfNecessary() {
        guard sceneView.scene.rootNode.childNodes.count == 0 else { return }
        startButton.setTitle("START ANOTHER ROUND?", for: .normal)
        showStartButtonContainer(true, animated: true)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let hitResults = sceneView.hitTest(centerView.center, options: nil)
        if !hitResults.isEmpty {
            hitResults.forEach { [weak self] (hitResult) in
                self?.garbageModels.forEach { (garbageModel) in
                    guard let rootNode = garbageModel.node else { return }
                    rootNode.childNodes.forEach({ (node) in
                        if hitResult.node.name == node.name {
                            modelFound = garbageModel
                            hitLabel.text = "Throw AWAY the TRASH"
                            trashCan.image = #imageLiteral(resourceName: "trash")
                        }
                    })
                }
            }

        } else {
            
            if startButtonPressed == true {
                let nodesLeft = sceneView.scene.rootNode.childNodes.count
                if nodesLeft > 0 {
                    let plural = nodesLeft == 1 ? "bag" : "bags"
                    let linkingVerb = nodesLeft == 1 ? "is" : "are"
                    hitLabel.text = String(format: "Find Them (there %@ %ld chip %@ left)", linkingVerb, sceneView.scene.rootNode.childNodes.count,plural)
                } else {
                    hitLabel.text = "You have found and discarded all the chip bags and won the game!!"
                    
                }
            
            }
            trashCan.image = #imageLiteral(resourceName: "trashClosed")
            modelFound = nil

        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        showError(title: "AR Session Failure Error", message: "Please exit the app and try again.")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        showError(title: "AR Session Interrupted", message: "Please press OK and exit the app if necessary.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        showError(title: "AR Session Interruption Ended", message: "Please press OK try again.")
    }

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

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var nodeFound: SCNNode?

        garbageModels.forEach { (garbageModel) in
            if garbageModel.anchor == anchor { nodeFound = garbageModel.node }
        }
        return nodeFound
    }
}



