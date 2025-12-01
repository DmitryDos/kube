import { Controller, Post, Get, Body, Req, Res } from '@nestjs/common';
import { Request, Response } from 'express';
import { AuthService } from './auth.service';

@Controller('api/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  async login(@Body() body: { email: string; password: string }, @Res() res: Response) {
    const result = await this.authService.login(body.email, body.password);
    
    // Устанавливаем токен в httpOnly cookie
    res.cookie('authToken', result.token, {
      httpOnly: true,
      secure: process.env['NODE_ENV'] === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 * 1000, // 7 дней
      path: '/',
    });

    return res.json({
      message: result.message,
      user: result.user,
    });
  }

  @Post('register')
  async register(
    @Body() body: { email: string; password: string; name: string },
    @Res() res: Response,
  ) {
    const result = await this.authService.register(body.email, body.password, body.name);
    
    // Устанавливаем токен в httpOnly cookie
    res.cookie('authToken', result.token, {
      httpOnly: true,
      secure: process.env['NODE_ENV'] === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 * 1000, // 7 дней
      path: '/',
    });

    return res.json({
      message: result.message,
      user: result.user,
    });
  }

  @Post('logout')
  async logout(@Req() req: Request, @Res() res: Response) {
    const token = req.cookies?.['authToken'];
    
    if (token) {
      await this.authService.logout(token);
    }

    // Удаляем cookie
    res.clearCookie('authToken', { path: '/' });

    return res.json({ message: 'Logged out successfully' });
  }

  @Get('me')
  async getMe(@Req() req: Request) {
    const token = req.cookies?.['authToken'];
    
    if (!token) {
      return { error: 'Not authenticated' };
    }

    try {
      const user = await this.authService.validateToken(token);
      return { user };
    } catch (error) {
      return { error: 'Not authenticated' };
    }
  }
}

