import CoreUI
/**
 ```
 protocol View {
     associatedtype ViewInterpolation: ViewInterpolationProtocol = DefaultViewInterpolation<Self> where ViewInterpolation.View == Self
     associatedtype Body: View
     var body: View { get }
 }
 ```
 ```
 struct DefaultViewInterpolation<V>: ViewInterpolationProtocol where V: View {
     typealias View = V
     typealias ModifyContent = V.Body.ViewInterpolation.ModifyContent
     var base: View.Body.ViewInterpolation
     init(_ view: View) {
         self.base = View.Body.ViewInterpolation(view.body)
     }
     mutating func modify<M>(_ modifier: M) where M : ViewModifier, ModifyContent == M.Modifiable {
         base.modify(modifier)
     }
     mutating func build() -> View.Body.ViewInterpolation.Result {
         base.build()
     }
 }
 ```
 ```
 extension View {
     func modifier<T, P>(_ modifier: T, proxy: (Self) -> P) -> _ModifiedContent<P, T> where P: View, T.Modifiable == P.Interpolation.ModifyContent {
         _ModifiedContent(self, modifier: modifier)
     }
 }
 ```
 */
public protocol ViewInterpolationProtocol {
    associatedtype View
    init(_ view: View) // TODO: Can it be removed from public?
    associatedtype ModifyContent // RENAME: ModificationsContainer?
    mutating func modify<M>(_ modifier: M) where M: ViewModifier, M.Modifiable == ModifyContent
    associatedtype Result
    mutating func build() -> Result
}

class _AnyInterpolation_<ModifyContent, Result> {
    func modify<M>(_ modifier: M) where M : ViewModifier, ModifyContent == M.Modifiable { fatalError() }
    func build() -> Result { fatalError() }
}
final class _AnyInterpolation<Interpolation>: _AnyInterpolation_<Interpolation.ModifyContent, Interpolation.Result> where Interpolation: ViewInterpolationProtocol {
    var base: Interpolation
    init(base: Interpolation) { self.base = base }
    override func modify<M>(_ modifier: M) where M : ViewModifier, M.Modifiable == Interpolation.ModifyContent { base.modify(modifier) }
    override func build() -> Interpolation.Result { base.build() }
}
/**
 ```
 public struct AnyView: View {
     let interpolation: AnyInterpolation<ModifyContent, Result>
     public init<T>(_ view: T) where T: View, T.ViewInterpolation.ModifyContent == ModifyContent {
         self.interpolation = AnyInterpolation(T.ViewInterpolation(view))
     }
     public var body: Never { fatalError() }
     public struct ViewInterpolation: ViewInterpolationProtocol {
         let view: AnyView
         public init(_ view: AnyView) {
             self.view = view
         }
         public mutating func modify<M>(_ modifier: M) where M : ViewModifier, ModifyContent == M.Modifiable {
             view.interpolation.modify(modifier)
         }
         public func build() -> Result {
             view.interpolation.build()
         }
     }
 }
 ```
 */
public struct AnyInterpolation<ModifyContent, Result>/*: ViewInterpolationProtocol*/ {
    let base: _AnyInterpolation_<ModifyContent, Result>
    public init<I>(_ base: I) where I: ViewInterpolationProtocol, I.ModifyContent == ModifyContent, I.Result == Result {
        self.base = _AnyInterpolation(base: base)
    }
    public func modify<M>(_ modifier: M) where M : ViewModifier, ModifyContent == M.Modifiable {
        base.modify(modifier)
    }
    public func build() -> Result { base.build() }
}

/**
 ```
 public struct TupleView<T>: View {
     let build: () -> [Result]
     public var body: Never { fatalError() }
     public struct ViewInterpolation: ViewInterpolationProtocol {
         public typealias View = TupleView<T>
         public typealias ModifyContent = SomeViewAttributes
         let view: TupleView<T>
         var attributes: SomeViewAttributes
         public init(_ view: TupleView<T>) {
             self.view = view
             self.attributes = SomeViewAttributes()
         }
         public mutating func modify<M>(_ modifier: M) where M : ViewModifier, ModifyContent == M.Modifiable {
             modifier.modify(content: &attributes)
         }
         public mutating func build() -> Result {
             Result(nestedResult: document.build(), attributes: attributes)
         }
     }
 }
 ```
 */
