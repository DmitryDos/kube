import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import cookieParser from 'cookie-parser';
import { AppConfigService } from './config/config.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  const configService = app.get(AppConfigService);
  
  // Cookie parser
  app.use(cookieParser());
  
  // CORS настройки
  app.enableCors({
    origin: configService.getFrontendUrl(),
    credentials: true,
  });

  const port = configService.getPort();
  await app.listen(port);
  console.log(`Video Service BFF is running on: http://localhost:${port}`);
}

bootstrap();

