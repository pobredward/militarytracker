/// Result 패턴 구현
/// 에러 처리를 일관성 있게 하기 위한 sealed class
sealed class Result<T> {
  const Result();

  /// Success 케이스인지 확인
  bool get isSuccess => this is Success<T>;

  /// Failure 케이스인지 확인
  bool get isFailure => this is Failure<T>;

  /// Success 데이터 가져오기 (없으면 null)
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;

  /// Failure 메시지 가져오기 (없으면 null)
  String? get errorOrNull => isFailure ? (this as Failure<T>).message : null;

  /// when 패턴 매칭
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      final fail = this as Failure<T>;
      return failure(fail.message, fail.exception);
    }
  }

  /// map으로 데이터 변환
  Result<R> map<R>(R Function(T) transform) {
    return when(
      success: (data) => Success(transform(data)),
      failure: (message, exception) => Failure(message, exception),
    );
  }

  /// flatMap (비동기 변환)
  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T) transform) async {
    return when(
      success: (data) => transform(data),
      failure: (message, exception) => Future.value(Failure(message, exception)),
    );
  }
}

/// 성공 케이스
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// 실패 케이스
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);

  @override
  String toString() => 'Failure($message${exception != null ? ', $exception' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          message == other.message &&
          exception == other.exception;

  @override
  int get hashCode => message.hashCode ^ exception.hashCode;
}

/// Result 생성 헬퍼
extension ResultExtension<T> on T {
  Result<T> toSuccess() => Success(this);
}

extension StringResultExtension on String {
  Result<T> toFailure<T>([Exception? exception]) => Failure(this, exception);
}

/// Future<Result> 헬퍼
extension FutureResultExtension<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Success(data);
    } catch (e) {
      if (e is Exception) {
        return Failure(e.toString(), e);
      }
      return Failure('알 수 없는 오류: $e');
    }
  }
}
