/** An error that maps directly onto the API's error envelope. */
class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }

  static badRequest(code, message, details) { return new ApiError(400, code, message, details); }
  static notFound(code, message) { return new ApiError(404, code, message); }
  static unprocessable(code, message, details) { return new ApiError(422, code, message, details); }
}

module.exports = ApiError;
