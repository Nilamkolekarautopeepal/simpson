// ignore_for_file: constant_identifier_names

class UserType {
  static const String DOCTOR = "DOCTOR";
  static const String PATIENT = "PATIENT";
  static const String ADMIN = "ADMIN";
}

class UserStatus {
  static const String INPROCESS = 'INPROCESS';
  static const String PENDINGAPPROVAL = 'PENDING_APPROVAL';
  static const String ACTIVE = 'ACTIVE';
  static const String INACTIVE = 'INACTIVE';
}

class AppointmentStatus {
  static const String DECLINED = 'Declined';
  static const String APPROVED = 'Approved';
  static const String CANCELLED = 'Cancelled';
}

class PaymentType {
  /*
  *
  * CC-Payment Code,Credit Card-PaymentType,DB-Debit Card,NB-Net banking,UPI,Cash
  * */
  static const String CreditCard = 'CC';
  static const String DebitCard = 'DC';
  static const String NetBanking = 'NB';
  static const String UPI = 'UPI';
  static const String CASH = 'CASH';
  static const String COD = 'COD';
  static const String CARD = 'CARD';
  static const String phonePay = 'phonePay';
  static const String paytm = 'paytm';
  static const String gPay = 'gPay';
  static const String bhim = 'bhim';
  static const String payHere = 'Pay Here';
}
