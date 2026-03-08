//
//  TouchCaptureView.swift
//  SprintStart
//
//  Created by Assistant on 3/7/26.
//

import SwiftUI

struct TouchCaptureView: UIViewRepresentable {
    typealias UIViewType = TouchView

    var onTouchCountChange: (Int) -> Void

    func makeUIView(context: Context) -> TouchView {
        let view = TouchView()
        view.onTouchCountChange = onTouchCountChange
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: TouchView, context: Context) {
        uiView.onTouchCountChange = onTouchCountChange
    }

    final class TouchView: UIView {
        var onTouchCountChange: ((Int) -> Void)?
        private var activeTouches: Set<UITouch> = []

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            activeTouches.formUnion(touches)
            onTouchCountChange?(activeTouches.count)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            // Count remains the same unless touches leave the view; UIKit still tracks them
            onTouchCountChange?(activeTouches.count)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            activeTouches.subtract(touches)
            onTouchCountChange?(activeTouches.count)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            activeTouches.subtract(touches)
            onTouchCountChange?(activeTouches.count)
        }
    }
}
