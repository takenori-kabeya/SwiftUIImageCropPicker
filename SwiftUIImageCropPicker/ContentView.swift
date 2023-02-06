//
//  ContentView.swift
//  SwiftUIImageCropPicker
//
//  Created by Takenori Kabeya on 2023/02/06.
//

import SwiftUI

struct ContentView: View {
    @State private var isPickerVisible: Bool = false
    @State private var originalImage: UIImage? = UIImage(systemName: "scissors")
    @State private var croppedImage: UIImage? = nil
    
    var body: some View {
        VStack {
            Button("Pick!", action: {
                isPickerVisible.toggle()
            })
            if let uiImage = self.sourceImage {
                if let cgImage = uiImage.cgImage {
                    Image(cgImage, scale: 1, orientation: .up, label: Text(""))
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                        .clipShape(Rectangle())
                }
            }
            else {
                Rectangle()
                    .stroke(lineWidth:2)
                    .frame(width: 100, height: 100)
            }
        }
        .padding()
        .sheet(isPresented: $isPickerVisible) {
            ImageCropPicker(originalImage: $originalImage, croppedImage: $croppedImage)
        }
    }
    
    var sourceImage: UIImage? {
        if let uiImage = self.croppedImage {
            return uiImage
        }
        if let uiImage = self.originalImage {
            return uiImage
        }
        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
