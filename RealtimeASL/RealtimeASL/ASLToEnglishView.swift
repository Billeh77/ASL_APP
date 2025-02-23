//
//  ASLToEnglishView.swift
//  RealtimeASL
//
//  Created by Emile Billeh on 22/02/2025.
//

import SwiftUI
import AVFoundation

struct ASLToEnglishView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isTranslating = false
    @State private var prediction: String = "–"
    @State private var confidence: Float = 0.0
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraViewModel.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Bottom Control Panel
                VStack {
                    Text(isTranslating ? "Translating..." : "Ready to Translate")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if isTranslating {
                        Text("\(prediction)") // Display the predicted letter
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .padding(.top, 5)
                        
                        Text("Confidence: \(String(format: "%.1f", confidence * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Button(action: {
                            isTranslating.toggle()
                            cameraViewModel.toggleTranslation(isTranslating: isTranslating, updatePrediction: updatePrediction)
                        }) {
                            Text(isTranslating ? "Stop Translation" : "Start Translation")
                                .font(.title3)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTranslating ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: isTranslating ? 220 : 120)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.bottom, 20)
                .padding(.horizontal, 10)
            }
        }
        .onAppear {
            cameraViewModel.startSession()
        }
        .onDisappear {
            cameraViewModel.stopSession()
        }
        .navigationBarHidden(true)
    }
    
    // Update prediction and confidence from ML model
    private func updatePrediction(_ newPrediction: String, _ newConfidence: Float) {
        DispatchQueue.main.async {
            prediction = newPrediction
            confidence = newConfidence
        }
    }
}
