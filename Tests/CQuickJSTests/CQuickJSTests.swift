import CQuickJS
import Testing

@Test
func canCreateRuntimeAndContext() throws {
    let runtime = JS_NewRuntime()
    #expect(runtime != nil)

    guard let runtime else {
        return
    }

    let context = JS_NewContext(runtime)
    #expect(context != nil)

    if let context {
        JS_FreeContext(context)
    }

    JS_FreeRuntime(runtime)
}
