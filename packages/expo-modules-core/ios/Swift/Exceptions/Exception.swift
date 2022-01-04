// Copyright 2022-present 650 Industries. All rights reserved.

open class Exception: CodedError, ChainableException, CustomStringConvertible {
  open var name: String {
    return String(describing: Self.self)
  }

  open var message: String {
    "undefined message"
  }

  open var source: ExceptionSource

  /**
   The default initializer that captures the place in the code where the exception was created.
   - Warning: Call it only without arguments!
   */
  public init(sourceFile: String = #fileID, sourceLine: UInt = #line, sourceFunction: String = #function) {
    self.source = ExceptionSource(file: sourceFile, line: sourceLine, function: sourceFunction)
  }

  // MARK: ChainableException

  open var cause: Error?

  // MARK: CustomStringConvertible

  open var description: String {
    let description = "\(name): \(message) (\(source))"

    if let cause = cause as? CodedError {
      return "\(description)\n→ Caused by \(cause.description)"
    } else if let cause = cause {
      return "\(description)\n→ Caused by: \(cause.localizedDescription)"
    }
    return description
  }
}
