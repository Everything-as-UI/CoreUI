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

///

/**
 ```
 struct ViewWithEnvironmentValue<Content, V>: View where Content: View {
     let keyPath: WritableKeyPath<EnvironmentValues, V>
     let environmentValue: V
     let content: Content

     var body: Never { fatalError() }

     struct ViewInterpolation: ViewInterpolationProtocol {
         public typealias View = ViewWithEnvironmentValue<Content, V>
         public typealias ModifyContent = Content.ViewInterpolation.ModifyContent
         let keyPath: WritableKeyPath<EnvironmentValues, V>
         let value: V
         var base: Content.ViewInterpolation

         public init(_ view: View) {
             self.keyPath = view.keyPath
             self.value = view.environmentValue
             self.base = EnvironmentValues.withValue(view.environmentValue, at: view.keyPath) {
                 Content.ViewInterpolation(view.content)
             }
         }

         public mutating func modify<M>(_ modifier: M) where M : CoreUI.ViewModifier, ModifyContent == M.Modifiable {
             base.modify(modifier)
         }

         public mutating func build() -> Content.ViewInterpolation.Result {
             return EnvironmentValues.withValue(value, at: keyPath) {
                 base.build()
             }
         }
     }
 }

 extension View {
     public func environment<V>(
         _ keyPath: WritableKeyPath<EnvironmentValues, V>,
         _ value: V
     ) -> some View {
         ViewWithEnvironmentValue(keyPath: keyPath, environmentValue: value, content: self)
     }
 }
 ```
*/

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public struct EnvironmentValues {
    private var storage: [ObjectIdentifier: Any]

    public init() {
        self.storage = [:]
    }

    public subscript<Key>(key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get { self.storage[ObjectIdentifier(key)].map { $0 as! Key.Value } ?? Key.defaultValue }
        set { self.storage[ObjectIdentifier(key)] = newValue }
    }
}

extension EnvironmentValues {
    static var global: Self = Self()

    public static func withValue<Value, Result>(_ value: Value, at keyPath: WritableKeyPath<Self, Value>, operation: () -> Result) -> Result {
        let oldValue = global[keyPath: keyPath]
        global[keyPath: keyPath] = value
        let result = operation()
        global[keyPath: keyPath] = oldValue
        return result
    }
}

@propertyWrapper
public struct Environment<Value> {
    let keyPath: KeyPath<EnvironmentValues, Value>

    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: Value {
        EnvironmentValues.global[keyPath: keyPath]
    }
}
