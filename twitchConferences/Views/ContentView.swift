//
//  ContentView.swift
//  twitchConferences
//
//  Created by Sam Patzer on 7/22/19.
//  Copyright © 2019 wizage. All rights reserved.
//

import SwiftUI
enum StateOfCreation {
    case save
    case dismiss
    case hide
    case show
}

struct ContentView : View {
    @State var shouldCreate : StateOfCreation = .hide
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello World!"/*@END_MENU_TOKEN@*/)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
