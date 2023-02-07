//
//  ImageCropPicker.swift
//  SwiftUIImageCropPicker
//
//  Created by Takenori Kabeya on 2023/02/06.
//

//  With the simulator, the first flower image causes the error.
//  This is a known issue.
//  see https://developer.apple.com/forums/thread/666338

import SwiftUI
import PhotosUI



class ImageCropViewHostingController: UIHostingController<ImageCropView> {
    var picker: PHPickerViewController?
    var parentViewCoordinator: ImageCropPicker.Coordinator?
    
    required init?(coder: NSCoder) {
        self.parentViewCoordinator = nil
        super.init(coder: coder)
    }
    
    init(picker: PHPickerViewController, parentViewCoordinator: ImageCropPicker.Coordinator, rootView: ImageCropView) {
        self.picker = picker
        self.parentViewCoordinator = parentViewCoordinator
        super.init(rootView: rootView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // when choose button is pressed
        if (rootView.croppedImage != nil) {
            if let safePicker = self.picker {
                safePicker.dismiss(animated: true)
            }
        }
        else {
            // when cancell button is pressed
            // it mgiht be better to deselect images but PHPickerViewController.deselectAssets requires identifiers. (and identifiers in didFinishPicking results might be nil)
            // so it seems to be impossible to deselect
        }
    }
}

struct ImageCropPicker: UIViewControllerRepresentable {
    @State var pickedImage: UIImage? = nil
    @Binding var originalImage: UIImage?
    @Binding var croppedImage: UIImage?
    var filter: PHPickerFilter = .images
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImageCropPicker
        var cropViewHostingController: ImageCropViewHostingController? = nil
        
        init(_ parent: ImageCropPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                picker.dismiss(animated: true)
                parent.croppedImage = nil
                return
            }
            if !provider.canLoadObject(ofClass: UIImage.self) {
                picker.dismiss(animated: true)
                parent.croppedImage = nil
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage else {
                    self?.parent.croppedImage = nil
                    return
                }
                DispatchQueue.main.async {
                    self?.parent.pickedImage = image
                    self?.parent.croppedImage = nil
                    self?.showCropView(picker)
                }
            }
        }
        
        func showCropView(_ picker: PHPickerViewController) {
            let viewControllerToPresent = ImageCropViewHostingController(picker: picker,
                                                                         parentViewCoordinator: self,
                                                                         rootView: ImageCropView(sourceImage: self.parent.$pickedImage,
                                                                                                 croppedImage: self.parent.$croppedImage,
                                                                                                 coordinator: self))
            self.cropViewHostingController = viewControllerToPresent
            if let sheet = viewControllerToPresent.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            picker.present(viewControllerToPresent, animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        //config.preferredAssetRepresentationMode = .automatic
        let viewController = PHPickerViewController(configuration: config)
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
}
