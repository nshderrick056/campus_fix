import 'package:campus_incident_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aluEmail accepts only ALU domains', () {
    expect(Validators.aluEmail('amina@alustudent.com'), isNull);
    expect(Validators.aluEmail('  Jean@ALUeducation.com '), isNull);
    expect(Validators.aluEmail('amina@gmail.com'), contains('Only'));
    expect(Validators.aluEmail('not-an-email'), isNotNull);
    expect(Validators.aluEmail(''), isNotNull);
  });

  test('newPassword needs 8+ characters and a number', () {
    expect(Validators.newPassword('short1'), isNotNull);
    expect(Validators.newPassword('longpassword'), isNotNull);
    expect(Validators.newPassword('longpass1'), isNull);
    expect(Validators.confirmPassword('a', 'b'), isNotNull);
    expect(Validators.confirmPassword('same1234', 'same1234'), isNull);
  });

  test('report fields are validated', () {
    expect(Validators.title('Leak'), isNotNull);
    expect(Validators.title('Water leak'), isNull);
    expect(Validators.title('x' * 81), isNotNull);
    expect(Validators.description('Too short'), isNotNull);
    expect(Validators.description('The tap in the kitchen is leaking.'), isNull);
    expect(Validators.location('  '), isNotNull);
  });
}
