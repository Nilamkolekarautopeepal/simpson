class APIStatusCode {
  static const int DUPLICATE = 1001;

  ///1002-Data inserted successfully
  ///
  static const int INSERTED_SUCCESS = 1002;

  ///1003-Data insert failed
  ///
  static const int INSERTED_ERROR = 1003;

  ///1004- Data update successfully
  ///
  static const int UPDATE_SUCCESS = 1004;

  ///1005- Data update failed
  ///
  static const int UPDATE_ERROR = 1005;

  ///1006-Data delete successfully
  ///
  static const int DELETE_SUCCESS = 1006;

  ///1007-Data delete failed
  ///
  static const int DELETE_ERROR = 1007;

  ///1008-Data cannot delete from system
  ///
  static const int DELETE_INVALID = 1008;

  ///1009-Internal server error
  ///
  static const int SERVER_ERROR = 1009;

  ///1010-Service expired
  ///
  static const int SERVICE_EXPIRED = 1010;

  ///1011-Data input is empty
  ///
  static const int INPUT_IS_EMPTY = 1011;

  ///1012-Entity not found
  ///
  static const int NOT_FOUND = 1012;

  ///1017-Entity found
  ///
  static const int FOUND = 200;

  static const int CUSTOMER_FOUND = 2010;
  static const int CUSTOMER_NOT_FOUND = 1018;

  ///1013-File uploaded successfully
  ///
  static const int FILE_UPLOADED_SUCCESS = 1013;

  ///1014-File upload failed
  ///
  static const int FILE_UPLOADED_ERROR = 1014;

  ///1015-No directive exist
  ///
  static const int NO_DIRECTIVE_EXIST = 1015;

  ///1100-Exception occurred at service side
  ///
  static const int SERVER_EXCEPTION = 1100;

  ///1101-Service success
  ///
  static const int SUCCESS = 200;

  static const int postSuccess = 201;

  static const int internalServerIssue = 500;

  static const int ERROR = 1102;

  static const int unauthorized = 401;

  static const int badRequest = 400;

  static const int ForbiddenError = 403;

  static const int alreadyExistError = 409;

  static const int notFoundError = 404;
}
