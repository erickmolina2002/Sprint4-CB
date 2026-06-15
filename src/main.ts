import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { vulnV1, vulnV2, vulnV3 } from './config/flags';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  const logger = new Logger('wellme-back');
  logger.warn(
    `Flags de vulnerabilidade EDUCACIONAL -> V1(JWT)=${vulnV1()} V2(auth)=${vulnV2()} V3(admin)=${vulnV3()}`,
  );
  logger.log(`wellme-back ouvindo em http://localhost:${port}`);
}
bootstrap();
