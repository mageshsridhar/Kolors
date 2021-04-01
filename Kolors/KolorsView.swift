//
//  KolorsView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI

struct KolorsView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Kolors.paletteName, ascending: true)]) private var kolors : FetchedResults<Kolors>
    @Environment(\.managedObjectContext) private var viewContext
    private func saveContext(){
        do{
            try viewContext.save()
        } catch{
            let error = error as NSError
            fatalError("Unresolved Error: \(error)")
        }
    }
    private func deleteKolor(offsets: IndexSet){
        withAnimation(){
            offsets.map{ kolors[$0] }.forEach(viewContext.delete)
            saveContext()
        }
        
    }
    var body: some View {
        NavigationView{
            List{
                ForEach(kolors){kolor in
                    NavigationLink(destination: KolorView(kolor: kolor)){
                        HStack{
                            Image(uiImage: UIImage(data: kolor.image!)!).resizable().aspectRatio(contentMode: .fill).clipShape(Circle()).frame(width: 40,height: 40)
                            VStack(alignment: .leading,spacing: 5){
                                Text(kolor.paletteName!)
                                HStack(spacing: 5){
                                    Circle().fill(Color(red: kolor.color1R/255, green: kolor.color1G/255, blue: kolor.color1B/255)).frame(width: 15,height: 15)
                                    Circle().fill(Color(red: kolor.color2R/255, green: kolor.color2G/255, blue: kolor.color2B/255)).frame(width: 15,height: 15)
                                    Circle().fill(Color(red: kolor.color3R/255, green: kolor.color3G/255, blue: kolor.color3B/255)).frame(width: 15,height: 15)
                                    Circle().fill(Color(red: kolor.color4R/255, green: kolor.color4G/255, blue: kolor.color4B/255)).frame(width: 15,height: 15)
                                    Circle().fill(Color(red: kolor.color5R/255, green: kolor.color5G/255, blue: kolor.color5B/255)).frame(width: 15,height: 15)
                                }
                            }
                        }.padding()
                    }
                }.onDelete(perform: deleteKolor)
            }.navigationBarTitle(Text("My Kolors"))
        }
    }
}

struct KolorsView_Previews: PreviewProvider {
    static var previews: some View {
        KolorsView()
    }
}
