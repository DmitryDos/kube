import { Resolver, Mutation, Query, Context, Args } from '@nestjs/graphql';
import { AuthService } from './auth.service';
import { AuthResponse, User, LoginInput, RegisterInput } from './auth.types';
import { Request, Response } from 'express';

@Resolver()
export class AuthResolver {
  constructor(private readonly authService: AuthService) {}

  @Mutation(() => AuthResponse)
  async login(
    @Args('input') input: LoginInput,
    @Context() context: { res: Response },
  ) {
    const result = await this.authService.login(input.email, input.password);
    
    context.res.cookie('authToken', result.token, {
      httpOnly: true,
      secure: process.env['NODE_ENV'] === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 * 1000,
      path: '/',
    });

    return {
      message: result.message,
      user: result.user,
    };
  }

  @Mutation(() => AuthResponse)
  async register(
    @Args('input') input: RegisterInput,
    @Context() context: { res: Response },
  ) {
    const result = await this.authService.register(input.email, input.password, input.name);
    
    context.res.cookie('authToken', result.token, {
      httpOnly: true,
      secure: process.env['NODE_ENV'] === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 * 1000,
      path: '/',
    });

    return {
      message: result.message,
      user: result.user,
    };
  }

  @Mutation(() => String)
  async logout(@Context() context: { req: Request; res: Response }) {
    const token = context.req.cookies?.['authToken'];
    
    if (token) {
      await this.authService.logout(token);
    }

    context.res.clearCookie('authToken', { path: '/' });

    return 'Logged out successfully';
  }

  @Query(() => User, { nullable: true })
  async me(@Context() context: { req: Request }) {
    const token = context.req.cookies?.['authToken'];
    
    if (!token) {
      return null;
    }

    try {
      return await this.authService.validateToken(token);
    } catch {
      return null;
    }
  }
}

