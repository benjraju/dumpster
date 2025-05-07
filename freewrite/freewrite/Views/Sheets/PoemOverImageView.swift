import SwiftUI

struct PoemOverImageView: View {
    let poemText: String
    let image: UIImage

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            VStack {
                Spacer()
                Text(poemText)
                    .font(.custom("Lato-Regular", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                Spacer()
            }
            .padding(.horizontal, 10)

        }
        .frame(maxWidth: .infinity)
        .aspectRatio(nil, contentMode: .fit)
        .frame(minHeight: 300, maxHeight: 500)
        .cornerRadius(20)
        .clipped()
    }
}

#if DEBUG
struct PoemOverImageView_Previews: PreviewProvider {
    static var previews: some View {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let dummyImage = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white
            ]
            let string = "Landscape Image"
            string.draw(with: CGRect(x: 20, y: 120, width: 360, height: 60), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }
        
        PoemOverImageView(
            poemText: "Across the wide expanse it flows,\nA gentle whisper, soft it goes.\nWith hues of dawn and twilight's gleam,\nA fleeting thought, a vivid dream.",
            image: dummyImage
        )
        .padding(20)
        .background(Color.gray.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}
#endif 