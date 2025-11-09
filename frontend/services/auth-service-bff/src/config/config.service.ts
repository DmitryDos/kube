import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private readonly configService: ConfigService) {}

  getApiBaseUrl(): string {
    // Priority: API_GATEWAY_SERVICE (Docker) > NEXT_PUBLIC_API_BASE_URL > API_BASE_URL > default
    if (this.configService.get<string>('API_GATEWAY_SERVICE')) {
      return `http://${this.configService.get<string>('API_GATEWAY_SERVICE')}:80`;
    }
    if (this.configService.get<string>('NEXT_PUBLIC_API_BASE_URL')) {
      return this.configService.get<string>('NEXT_PUBLIC_API_BASE_URL')!;
    }
    if (this.configService.get<string>('API_BASE_URL')) {
      return this.configService.get<string>('API_BASE_URL')!;
    }
    return 'http://localhost:8080';
  }

  getFrontendUrl(): string {
    return this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
  }

  getPort(): number {
    return this.configService.get<number>('PORT') || 3003;
  }
}

