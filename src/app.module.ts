import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmAsyncConfig } from './utils/config/database/config.service';
import { join } from 'path';
import { HeaderResolver, I18nModule } from 'nestjs-i18n';
import { CinemaModule } from './cinema/cinema.module';
import { RoomsModule } from './rooms/rooms.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { MoviesModule } from './movies/movies.module';

@Module({
  imports: [
    ConfigModule.forRoot({ envFilePath: ['.env'], isGlobal: true }),
    ConfigModule,
    TypeOrmModule.forRootAsync(typeOrmAsyncConfig),
    I18nModule.forRoot({
      fallbackLanguage: process.env.DEFAULT_LANGUAGE,
      loaderOptions: {
        path: join(__dirname, 'utils/i18n/'),
        watch: true,
      },
      resolvers: [new HeaderResolver(['x-language'])],
    }),
    AuthModule,
    UsersModule,
    CinemaModule,
    RoomsModule,
    MoviesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
