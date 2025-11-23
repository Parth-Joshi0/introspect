//
//  CameraBox.swift
//  IntroSpect
//
//  Created by Parth Joshi on 2025-11-23.
//

import SwiftUI

struct CameraBox: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.9))
                .frame(height: 300)
                .shadow(radius: 6)

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 24))

            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
    }
}
