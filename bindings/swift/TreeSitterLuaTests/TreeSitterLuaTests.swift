import XCTest
import SwiftTreeSitter
import TreeSitterLua

final class TreeSitterLuaTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_lua())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Lua grammar")
    }
}
