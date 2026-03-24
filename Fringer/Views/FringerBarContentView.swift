import SwiftUI

struct FringerBarContentView: View {
    let items: [MenuBarItem]
    let onItemClick: (MenuBarItem) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                Button {
                    onItemClick(item)
                } label: {
                    if let image = item.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
                .help(item.title ?? item.ownerName)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            VisualEffectBlur(material: .menu, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
