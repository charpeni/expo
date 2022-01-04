// Copyright 2022-present 650 Industries. All rights reserved.

/**
 The exception that needs some additional parameters to be best described.
 */
open class GenericException<ParamsType>: Exception {
  /**
   The additional parameters passed to the initializer.
   */
  public let params: ParamsType

  /**
   The default initializer that takes a tuple of params and captures the place in the code where the exception was created.
   - Warning: Call it only with one argument!
   */
  public init(_ params: ParamsType, sourceFile: String = #fileID, sourceLine: UInt = #line, sourceFunction: String = #function) {
    self.params = params
    super.init(sourceFile: sourceFile, sourceLine: sourceLine, sourceFunction: sourceFunction)
  }
}
