import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "Change made to see if this triggers a TAP rebuild"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
