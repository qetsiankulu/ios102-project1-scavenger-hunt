//
//  TaskDetailViewController.swift
//  PhotoScavengerHunt
//
//  Created by Qetsia Nkulu on 03/01/22
//

//
//        // if the app does not have authorization, request photo library access
//        // else show the image picker
//        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
//            // request photo library access
//            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
//                switch status {
//                case .authorized:
//                    // the user authorized access to their photo library
//                    // show picker (on the main thread)
//                    DispatchQueue.main.async {
//                        self?.presentImagePicker()
//                    }
//                default:
//                    // show settings alert (on main thread)
//                    DispatchQueue.main.async {
//                        // helper method to show alert settings alert
//                        self?.presentGoToSettingsAlert()
//                    }
//                }
//            }
//        } else {
//            // show the photo picker
//            presentImagePicker()
//        }

import UIKit
import MapKit
import PhotosUI
import CoreImage
import AVFoundation
import CoreLocation
import Photos

class TaskDetailViewController: UIViewController, PHPickerViewControllerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet private weak var completedImageView: UIImageView!
    @IBOutlet private weak var completedLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var attachPhotoButton: UIButton!
    
    // MapView outlet
    @IBOutlet private weak var mapView: MKMapView!
    
    var task: Task!
    // Location manager for obtaining location information
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 7a: Use a custom annotation view to display the annotation
        // TODO: Register custom annotation view
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)
        
        // TODO: Set mapView delegate
        mapView.delegate = self
        
        // UI Candy
        mapView.layer.cornerRadius = 12
        
        
        updateUI()
        updateMapView()
        
    }
    
