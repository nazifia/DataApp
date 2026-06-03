import '../models/beneficiary.dart';

abstract class BeneficiaryState {
  const BeneficiaryState();
}

class BeneficiaryInitial extends BeneficiaryState {
  const BeneficiaryInitial();
}

class BeneficiaryLoading extends BeneficiaryState {
  const BeneficiaryLoading();
}

class BeneficiaryLoaded extends BeneficiaryState {
  final List<Beneficiary> beneficiaries;
  const BeneficiaryLoaded(this.beneficiaries);
}

class BeneficiaryFailure extends BeneficiaryState {
  final String message;
  const BeneficiaryFailure(this.message);
}

class BeneficiarySaved extends BeneficiaryState {
  final Beneficiary beneficiary;
  const BeneficiarySaved(this.beneficiary);
}
