import '../../../../core/failure.dart';

/// Maps source bridge/runtime error codes to typed failure variants.
Failure mapSourceBridgeFailure({
  required String code,
  required String message,
}) {
  switch (code) {
    case SourceFailureCode.runtimeTimeout:
      return SourceRuntimeFailure(code: code, message: message);
    case SourceFailureCode.runtimeCancelled:
      return SourceRuntimeFailure(code: code, message: message);
    case SourceFailureCode.runtimeExecutionFailed:
      return SourceRuntimeFailure(code: code, message: message);
    case SourceFailureCode.unsupportedCapability:
      return SourceCapabilityFailure(code: code, message: message);
    case SourceFailureCode.sourceNotTrusted:
      return SourceTrustFailure(code: code, message: message);
    case SourceFailureCode.missingPlugin:
      return SourceCapabilityFailure(code: code, message: message);
    default:
      return SourceRuntimeFailure(
        code: SourceFailureCode.unknown,
        message: message,
      );
  }
}
