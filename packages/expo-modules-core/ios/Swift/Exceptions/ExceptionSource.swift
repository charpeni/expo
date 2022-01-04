// Copyright 2022-present 650 Industries. All rights reserved.

/**
 Represents the place in code where the exception was created.
 */
public struct ExceptionSource: CustomStringConvertible {
  /**
   The path to the file in which the exception was created.
   */
  let file: String

  /**
   The line number on which the exception was created.
   */
  let line: UInt

  /**
   The name (selector) of the declaration in which the exception was created.
   */
  let function: String

  /**
   Stringified representation of the exception source.
   */
  public var description: String {
    "\(function) at \(file):\(line)"
  }
}
