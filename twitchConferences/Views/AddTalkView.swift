//
//  AddTalkView.swift
//  twitchConferences
//
//  Created by Sam Patzer on 7/22/19.
//  Copyright © 2019 wizage. All rights reserved.
//

import SwiftUI

struct AddTalkView : View {
    @Binding var talk : CreateTalkInput
    @EnvironmentObject var talkStore : TalkStore
    @Binding var isShowing : StateOfCreation
    var body: some View {
        Text("Hello World")
    }
}

#if DEBUG
struct AddTalkView_Previews : PreviewProvider {
    static var previews: some View {
        AddTalkView()
    }
}
#endif
