//
//  ImageView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import ColorThiefSwift

struct ImageView: View {
    @State var showImagePicker: Bool = false
    @State var image: UIImage?
    @State var showCamera : Bool = false
    var body: some View {
            NavigationView {
                ZStack{
                    Color("AccentColor").ignoresSafeArea()
                        VStack(spacing: 10) {
                            if image != nil {
                                Image(uiImage: image!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                                    .frame(width:UIScreen.main.bounds.width-30,height:UIScreen.main.bounds.height/3)
                                    
                                NavigationLink(destination: KolorsFromImageView(image: image!)){
                                        HStack  {
                                            Image(systemName:"paintpalette")
                                            Text("Get Kolor Palette")
                                        }.foregroundColor(.yellow)
                                        .frame(width: UIScreen.main.bounds.width-30,height: UIScreen.main.bounds.height/12)
                                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color("Card")))
                                    }
                                Button(action: {
                                    withAnimation(.spring()){
                                        self.image = nil
                                    }
                                    
                                }){
                                    HStack{
                                        Image(systemName:"xmark.circle")
                                        Text("Reset image")
                                    }.foregroundColor(.red)
                                    .frame(width: UIScreen.main.bounds.width-30,height:UIScreen.main.bounds.height/12)
                                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color("Card")))
                                }
                            }
                            Button(action: {self.showCamera.toggle()}){
                                HStack{
                                    Image(systemName:"camera")
                                    Text("Capture an image")
                                }.foregroundColor(.yellow)
                                .frame(width: UIScreen.main.bounds.width-30,height: image != nil ? UIScreen.main.bounds.height/12 : UIScreen.main.bounds.height/3)
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color("Card")))
                            }
                            NavigationLink(destination: ImagePickerView(sourceType: .photoLibrary){
                                    image in
                                withAnimation(.spring()){
                                    self.image = image
                                }
                            }.navigationBarHidden(true)){
                                    HStack  {
                                        Image(systemName:"photo")
                                        Text("Choose from Photo Library")
                                    }.foregroundColor(.yellow)
                                    .frame(width: UIScreen.main.bounds.width-30,height: image != nil ? UIScreen.main.bounds.height/12 : UIScreen.main.bounds.height/3)
                                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color("Card")))
                                }
                            Spacer()
                        }.fullScreenCover(isPresented: $showCamera){
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                ImagePickerView(sourceType: .camera) { image in
                                    withAnimation(.spring()){
                                        self.image = image
                                    }
                                    
                                }
                            }
                            else{
                                ImagePickerView(sourceType: .photoLibrary) { image in
                                    withAnimation(.spring()){
                                        self.image = image
                                    }
                                }
                            }
                        }.navigationBarTitle(Text("Kolors"))
                    
                }
            
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .preferredColorScheme(.light)
    }
}
