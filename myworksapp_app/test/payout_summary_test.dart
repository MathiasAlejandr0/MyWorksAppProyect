import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/payout_summary.dart';

void main() {
  test('suma lo retenido y deja fuera lo ya transferido', () {
    const summary = PayoutSummary(movements: [
      PayoutMovement(
        paymentId: 'a',
        jobId: 'j1',
        amountClp: 40000,
        paymentStatus: 'retenido',
      ),
      PayoutMovement(
        paymentId: 'b',
        jobId: 'j2',
        amountClp: 25000,
        paymentStatus: 'liberado',
        transferStatus: 'transferido',
      ),
      PayoutMovement(
        paymentId: 'c',
        jobId: 'j3',
        amountClp: 10000,
        paymentStatus: 'reembolsado',
      ),
    ]);
    expect(summary.pendingClp, 40000);
    expect(summary.history, hasLength(1));
  });

  test('valida y enmascara la cuenta', () {
    expect(
      validateBankAccount(
        bank: 'BancoEstado',
        accountType: 'rut',
        accountNumber: '12345678',
        holderRut: '12.345.678-5',
        holderName: 'Ana Soto',
      ),
      isNull,
    );
    expect(
      validateBankAccount(
        bank: 'BancoEstado',
        accountType: 'rut',
        accountNumber: '12',
        holderRut: '12.345.678-5',
        holderName: 'Ana Soto',
      ),
      contains('número'),
    );
    expect(maskAccountNumber('12345678'), '•••• 5678');
    expect(isValidChileanRut('12.345.678-5'), isTrue);
    expect(isValidChileanRut('12.345.678-9'), isFalse);
  });
}
