export class UsageError extends Error {
  readonly exitCode = 64;
}

export class ApiError extends Error {
  readonly exitCode = 69;

  constructor(
    readonly code: string,
    message: string,
    readonly status?: number,
  ) {
    super(message);
  }
}

export class ConfigurationError extends Error {
  readonly exitCode = 78;
}

export function exitCodeFor(error: unknown): number {
  if (
    error instanceof UsageError ||
    error instanceof ApiError ||
    error instanceof ConfigurationError
  ) {
    return error.exitCode;
  }
  return 1;
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
