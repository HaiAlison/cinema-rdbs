import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../../users/enums/user-role.enum';
import { UserStatus } from '../../users/enums/user-status.enum';
import { EUserRole } from 'src/entities/user.entity';

export class UserProfileDto {
  @ApiProperty({ example: 'USR-001' })
  id: string;

  @ApiProperty({ example: 'Nguyen Van Admin' })
  name: string;

  @ApiProperty({ example: 'admin@tmc.com' })
  email: string;

  @ApiProperty({ enum: EUserRole, example: EUserRole.ADMIN })
  role: EUserRole;

  @ApiProperty({ example: true })
  is_active: boolean;

}

export class LoginResponseDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'JWT Access Token',
  })
  accessToken: string;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'JWT Refresh Token',
  })
  refreshToken: string;

  @ApiProperty({ type: UserProfileDto })
  user: UserProfileDto;
}

export class UserMeResponseDto extends UserProfileDto {
  @ApiProperty({
    type: [String],
    example: [
      'dashboard',
      'employees',
      'qr-codes',
      'my-qr',
      'attendance',
      'gates',
      'reports',
      'audit-logs',
      'settings',
    ],
  })
  permissions: string[];
}

export class LogoutResponseDto {
  @ApiProperty({ example: 'Logged out successfully' })
  message: string;
}
