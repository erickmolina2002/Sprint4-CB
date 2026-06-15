import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface SecurityEvent {
  event: string;
  outcome?: 'success' | 'fail' | 'info';
  name?: string;
  route?: string;
  method?: string;
  ip?: string;
  userAgent?: string;
  count?: number;
  identified?: boolean;
  detail?: string;
}

@Injectable()
export class SecurityLogger {
  private readonly file = path.resolve(process.cwd(), 'logs', 'app.log');

  constructor() {
    try {
      fs.mkdirSync(path.dirname(this.file), { recursive: true });
    } catch {
      void 0;
    }
  }

  log(event: SecurityEvent): void {
    const line = JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'security',
      ...event,
    });
    process.stdout.write(line + '\n');
    try {
      fs.appendFileSync(this.file, line + '\n');
    } catch {
      void 0;
    }
  }
}
