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

export function unauthorizedError(requestId: string, message = 'Token ou idUser inválido.'): ErrorResponseJson {
  return {
    error: 'UNAUTHORIZED',
    message,
    requestId,
  };
}

export function notFoundError(requestId: string, message = 'Recurso não encontrado.'): ErrorResponseJson {
  return {
    error: 'NOT_FOUND',
    message,
    requestId,
  };
}
