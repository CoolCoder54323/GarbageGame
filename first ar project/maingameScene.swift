//
//  maingameScene.swift
//  first ar project
//
//  Created by Nicholas Dixon on 1/7/18.
//  Copyright © 2018 Nicholas Dixon. All rights reserved.
//

import ARKit

class maingameScene: SKScene {

    var sceneView: ARSKView {
        return view as! ARSKView
    }

    var isWorldSetup = false

    private func setupWorld() {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        isWorldSetup = true
    
    }







}



