import 'package:flutter_test/flutter_test.dart';
import 'package:militarytracker/core/utils/result.dart';

void main() {
  group('Result Pattern Tests', () {
    test('Success holds data', () {
      // Arrange & Act
      final result = Success<int>(42);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals(42));
      expect(result.errorOrNull, isNull);
    });

    test('Failure holds error message', () {
      // Arrange & Act
      final result = Failure<int>('Something went wrong');

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, equals('Something went wrong'));
    });

    test('when pattern matching works for Success', () {
      // Arrange
      final result = Success<String>('Hello');

      // Act
      final output = result.when(
        success: (data) => 'Success: $data',
        failure: (message, _) => 'Failure: $message',
      );

      // Assert
      expect(output, equals('Success: Hello'));
    });

    test('when pattern matching works for Failure', () {
      // Arrange
      final result = Failure<String>('Error occurred');

      // Act
      final output = result.when(
        success: (data) => 'Success: $data',
        failure: (message, _) => 'Failure: $message',
      );

      // Assert
      expect(output, equals('Failure: Error occurred'));
    });

    test('map transforms Success data', () {
      // Arrange
      final result = Success<int>(5);

      // Act
      final mapped = result.map((value) => value * 2);

      // Assert
      expect(mapped.isSuccess, isTrue);
      expect(mapped.dataOrNull, equals(10));
    });

    test('map preserves Failure', () {
      // Arrange
      final result = Failure<int>('Error');

      // Act
      final mapped = result.map((value) => value * 2);

      // Assert
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, equals('Error'));
    });

    test('flatMap transforms Success to new Result', () async {
      // Arrange
      final result = Success<int>(5);

      // Act
      final flatMapped = await result.flatMap((value) async {
        if (value > 0) {
          return Success(value * 2);
        }
        return Failure<int>('Negative value');
      });

      // Assert
      expect(flatMapped.isSuccess, isTrue);
      expect(flatMapped.dataOrNull, equals(10));
    });

    test('flatMap preserves Failure', () async {
      // Arrange
      final result = Failure<int>('Original error');

      // Act
      final flatMapped = await result.flatMap((value) async {
        return Success(value * 2);
      });

      // Assert
      expect(flatMapped.isFailure, isTrue);
      expect(flatMapped.errorOrNull, equals('Original error'));
    });

    test('toSuccess extension creates Success', () {
      // Arrange & Act
      final result = 'Hello'.toSuccess();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals('Hello'));
    });

    test('toFailure extension creates Failure', () {
      // Arrange & Act
      final result = 'Error message'.toFailure<int>();

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, equals('Error message'));
    });

    test('Future.toResult converts successful Future to Success', () async {
      // Arrange
      Future<int> futureValue = Future.value(42);

      // Act
      final result = await futureValue.toResult();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(42));
    });

    test('Future.toResult converts failed Future to Failure', () async {
      // Arrange
      Future<int> futureValue = Future.error(Exception('Failed'));

      // Act
      final result = await futureValue.toResult();

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isNotNull);
    });
  });
}
