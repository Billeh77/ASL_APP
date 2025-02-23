//
//  ContentView.swift
//  RealtimeASL
//
//  Created by Emile Billeh on 22/02/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Welcome message with emojis
                Text("👋 Welcome to Realtime ASL! 🤟")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                Text("Translate ASL in real-time using your camera 📷")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Spacer()

                // Navigation buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: ASLToEnglishView()) {
                        Text("🖐️ ASL to English")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }

                    NavigationLink(destination: EnglishToASLView()) {
                        Text("🔠 English to ASL")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true) // Hide nav bar for a clean look
        }
    }
}

#Preview {
    ContentView()
}
