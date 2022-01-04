// Copyright 2021-present 650 Industries. All rights reserved.

import Quick
import Nimble

@testable import ExpoModulesCore

final class ExceptionsSpec: QuickSpec {
  override func spec() {
    it("has name") {
      let error = TestException()
      expect(error.name) == "TestException"
    }

    it("has code") {
      let error = TestException()
      expect(error.code) == "ERR_TEST"
    }

    it("has message") {
      let error = TestException()
      expect(error.message) == "This is the test exception"
    }

    describe("chaining") {
      it("can be chained once") {
        func throwable() throws {
          do {
            throw TestExceptionCause()
          } catch {
            throw TestException().causedBy(error)
          }
        }
        expect { try throwable() }.to(throwError { error in
          expect(error).to(beAKindOf(TestException.self))
          expect((error as! TestException).cause).to(beAKindOf(TestExceptionCause.self))
        })
      }

      it("can be chained twice") {
        func throwable() throws {
          do {
            do {
              throw TestExceptionCause()
            } catch {
              throw TestExceptionCause().causedBy(error)
            }
          } catch {
            throw TestException().causedBy(error)
          }
        }
        expect { try throwable() }.to(throwError { error in
          expect(error).to(beAKindOf(TestException.self))
          expect((error as! TestException).cause).to(beAKindOf(TestExceptionCause.self))
          expect(((error as! TestException).cause as! TestExceptionCause).cause).to(beAKindOf(TestExceptionCause.self))
          print((error as! Exception).description)
        })
      }

      it("includes cause description") {
        func throwable() throws {
          do {
            throw TestExceptionCause()
          } catch {
            throw TestException().causedBy(error)
          }
        }
        expect { try throwable() }.to(throwError { error in
          if let error = error as? TestException, let cause = error.cause as? TestExceptionCause {
            expect(error.description).to(contain(cause.description))
          } else {
            fail("Error and its cause are not of expected types.")
          }
        })
      }
    }
  }
}

class TestException: Exception {
  override var message: String {
    "This is the test exception"
  }
}

class TestExceptionCause: Exception {
  override var message: String {
    "This is the cause of the test exception"
  }
}
