//
//  OnboardingItemLayout.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI

struct OnboardingItemLayout<ImageView: View, InfoPopoverContent: View, Content: View, ActionView: View>: View {
    @State private var instructionsPopoverPresented = false

    private let title: LocalizedStringKey
    private let image: () -> ImageView
    private let actionView: () -> ActionView
    private let description: LocalizedStringKey
    

    private let infoPopoverContent: () -> InfoPopoverContent
    private let showInfoIcon: Bool
    private let content: () -> Content
    

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        @ViewBuilder image: @escaping () -> ImageView,
        @ViewBuilder actionView: @escaping () -> ActionView,
        @ViewBuilder infoPopoverContent: @escaping () -> InfoPopoverContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.image = image
        self.actionView = actionView
        self.description = description
        self.infoPopoverContent = infoPopoverContent
        self.showInfoIcon = true
        self.content = content
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        @ViewBuilder image: @escaping () -> ImageView,
        @ViewBuilder actionView: @escaping () -> ActionView,
        @ViewBuilder content: @escaping () -> Content
    ) where InfoPopoverContent == EmptyView {
        self.title = title
        self.image = image
        self.description = description
        self.infoPopoverContent = { EmptyView() }
        
        self.actionView = actionView
        self.showInfoIcon = false
        self.content = content
    }

    var body: some View {
        HStack(spacing: 12) {

            content()
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .fontWeight(.medium)
                    if showInfoIcon {
                        Button {
                            instructionsPopoverPresented.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $instructionsPopoverPresented, arrowEdge: .bottom) {
                            infoPopoverContent()
                                .padding()
                                .frame(maxWidth: 400, alignment: .topLeading)
                        }
                    }
                    Spacer()
                    
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            actionView()
        

        }
    }
}
