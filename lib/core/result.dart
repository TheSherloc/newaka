sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  R when<R>({
    required R Function(T value, List<String> warnings) ok,
    required R Function(String message) err,
  }) {
    return switch (this) {
      Ok<T>(:final value, :final warnings) => ok(value, warnings),
      Err<T>(:final message) => err(message),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value, {this.warnings = const []});
  final T value;
  final List<String> warnings;
}

final class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}
