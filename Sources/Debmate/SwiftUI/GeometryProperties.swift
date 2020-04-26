//
//  File.swift
//  
//
//  Created by David Baraff on 4/15/20.
//

import SwiftUI

public enum GeometryProperties {
    /// Extract the width of a view.
    public struct WidthReader: View {
        let setter: (CGFloat) -> ()
        
        public init(setter: @escaping (CGFloat) -> ()) {
            self.setter = setter
        }
        
        public var body: some View {
            GeometryReader { proxy -> AnyView in
                self.setter(proxy.size.width)
                return Color.clear.anyView()
            }
        }
    }

    /// Extract the height of a view.
    public struct HeightReader: View {
        let setter: (CGFloat) -> ()
        
        public init(setter: @escaping (CGFloat) -> ()) {
            self.setter = setter
        }
        
        public var body: some View {
            GeometryReader { proxy -> AnyView in
                self.setter(proxy.size.height)
                return Color.clear.anyView()
            }
        }
    }

    /// Extract the size of a view.
    public struct SizeReader: View {
        let setter: (CGSize) -> ()
        
        public init(setter: @escaping (CGSize) -> ()) {
            self.setter = setter
        }
        
        public var body: some View {
            GeometryReader { proxy -> AnyView in
                self.setter(proxy.size)
                return Color.clear.anyView()
            }
        }
    }
    
    /// Extract the size of a view.
    public struct RectReader: View {
        let setter: (CGRect) -> ()
        
        public init(setter: @escaping (CGRect) -> ()) {
            self.setter = setter
        }
        
        public var body: some View {
            GeometryReader { proxy -> AnyView in
                self.setter(proxy.frame(in: .global))
                return Color.clear.anyView()
            }
        }
    }

    // Return the width of some text
    public struct TextWidthReader: View {
        let text: String
        let setter: (CGFloat) -> ()
        let font: Font?

        public init(_ text: String, font: Font? = nil, setter: @escaping (CGFloat) -> ()) {
            self.text = text
            self.font = font
            self.setter = setter
        }

        public var body: some View {
            Text(text).font(font ?? .body).fixedSize().background(WidthReader(setter: self.setter)).hidden()
        }
    }
}

