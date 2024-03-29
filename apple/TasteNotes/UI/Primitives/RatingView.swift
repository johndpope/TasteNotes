import SwiftUI

struct RatingView: View {
    let rating: Double
    @State private var starSize: CGSize = .zero
    @State private var controlSize: CGSize = .zero
    @GestureState private var dragging: Bool = false

    var body: some View {
        ZStack {
            HStack {
                ForEach(0..<Int(rating), id: \.self) { idx in
                    fullStar
                }

                if (rating != floor(rating)) {
                    halfStar
                }

                ForEach(0..<Int(Double(5) - rating), id: \.self) { idx in
                    emptyStar
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ControlSizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(StarSizeKey.self) { size in
                starSize = size
            }
            .onPreferenceChange(ControlSizeKey.self) { size in
                controlSize = size
            }

            Color.clear
                .frame(width: controlSize.width, height: controlSize.height)
                .contentShape(Rectangle())
        }
    }

    private var fullStar: some View {
        Image(systemName: "star.fill")
            .star(size: starSize)
            .foregroundColor(.yellow)
    }

    private var halfStar: some View {
        Image(systemName: "star.leadinghalf.fill")
            .star(size: starSize)
            .foregroundColor(.yellow)
    }

    private var emptyStar: some View {
        Image(systemName: "star")
            .star(size: starSize)
    }

}

fileprivate extension Image {
    func star(size: CGSize) -> some View {
        return self
            .font(.title)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: StarSizeKey.self, value: proxy.size)
                }
            )
            .frame(width: size.width, height: size.height)
    }
}

fileprivate protocol SizeKey: PreferenceKey { }
fileprivate extension SizeKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        value = CGSize(width: max(value.width, next.width), height: max(value.height, next.height))
    }
}

fileprivate struct StarSizeKey: SizeKey {}
fileprivate struct ControlSizeKey: SizeKey { }
