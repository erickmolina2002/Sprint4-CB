import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { SecurityLogger } from './security-logger.service';
import { Events } from './events';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  constructor(private readonly logger: SecurityLogger) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest();
    const method: string = req.method;
    const route: string = req.originalUrl || req.url;
    const ip: string = req.ip || req.socket?.remoteAddress || 'desconhecido';
    const userAgent: string | undefined = req.headers?.['user-agent'];

    return next.handle().pipe(
      tap(() => {
        this.logger.log({
          event: Events.REQUEST,
          outcome: 'info',
          method,
          route,
          ip,
          userAgent,
        });
      }),
    );
  }
}
