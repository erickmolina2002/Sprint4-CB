import { vulnV1 } from '../config/flags';

export const HARDCODED_JWT_SECRET = 'wellme-super-secret-123';

export interface ResolvedSecret {
  secret: string;
  source: 'hardcoded-fallback' | 'env-secure' | 'fallback-missing-env';
}

export function resolveJwtSecret(): ResolvedSecret {
  if (vulnV1()) {
    return { secret: HARDCODED_JWT_SECRET, source: 'hardcoded-fallback' };
  }
  const fromEnv = process.env.JWT_SECRET;
  if (fromEnv && fromEnv.length > 0) {
    return { secret: fromEnv, source: 'env-secure' };
  }
  return { secret: HARDCODED_JWT_SECRET, source: 'fallback-missing-env' };
}