//    func requestLocationPermissions() {
//        // Use the main thread to check if location services are enabled
//        DispatchQueue.main.async {
//            if CLLocationManager.locationServicesEnabled() {
//                self.locationManager.delegate = self
//                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//
//                // Wait for the `-locationManagerDidChangeAuthorization` callback
//                // Authorization status will be checked in the delegate method
//                self.locationManager.requestWhenInUseAuthorization()
//            } else {
//                // Handle the case where location services are not enabled
//                print("Location services are not enabled.")
//            }
//        }
//    }
    
    func requestLocationPermissions() {
        // Ensure that the check is performed on the main thread
        DispatchQueue.main.async {
            let status = CLLocationManager.authorizationStatus()

            switch status {
            case .notDetermined:
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

                // Wait for the `-locationManagerDidChangeAuthorization` callback
                // Authorization status will be checked in the delegate method
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                // Location access already granted, proceed with necessary actions
                print("Location access granted.")
                // You can start updating location or perform other actions here
            case .denied, .restricted:
                // Location access denied or restricted, handle accordingly
                print("Location access denied or restricted.")
                // You may want to show an alert or guide the user to settings
            default:
                // Handle any future cases
                print("Unknown authorization status.")
            }
        }
    }


    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        
        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")
        
        // calling `withRenderingMode(.alwaysTemplate)` on an image allows for coloring the image via it's `tintColor` property.
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)
        completedLabel.text = task.isComplete ? "Complete" : "Incomplete"
        
        let color: UIColor = task.isComplete ? .systemBlue : .tertiaryLabel
        completedImageView.tintColor = color
        completedLabel.textColor = color
        
        mapView.isHidden = !task.isComplete
        attachPhotoButton.isHidden = task.isComplete
    }
  

    
    // Step 1 : Get Authorization to access the user's photo library or take a picture using the camera
    @IBAction func didTapAttachPhotoButton(_ sender: Any) {
        
        // Request location permissions
        requestLocationPermissions()
        
        // get photo library authorization status
        let photoLibraryAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // check camera authorization status
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch (photoLibraryAuthorizationStatus, cameraAuthorizationStatus) {
        case (.authorized, .authorized):
            // Both photo library and camera access are authorized, show options to the user
            showPhotoSourceSelection()
            
        case (.notDetermined, .notDetermined):
            // request photo library access and camera access
            requestAuthorization(for: .readWrite){ [weak self] photoLibraryAuthorized in
                if photoLibraryAuthorized {
                    self?.requestCameraAccess()
                } else {
                    self?.presentGoToSettingsAlert()
                }
            }
        case (.authorized, .notDetermined):
            // request camera access only
            requestCameraAccess()
            
        case (.notDetermined, .authorized):
            // request photo library access only
            // request photo library access and camera access
            requestAuthorization(for: .readWrite){ [weak self] photoLibraryAuthorized in
                if photoLibraryAuthorized {
                    self?.requestCameraAccess()
                } else {
                    self?.presentGoToSettingsAlert()
                }
            }
            
        default:
            // authorization denied for at least one of the sources, show settings alert
            presentGoToSettingsAlert()
        }
    }
    
    private func requestAuthorization(for type: PHAccessLevel, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: type) { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    

    // Helper function to request camera access by the user
    func requestCameraAccess() {
        // Check camera authorization access
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { [weak self] cameraGranted in
                DispatchQueue.main.async {
                    if cameraGranted {
                        // Camera access granted, show options to the user
                        self?.showPhotoSourceSelection()
                    } else {
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        case .authorized:
            // Camera access already authorized, show options to the user
            DispatchQueue.main.async {
                self.showPhotoSourceSelection()
            }
        case .denied, .restricted:
            // Camera access denied or restricted, show settings alert
            DispatchQueue.main.async {
                self.presentGoToSettingsAlert()
            }
        default:
            break
        }
    }
    
    func showPhotoSourceSelection() {
        // Present an action sheet or any UI to let the user choose between photo library and camera
        let actionSheet = UIAlertController(title: "Select Photo Source", message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })

        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCameraPicker()
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true, completion: nil)
    }
    
    // function to handle the camera picjer
    func presentCameraPicker() {
        let cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        cameraPicker.delegate = self
        
        present(cameraPicker, animated: true, completion: nil)
    }

    // Step 2: Create, setup and present the image picker
    private func presentImagePicker() {
    // Create, configure and present image picker.
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    
        // set the filter to only show images as options (i.e. no video, etc)
        config.filter = .images
        
        // request the original file format. Fastest method as it avoids transcoding
        config.preferredAssetRepresentationMode = .current
        
        // only allow 1 image to be selected at a time
        config.selectionLimit = 1
        
        // Instantiate a picker, passing in the configuration
        let picker = PHPickerViewController(configuration: config)
        
        // set the picker delegate so we can receive whatever image the user picks
        picker.delegate = self
        
        // present the picker
        present(picker, animated: true)
    }
    
    // Step 3a: Get the location metadata from the chosen photo in the photo library
    // TODO: Conform to PHPickerViewControllerDelegate + implement required method(s)
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // dismiss the picker
        picker.dismiss(animated: true)
        
        // get the selected image asset
        let result = results.first // grab the 1st item in the array since we only allowed a selection of 1
        
        // get image location
        // PHAsset contains metadata about an image
        guard let assetId = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject?.location else {
            return
        }
        
        print("📍 Image location coordinate: \(location.coordinate)")
        
        // Step 4: Get the image from the chosen photo
        guard let provider = result?.itemProvider,
                // make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        // load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            
            // handle any errors
            if let error = error {
                DispatchQueue.main.async { [weak self] in self?.showAlert(for: error)}
            }
            
            // make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else { return }
            
            print("🌉 We have an image from the camera roll!")
            
            // UI updates should be done on main thread
            DispatchQueue.main.async { [weak self] in
                
                // set the picked image and location on the task
                self?.task.set(image, with: location)
                
                // update the UI since we've updated the task
                self?.updateUI()
                
                // update the map view since we now have a location
                self?.updateMapView()
                
                // move the map view to the image annotation
                self?.moveMapToImageAnnotation(location.coordinate)
            }
            
        }
    
    }
    
    // Step 3b: Get the location metadata from the picture taken with the camera
    // Function to handle the image picker result
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let cameraImage = info[.originalImage] as? UIImage else {
            print("🌉 We have an image from the camera!")
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        if let location = CLLocationManager().location {
        
            print("📍 Image location coordinate: \(location.coordinate)")
            
            // Handle the picked image and location metadata
            DispatchQueue.main.async { [weak self] in
                self?.task.set(cameraImage, with: location)
                self?.updateUI()
                self?.updateMapView()
                
                // No need for optional binding here, coordinate is not optional
                let coordinate = location.coordinate
                self?.moveMapToImageAnnotation(coordinate)
            }
        } else {
            print("Location is nil.")
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    // a MKCoordinateRegion is created based on the selected coordinate,
    // and then it sets the map view's region to that region with animation
    // this helper function allows for the map view to move to the image annotation
    // helpful for when the selected image is not in North America
    func moveMapToImageAnnotation(_ coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }

    // Step 5: Setup the map view
    func updateMapView() {
        // TODO: Set map viewing region and scale
        // make sure the task has image location
        guard let imageLocation = task.imageLocation else { return }
        
        // get the coordinate from the location
        let coordinate = imageLocation.coordinate
        
        // set the map's view region based on the coordinate of the image
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        // Step 6: Add an annotation
        // TODO: Add annotation to map view
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    // Step 7b: Use a custom annotation view to display the annotation
    // TODO: Conform to MKMapKitDelegate + implement mapView(_:viewFor:) delegate method.
    // Implement mapView(_:viewFor:) delegate method.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Dequeue the annotation view for the specified reuse identifier and annotation.
        // Cast the dequeued annotation view to your specific custom annotation view class, `TaskAnnotationView`
        // 💡 This is very similar to how we get and prepare cells for use in table views.
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TaskAnnotationView.identifier, for: annotation) as? TaskAnnotationView else {
            fatalError("Unable to dequeue TaskAnnotationView")
        }

        // Configure the annotation view, passing in the task's image.
        annotationView.configure(with: task.image)
        return annotationView
    }

}


// Helper methods to present various alerts
extension TaskDetailViewController {

    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}
