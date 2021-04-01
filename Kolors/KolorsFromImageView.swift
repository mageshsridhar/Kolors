//
//  KolorsFromImageView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import SwiftUI
import ColorThiefSwift
import MobileCoreServices
struct KolorsFromImageView: View {
    func hexStringFromColor(r: UInt8,g: UInt8,b:UInt8) -> String {
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r)), lroundf(Float(g)), lroundf(Float(b)))
        return hexString
     }
    private func saveContext(){
        do{
            try viewContext.save()
        } catch{
            let error = error as NSError
            fatalError("Unresolved Error: \(error)")
        }
    }
    func addKolors(){
        withAnimation(){
        let newKolors = Kolors(context: viewContext)
            newKolors.color1Hex = hexStringFromColor(r: colors![0].r, g: colors![0].g, b: colors![0].b)
            newKolors.color2Hex = hexStringFromColor(r: colors![1].r, g: colors![1].g, b: colors![1].b)
            newKolors.color3Hex = hexStringFromColor(r: colors![2].r, g: colors![2].g, b: colors![2].b)
            newKolors.color4Hex = hexStringFromColor(r: colors![3].r, g: colors![3].g, b: colors![3].b)
            newKolors.color5Hex = hexStringFromColor(r: colors![4].r, g: colors![4].g, b: colors![4].b)
            newKolors.color1R = Double(colors![0].r)
            newKolors.color1B = Double(colors![0].b)
            newKolors.color1G = Double(colors![0].g)
            newKolors.color2R = Double(colors![1].r)
            newKolors.color2B = Double(colors![1].b)
            newKolors.color2G = Double(colors![1].g)
            newKolors.color3R = Double(colors![2].r)
            newKolors.color3B = Double(colors![2].b)
            newKolors.color3G = Double(colors![2].g)
            newKolors.color4R = Double(colors![3].r)
            newKolors.color4B = Double(colors![3].b)
            newKolors.color4G = Double(colors![3].g)
            newKolors.color5R = Double(colors![4].r)
            newKolors.color5B = Double(colors![4].b)
            newKolors.color5G = Double(colors![4].g)
            newKolors.paletteName = paletteName
            newKolors.image = self.image.jpegData(compressionQuality: 0)
            saveContext()
        }
    }
    var image: UIImage
    var colors: [MMCQ.Color]?
    init(image: UIImage){
        self.image = image
        self.colors = ColorThief.getPalette(from: self.image, colorCount: 5)
    }
    @State private var paletteName = ""
    @State private var nameError = false
    @State private var kolorAdded = false
    @Environment(\.managedObjectContext) private var viewContext
    var textfield: some View{
        TextField("Enter a palette name", text: $paletteName).padding().frame(width:UIScreen.main.bounds.width-30).background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")))
    }
    var addButton : some View{
        Button(action:{
            if paletteName==""{
                nameError.toggle()
            }
            else{
                addKolors()
                nameError.toggle()
            }
        }){
            Text("Add Palette to My Kolors Library").foregroundColor(.yellow).padding().frame(width:UIScreen.main.bounds.width-30).background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")))
        }
    }
    var color1 : some View{
        HStack{
            Circle().fill(Color(colors![0].makeUIColor())).frame(width: UIScreen.main.bounds.width/8,height:UIScreen.main.bounds.width/8).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                let color1Hex = hexStringFromColor(r: colors![0].r, g: colors![0].g, b: colors![0].b)
                Text(color1Hex).font(.title3).bold()
                    .onTapGesture(count: 1) {
                            UIPasteboard.general.setValue(color1Hex,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(colors![0].r)").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(colors![0].g)").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(colors![0].b)").font(.caption)
                }
            }
            Spacer()
            
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color2 : some View{
        HStack{
            
            Circle().fill(Color(colors![1].makeUIColor())).frame(width: UIScreen.main.bounds.width/7,height:UIScreen.main.bounds.width/7).padding(.horizontal)
            
            VStack(alignment:.leading,spacing: 6){
                let color2Hex = hexStringFromColor(r: colors![1].r, g: colors![1].g, b: colors![1].b)
                Text(color2Hex).font(.title3).bold()
                    .onTapGesture(count: 1) {
                            UIPasteboard.general.setValue(color2Hex,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(colors![1].r)").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(colors![1].g)").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(colors![1].b)").font(.caption)
                }
            }
            Spacer()
            
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color3 : some View{
        HStack{
            
            Circle().fill(Color(colors![2].makeUIColor())).frame(width: UIScreen.main.bounds.width/7,height:UIScreen.main.bounds.width/7).padding(.horizontal)
            
            VStack(alignment:.leading,spacing: 6){
                let color3Hex = hexStringFromColor(r: colors![2].r, g: colors![2].g, b: colors![2].b)
                Text(color3Hex).font(.title3).bold()
                    .onTapGesture(count: 1) {
                            UIPasteboard.general.setValue(color3Hex,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(colors![2].r)").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(colors![2].g)").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(colors![2].b)").font(.caption)
                }
            }
            Spacer()
            
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color4: some View{
        HStack{
            
            Circle().fill(Color(colors![3].makeUIColor())).frame(width: UIScreen.main.bounds.width/7,height:UIScreen.main.bounds.width/7).padding(.horizontal)
            
            VStack(alignment:.leading,spacing: 6){
                let color4Hex = hexStringFromColor(r: colors![3].r, g: colors![3].g, b: colors![3].b)
                Text(color4Hex).font(.title3).bold()
                    .onTapGesture(count: 1) {
                            UIPasteboard.general.setValue(color4Hex,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(colors![3].r)").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(colors![3].g)").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(colors![3].b)").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color5 : some View{
        HStack{
            
            Circle().fill(Color(colors![4].makeUIColor())).frame(width: UIScreen.main.bounds.width/7,height:UIScreen.main.bounds.width/7).padding(.horizontal)
            
            VStack(alignment:.leading,spacing: 6){
                let color5Hex = hexStringFromColor(r: colors![4].r, g: colors![4].g, b: colors![4].b)
                Text(color5Hex).font(.title3).bold()
                    .onTapGesture(count: 1) {
                            UIPasteboard.general.setValue(color5Hex,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(colors![4].r)").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(colors![4].g)").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(colors![4].b)").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var body: some View {
        ZStack{
            Color("AccentColor").ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    Spacer(minLength: 15)
                    Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width:UIScreen.main.bounds.width-30,height:UIScreen.main.bounds.height/3)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    
                    color1
                    color2
                    color3
                    color4
                    color5
                    textfield
                    addButton
                    Spacer(minLength: 15)
                }.alert(isPresented: $nameError){
                    if paletteName==""{
                        return Alert(title: Text("My Kolors Palette Name"), message: Text("Enter a palette name"), dismissButton: .default(Text("Close")))
                    }
                    else{
                        return Alert(title: Text("My Kolors Library"), message: Text("Kolor Palette added successfully. Check it out in the My Kolors library"), dismissButton: .default(Text("Close")))
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct KolorsFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        KolorsFromImageView(image: UIImage(named: "Image")!)
            .preferredColorScheme(.dark)
    }
}
