sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class DataFailure extends Failure {
  const DataFailure(super.message);
}

final class IntegrityFailure extends Failure {
  const IntegrityFailure(super.message);
}

final class RuleFailure extends Failure {
  const RuleFailure(super.message);
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}
