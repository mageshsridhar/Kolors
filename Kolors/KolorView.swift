//
//  KolorView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import SwiftUI
import MobileCoreServices
struct KolorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let kolor : FetchedResults<Kolors>.Element
    var color1 : some View{
        HStack{
            Circle().fill(Color(red: kolor.color1R/255, green: kolor.color1G/255, blue: kolor.color1B/255)).frame(width: UIScreen.main.bounds.width/5,height:UIScreen.main.bounds.width/5).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                Text(kolor.color1Hex!).font(.title3).bold()
                    .onTapGesture(count: 1) {
                        UIPasteboard.general.setValue(kolor.color1Hex!,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(Int(kolor.color1R))").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(Int(kolor.color1G))").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(Int(kolor.color1B))").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color2 : some View{
        HStack{
            Circle().fill(Color(red: kolor.color2R/255, green: kolor.color2G/255, blue: kolor.color2B/255)).frame(width: UIScreen.main.bounds.width/5,height:UIScreen.main.bounds.width/5).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                Text(kolor.color2Hex!).font(.title3).bold()
                    .onTapGesture(count: 1) {
                        UIPasteboard.general.setValue(kolor.color2Hex!,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(Int(kolor.color2R))").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(Int(kolor.color2G))").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(Int(kolor.color2B))").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color3 : some View{
        HStack{
            Circle().fill(Color(red: kolor.color3R/255, green: kolor.color3G/255, blue: kolor.color3B/255)).frame(width: UIScreen.main.bounds.width/5,height:UIScreen.main.bounds.width/5).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                Text(kolor.color3Hex!).font(.title3).bold()
                    .onTapGesture(count: 1) {
                        UIPasteboard.general.setValue(kolor.color3Hex!,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(Int(kolor.color3R))").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(Int(kolor.color3G))").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(Int(kolor.color3B))").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color4 : some View{
        HStack{
            Circle().fill(Color(red: kolor.color4R/255, green: kolor.color4G/255, blue: kolor.color4B/255)).frame(width: UIScreen.main.bounds.width/5,height:UIScreen.main.bounds.width/5).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                Text(kolor.color4Hex!).font(.title3).bold()
                    .onTapGesture(count: 1) {
                        UIPasteboard.general.setValue(kolor.color4Hex!,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(Int(kolor.color4R))").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(Int(kolor.color4G))").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(Int(kolor.color4B))").font(.caption)
                }
            }
            Spacer()
        }.padding()
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color("Card")).frame(width:UIScreen.main.bounds.width-30))
    }
    var color5 : some View{
        HStack{
            Circle().fill(Color(red: kolor.color5R/255, green: kolor.color5G/255, blue: kolor.color5B/255)).frame(width: UIScreen.main.bounds.width/5,height:UIScreen.main.bounds.width/5).padding(.horizontal)
            VStack(alignment:.leading,spacing: 6){
                Text(kolor.color5Hex!).font(.title3).bold()
                    .onTapGesture(count: 1) {
                        UIPasteboard.general.setValue(kolor.color5Hex!,
                                forPasteboardType: kUTTypePlainText as String)
                        }
                HStack{
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("R: \(Int(kolor.color5R))").font(.caption)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("G: \(Int(kolor.color5G))").font(.caption)
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("B: \(Int(kolor.color5B))").font(.caption)
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
                    Image(uiImage: UIImage(data: kolor.image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .frame(width:UIScreen.main.bounds.width-30,height:UIScreen.main.bounds.height/3)
                    
                    color1
                    color2
                    color3
                    color4
                    color5
                    Spacer(minLength: 15)
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}

//struct KolorView_Previews: PreviewProvider {
//    static var previews: some View {
//        KolorView()
//    }
//}
