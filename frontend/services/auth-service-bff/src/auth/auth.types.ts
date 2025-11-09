import { ObjectType, Field, InputType } from '@nestjs/graphql';

@ObjectType()
export class User {
  @Field()
  id!: string;

  @Field()
  email!: string;

  @Field()
  name!: string;

  @Field({ nullable: true })
  created_at?: string;
}

@ObjectType()
export class AuthResponse {
  @Field()
  message!: string;

  @Field(() => User)
  user!: User;
}

@InputType()
export class LoginInput {
  @Field()
  email!: string;

  @Field()
  password!: string;
}

@InputType()
export class RegisterInput {
  @Field()
  email!: string;

  @Field()
  password!: string;

  @Field()
  name!: string;
}

