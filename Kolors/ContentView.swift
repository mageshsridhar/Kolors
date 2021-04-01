//
//  ContentView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import ColorThiefSwift

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var body: some View{
        TabView{
            ImageView().environment(\.managedObjectContext, viewContext).tabItem { Label(
                title: { Text("Image") },
                icon: { Image(systemName: "photo") }
            ) }
            KolorsView().environment(\.managedObjectContext, viewContext).tabItem { Label(
                title: { Text("Library") },
                icon: { Image(systemName: "paintpalette") }
            ) }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
