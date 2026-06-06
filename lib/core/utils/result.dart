sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ErrorResult<T> extends Result<T> {
  final String message;
  const ErrorResult(this.message);
}
