import { Global, Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { SecurityLogger } from './security-logger.service';
import { LoggingInterceptor } from './logging.interceptor';

@Global()
@Module({
  providers: [
    SecurityLogger,
    { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
  ],
  exports: [SecurityLogger],
})
export class ObservabilityModule {}
