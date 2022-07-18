/**
 View without content
 ```
 protocol View {
     associatedtype Body: View
     @ViewBuilder var body: Body { get }
 }
 ```
 ```
 extension Never: View {
    var body: Never { fatalError() }
 }
 ```
 ```
 extension NullView: View {
   var body: Never { fatalError() }
 }
 ```
*/
public struct NullView {
    public init() {}
}

public protocol ViewModifier {
    associatedtype Modifiable
    func modify(content: inout Modifiable) // TODO: (container: _)
}
/**
 ```
 extension _ModifiedContent: View where Content: View, Modifier: ViewModifier {}
 ```
 ```
 extension View {
     func modifier<T>(_ modifier: T) -> _ModifiedContent<Self, T> where T.Modifiable == ViewInterpolation.ModifyContent {
         _ModifiedContent(self, modifier: modifier)
     }
 }
 ```
*/
public struct _ModifiedContent<Content, Modifier> {
    public let content: Content
    public let modifier: Modifier

    public init(_ content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}
extension _ModifiedContent: ViewModifier where Content: ViewModifier, Modifier: ViewModifier, Content.Modifiable == Modifier.Modifiable {
    public func modify(content: inout Modifier.Modifiable) {
        self.content.modify(content: &content)
        modifier.modify(content: &content)
    }
}
extension ViewModifier {
    public func concat<T>(_ modifier: T) -> _ModifiedContent<Self, T> {
        _ModifiedContent(self, modifier: modifier)
    }
}
public struct _ConditionalContent<TrueContent, FalseContent> {
    public enum Condition {
        case first(TrueContent)
        case second(FalseContent)
    }
    public let condition: Condition
}

@resultBuilder
public struct ViewBuilder {
    public static func buildBlock() -> NullView { NullView() }
    public static func buildBlock<Content>(_ content: Content) -> Content { content }
    public static func buildOptional<Content>(_ content: Content?) -> Content? { content }
    public static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> _ConditionalContent<TrueContent, FalseContent> {
        _ConditionalContent(condition: .first(first))
    }
    public static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> _ConditionalContent<TrueContent, FalseContent> {
        _ConditionalContent(condition: .second(second))
    }
}

///

public struct Group<Content> {
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}
extension Group {
    public var body: Content { content() }
}

public struct ForEach<Data, Content> where Data: Sequence {
    public let data: Data
    public let content: (Data.Element) -> Content
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
}
