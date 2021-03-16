//
//  File.swift
//  
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation
import SwiftUI



struct AsyncExecutionModalView : View {
    var body: some View {
        VStack {
            Text("hi")
        }.frame(width: 300, height:200)
        .background(Color.systemBackground)
        .cornerRadius(12)
    }
}

struct AsyncExecutionModealView_Previews: PreviewProvider {
    static var previews: some View {
        TestViews.CoveredScreen(color: Color(white: 0.1)) {
            AsyncExecutionModalView()
        }.environment(\.colorScheme, .light)
    }
}

