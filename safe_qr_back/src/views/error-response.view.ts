export type ErrorResponseJson = {
  error: string;
  message: string;
  requestId: string;
  details?: unknown;
};

export function validationError(
  requestId: string,
  message: string,
  details?: unknown,
): ErrorResponseJson {
  return {
    error: 'VALIDATION_ERROR',
    message,
    requestId,
    ...(details !== undefined ? { details } : {}),
  };
}

export function payloadTooLarge(requestId: string, maxBytes: number): ErrorResponseJson {
  return {
    error: 'PAYLOAD_TOO_LARGE',
    message: `Conteúdo excede o limite de ${maxBytes} bytes (UTF-8).`,
    requestId,
  };
}
