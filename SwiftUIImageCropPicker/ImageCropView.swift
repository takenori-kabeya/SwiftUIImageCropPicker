//
//  ImageCropView.swift
//  SwiftUIImageCropPicker
//
//  Created by Takenori Kabeya on 2023/02/06.
//

import SwiftUI


struct ImageCropView: View {
    @Binding var sourceImage: UIImage?
    @Binding var croppedImage: UIImage?
    @State var paddingTop: CGFloat = 0
    @State var paddingLeft: CGFloat = 0
    @State var paddingBottom: CGFloat = 0
    @State var paddingRight: CGFloat = 0
    
    @State var cropTop: CGFloat = 0
    @State var cropLeft: CGFloat = 0
    @State var cropBottom: CGFloat = 0
    @State var cropRight: CGFloat = 0
    @State var scaledRectWidth: CGFloat = 0
    @State var scaledRectHeight: CGFloat = 0
    var coordinator: ImageCropPicker.Coordinator

    let gripCircleSize: CGFloat = 16
    let screenSizeToImageSizeRatio = 0.7
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                if let image = self.sourceImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: image.size.width < image.size.height ?
                               geometry.size.height * screenSizeToImageSizeRatio / image.size.height * image.size.width :
                                geometry.size.width * screenSizeToImageSizeRatio,
                               height: image.size.width < image.size.height ?
                               geometry.size.height * screenSizeToImageSizeRatio :
                                geometry.size.width * screenSizeToImageSizeRatio / image.size.width * image.size.height)
                        .clipShape(Rectangle())
                        .overlay(cropOperator)
                }
                Spacer()
                HStack {
                    Button(role:.cancel, action: {
                        self.croppedImage = nil
                        if let vc = self.coordinator.cropViewHostingController {
                            vc.dismiss(animated: false)
                        }
                    }, label: { Text("Cancel") })
                        .padding(20)
                    Spacer()
                    Button("Choose", action: {
                        cropImage()
                        if let vc = self.coordinator.cropViewHostingController {
                            vc.dismiss(animated: false)
                            self.coordinator.parent.originalImage = self.croppedImage
                        }
                    })
                        .padding(20)
                }
            }
        }
    }
    
    func cropImage() {
        guard let uiImage = self.sourceImage else {
            return
        }
        guard let cgImage = uiImage.cgImage else {
            return
        }
        let xScale = uiImage.size.width / scaledRectWidth
        let yScale = uiImage.size.height / scaledRectHeight
        let newWidth = xScale * (scaledRectWidth - paddingLeft - paddingRight)
        let newHeight = yScale * (scaledRectHeight - paddingTop - paddingBottom)
        let croppedRect = CGRect(x: paddingLeft * xScale, y: paddingTop * yScale, width: newWidth, height: newHeight)
        guard let croppedImage = cgImage.cropping(to: croppedRect) else {
            return
        }
        self.croppedImage = UIImage(cgImage: croppedImage)
    }
    
    var cropOperator: some View {
        GeometryReader { geometry in
            let scaledRectWidth = geometry.size.width
            let scaledRectHeight = geometry.size.height
            Path { path in
                DispatchQueue.main.async {
                    if self.scaledRectWidth != scaledRectWidth {
                        self.scaledRectWidth = scaledRectWidth
                    }
                    if self.scaledRectHeight != scaledRectHeight {
                        self.scaledRectHeight = scaledRectHeight
                    }
                }
            }
            VStack {
                ZStack {
                    Rectangle() // square to fit image size
                        .stroke(Color(red: 0.8, green: 0.8, blue: 0.8), lineWidth: 2)
                        .padding(EdgeInsets(top: paddingTop, leading: paddingLeft, bottom: paddingBottom, trailing: paddingRight))
                    Rectangle() // square to cover all grip circles
                        .foregroundColor(.gray)
                        .opacity(0.0001)    // when set opacity=0, drag handler will be ignored. so use small value for it.
                        .padding(EdgeInsets(top: paddingTop - gripCircleSize/2, leading: paddingLeft - gripCircleSize/2, bottom: paddingBottom - gripCircleSize/2, trailing: paddingRight - gripCircleSize/2))
                        .gesture(drag)
                    // gray area outside of cropped area
                    ZStack {
                        coverFrame
                            .offset(x:0, y:-scaledRectHeight / 2 + paddingTop / 2)
                            .frame(height: paddingTop < 0 ? 0 : paddingTop)
                        coverFrame
                            .offset(x:0, y:scaledRectHeight / 2 - paddingBottom / 2)
                            .frame(height: paddingBottom < 0 ? 0 : paddingBottom)
                        coverFrame
                            .offset(x:-scaledRectWidth / 2 + paddingLeft / 2, y: (paddingTop - paddingBottom) / 2)
                            .frame(width: paddingLeft < 0 ? 0 : paddingLeft,
                                   height: scaledRectHeight - paddingTop - paddingBottom < 0 ? 0 : scaledRectHeight - paddingTop - paddingBottom)
                        coverFrame
                            .offset(x:scaledRectWidth / 2 - paddingRight / 2, y: (paddingTop - paddingBottom) / 2)
                            .frame(width: paddingRight < 0 ? 0 : paddingRight,
                                   height: scaledRectHeight - paddingTop - paddingBottom < 0 ? 0 : scaledRectHeight - paddingTop - paddingBottom)
                    }
                    // grip circles
                    ZStack {
                        //top-left
                        gripCircle.offset(x: paddingLeft - scaledRectWidth / 2, y: paddingTop - scaledRectHeight / 2)
                        //bottom-left
                        gripCircle.offset(x: paddingLeft - scaledRectWidth / 2, y: -paddingBottom + scaledRectHeight / 2)
                        //top-right
                        gripCircle.offset(x: -paddingRight + scaledRectWidth / 2, y: paddingTop - scaledRectHeight / 2)
                        //bottom-right
                        gripCircle.offset(x: -paddingRight + scaledRectWidth  / 2, y: -paddingBottom + scaledRectHeight / 2)
                        //center-left
                        gripCircle.offset(x: paddingLeft - scaledRectWidth / 2, y: (paddingTop - paddingBottom) / 2)
                        //center-right
                        gripCircle.offset(x: -paddingRight + scaledRectWidth / 2, y: (paddingTop - paddingBottom) / 2)
                        //top-center
                        gripCircle.offset(x: (paddingLeft - paddingRight) / 2, y: paddingTop - scaledRectHeight / 2)
                        //bottom-center
                        gripCircle.offset(x: (paddingLeft - paddingRight) / 2, y: -paddingBottom + scaledRectHeight / 2)
                    }
                }
            }
        }
    }
    
    var coverFrame: some View {
        Rectangle()
            .foregroundColor(.gray)
            .opacity(0.4)
    }
    
    var gripCircle: some View {
        Circle()
            .frame(width: gripCircleSize, height: gripCircleSize)
            .foregroundColor(.gray)
            .opacity(0.5)
    }
    
    var drag: some Gesture {
        return DragGesture()
            .onChanged { gestureValue in
                if let vc = self.coordinator.cropViewHostingController {
                    vc.isModalInPresentation = true
                }
                if (abs(gestureValue.startLocation.x - self.cropLeft) < gripCircleSize) {
                    self.paddingLeft = cropLeft + gestureValue.translation.width
                }
                else if (abs(gestureValue.startLocation.x - (self.scaledRectWidth - self.cropRight)) < gripCircleSize) {
                    self.paddingRight = cropRight - gestureValue.translation.width
                }
                if (abs(gestureValue.startLocation.y - self.cropTop) < gripCircleSize) {
                    self.paddingTop = cropTop + gestureValue.translation.height
                }
                if (abs(gestureValue.startLocation.y - (self.scaledRectHeight - self.cropBottom)) < gripCircleSize) {
                    self.paddingBottom = cropBottom - gestureValue.translation.height
                }
            }
            .onEnded { gestureValue in
                self.cropLeft = self.paddingLeft
                self.cropTop = self.paddingTop
                self.cropRight = self.paddingRight
                self.cropBottom = self.paddingBottom
            }
    }
}

struct CNWImageCropView_Previews: PreviewProvider {
    @State static var image: UIImage? = UIImage(systemName:"scissors.badge.ellipsis")
    @State static var croppedImage: UIImage? = nil
    static var previews: some View {
        ImageCropView(sourceImage: $image,
                    croppedImage: $croppedImage,
                        coordinator: ImageCropPicker.Coordinator(ImageCropPicker(originalImage: $image, croppedImage: $croppedImage)))
    }
}
