abstract class BeneficiaryEvent {
  const BeneficiaryEvent();
}

class LoadBeneficiariesEvent extends BeneficiaryEvent {
  final String? type;
  const LoadBeneficiariesEvent({this.type});
}

class SaveBeneficiaryEvent extends BeneficiaryEvent {
  final String phoneNumber;
  final String network;
  final String type;
  final String nickname;

  const SaveBeneficiaryEvent({
    required this.phoneNumber,
    required this.network,
    required this.type,
    this.nickname = '',
  });
}

class DeleteBeneficiaryEvent extends BeneficiaryEvent {
  final String id;
  const DeleteBeneficiaryEvent(this.id);
}

class UpdateBeneficiaryNicknameEvent extends BeneficiaryEvent {
  final String id;
  final String nickname;
  const UpdateBeneficiaryNicknameEvent({required this.id, required this.nickname});
}
