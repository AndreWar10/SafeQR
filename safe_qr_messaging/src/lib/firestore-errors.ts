const ALREADY_EXISTS_CODE = 6;
const PERMISSION_DENIED_CODE = 7;

export function isAlreadyExistsError(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code: number }).code === ALREADY_EXISTS_CODE
  );
}

export function isPermissionDeniedError(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code: number }).code === PERMISSION_DENIED_CODE
  );
}
