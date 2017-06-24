//
//  ViewController.swift
//  WhatIsThat
//
//  Created by Mars on 21/06/2017.
//  Copyright © 2017 Mars. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var photoSelected: UIImageView!
    @IBOutlet weak var probability: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    @IBAction func grabAPicture(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Take a photo", style: .default, handler: {
            _ in
            self.takePhoto(from: .camera)
        })
        let libraryAction = UIAlertAction(title: "Choose from Photos", style: .default, handler: {
            _ in
            self.takePhoto(from: .photoLibrary)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    enum PhotoSource {
        case camera, photoLibrary
    }
    
    func takePhoto(from source: PhotoSource) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = (source == .camera ? .camera : .photoLibrary)
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func resize(image: UIImage, to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension ViewController {
    func guess(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Cannot create a core image object.")
        }
        
        // 1. Load model
        guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
            fatalError("Cannot load CoreML model.")
        }
        
        // 2. Create a Vision request
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let results = request.results as? [VNClassificationObservation],
                let firstResult = results.first else {
                fatalError("Cannot fetch result from VNCoreMLRequest...")
            }
            
            DispatchQueue.main.async {
                self.descriptionLabel.text = firstResult.identifier
                self.probability.text = "\(firstResult.confidence * 100)"
            }
        }
        
        // 3. Perform the request
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            photoSelected.image = image
            
            if let newImage = resize(image: image, to: CGSize(width: 224, height: 224)) {
                guess(image: newImage)
            }
            
        }
    }
}


