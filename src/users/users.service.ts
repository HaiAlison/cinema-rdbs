import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { EUserRole, UserEntity } from '../entities/user.entity';
import { UserStatus } from './enums/user-status.enum';
import * as bcrypt from 'bcryptjs';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ListUsersDto } from './dto/list-users.dto';
import {
  UserResponseDto,
} from './dto/user-response.dto';
import {
  DEFAULT_LIMIT_NUMBER,
  DEFAULT_PAGE_NUMBER,
} from '../utils/common/constant';
import { pagination } from '../utils/common/handle';
import { PaginationResponse } from 'src/utils/common/interface';

@Injectable()
export class UsersService implements OnModuleInit {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.seedAdminUser();
  }

  async seedAdminUser(): Promise<void> {
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@cgv.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'string';

    const existingAdmin = await this.userRepository.findOne({
      where: { email: adminEmail.toLowerCase() },
      withDeleted: true,
    });

    if (!existingAdmin) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(adminPassword, salt);
      const admin = this.userRepository.create({
        code: 'ADMIN',
        name: 'Nguyen Van Admin',
        email: adminEmail.toLowerCase(),
        password: hashedPassword,
        role: EUserRole.ADMIN,
        is_active: true,
        phone: '0123456789',
        province: 'Hà Nội',
        salt,
      });

      await this.userRepository.save(admin);
      this.logger.log(`Seeded default admin user: ${adminEmail}`);
    }

    // Seed default employee account for testing/demo if not present
    const empEmail = 'giang.do@tmc.com.vn';
    const existingEmp = await this.userRepository.findOne({
      where: { email: empEmail },
      withDeleted: true,
    });

    if (!existingEmp) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash('admin123', salt);
      const empUser = this.userRepository.create({
        code: 'STAFF-01',
        name: 'Giang Do',
        email: empEmail,
        password: hashedPassword,
        role: EUserRole.STAFF,
        is_active: true,
        phone: '0123456789',
        province: 'Hà Nội',
        salt
      });

      await this.userRepository.save(empUser);
      this.logger.log(`Seeded default test employee user: ${empEmail}`);
    }
  }

  async create(dto: CreateUserDto): Promise<UserResponseDto> {
    const normalizedEmail = dto.email.toLowerCase().trim();

    const existingUser = await this.userRepository.findOne({
      where: { email: normalizedEmail },
      withDeleted: true,
    });

    if (existingUser) {
      throw new ConflictException(
        `User with email ${dto.email} already exists`,
      );
    }

    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const user = this.userRepository.create({
      name: dto.name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: dto.role,
      is_active: dto.is_active,
    });

    return await this.userRepository.save(user);
  }

  async findAll(params: ListUsersDto): Promise<PaginationResponse<UserResponseDto>> {

    const qb = this.userRepository.createQueryBuilder('user');
    qb.where('user.deleted_at IS NULL');

    if (params.search_string) {
      qb.andWhere(
        '(LOWER(user.name) LIKE :q OR LOWER(user.email) LIKE :q)',
        { q: params.search_string },
      );
    }

    if (params.role) {
      qb.andWhere('user.role = :role', { role: params.role });
    }

    if (params.is_active) {
      qb.andWhere('user.is_active = :is_active', { is_active: params.is_active });
    }

    qb.orderBy('user.id', 'ASC');

    const paginated = await pagination<UserEntity>(qb, {
      limit: params.limit,
      offset: params.offset,
    });

    const data = paginated.results;

    return {
      results: data,
      totalItems: paginated.totalItems,
      offset: paginated.offset,
      limit: paginated.limit,
      totalPages: paginated.totalPages,
    };
  }

  async getById(id: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async update(id: string, dto: UpdateUserDto): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    if (dto.email && dto.email.toLowerCase() !== user.email.toLowerCase()) {
      const normalizedEmail = dto.email.toLowerCase().trim();
      const existing = await this.userRepository.findOne({
        where: { email: normalizedEmail },
        withDeleted: true,
      });
      if (existing && existing.id !== id) {
        throw new ConflictException(
          `User with email ${dto.email} already exists`,
        );
      }
      user.email = normalizedEmail;
    }

    if (dto.name) user.name = dto.name.trim();
    if (dto.is_active) user.is_active = dto.is_active;
    if (dto.password) {
      user.password = await bcrypt.hash(dto.password, 10);
    }

    return await this.userRepository.save(user);
  }

  async delete(id: string): Promise<void> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    await this.userRepository.softDelete(id);
  }

  async findByEmail(
    email: string,
    includePassword = false,
  ): Promise<UserEntity | null> {
    const qb = this.userRepository.createQueryBuilder('user');
    qb.where('LOWER(user.email) = LOWER(:email)', { email });

    if (includePassword) {
      qb.addSelect('user.password').addSelect('user.refresh_token_hash');
    }

    return qb.getOne();
  }

  async findById(
    id: string,
    includeRefreshToken = false,
  ): Promise<UserEntity | null> {
    const qb = this.userRepository.createQueryBuilder('user');
    qb.where('user.id = :id', { id });

    if (includeRefreshToken) {
      qb.addSelect('user.refresh_token_hash');
    }

    return qb.getOne();
  }

  async updateRefreshTokenHash(
    userId: string,
    refresh_token_hash: string | null,
  ): Promise<void> {
    await this.userRepository.update({ id: userId }, { refresh_token_hash });
  }

  async updateLastLogin(userId: string): Promise<void> {
    await this.userRepository.update({ id: userId }, { last_login: new Date() });
  }

  // ===========================================================================
  // BTL2 MỤC 2.1 & 3.1: GỌI STORED PROCEDURES INSERT / UPDATE / DELETE
  // ===========================================================================

  async createUserViaProcedure(dto: any): Promise<{ message: string }> {
    try {
      await this.userRepository.query(
        `CALL sp_insert_user($1, $2, $3, $4, $5, $6, $7, $8, NULL)`,
        [
          dto.code,
          dto.name,
          dto.email,
          dto.phone,
          dto.dob || null,
          dto.province,
          dto.password,
          dto.role || 'customer',
        ],
      );
      return { message: 'Tạo người dùng thành công qua Stored Procedure' };
    } catch (error) {
      this.logger.error(`Lỗi sp_insert_user: ${error.message}`);
      throw new ConflictException(error.message);
    }
  }

  async updateUserViaProcedure(id: string, dto: any): Promise<{ message: string }> {
    try {
      await this.userRepository.query(
        `CALL sp_update_user($1, $2, $3, $4, $5)`,
        [
          id,
          dto.name || null,
          dto.phone || null,
          dto.province || null,
          dto.is_active ?? null,
        ],
      );
      return { message: `Cập nhật người dùng ${id} thành công qua Stored Procedure` };
    } catch (error) {
      this.logger.error(`Lỗi sp_update_user: ${error.message}`);
      throw new ConflictException(error.message);
    }
  }

  async deleteUserViaProcedure(id: string): Promise<{ message: string }> {
    try {
      await this.userRepository.query(`CALL sp_delete_user($1)`, [id]);
      return { message: `Xóa người dùng ${id} thành công qua Stored Procedure` };
    } catch (error) {
      this.logger.error(`Lỗi sp_delete_user: ${error.message}`);
      throw new ConflictException(error.message);
    }
  }

  // ===========================================================================
  // BTL2 MỤC 2.3 & 3.2: GỌI STORED PROCEDURES TRUY VẤN DỮ LIỆU
  // ===========================================================================

  async getUsersWithMembershipViaProcedure(province?: string, tier?: string): Promise<any[]> {
    return await this.userRepository.manager.transaction(async (manager) => {
      await manager.query(
        `CALL sp_get_users_with_membership($1, $2, 'cur_users_mb')`,
        [province || null, tier || null],
      );
      return await manager.query(`FETCH ALL FROM "cur_users_mb"`);
    });
  }

  async getUserSpendingReportViaProcedure(tier?: string, minTotalSpent?: number): Promise<any[]> {
    return await this.userRepository.manager.transaction(async (manager) => {
      await manager.query(
        `CALL sp_report_user_spending_by_tier($1, $2, 'cur_spending_rep')`,
        [tier || null, minTotalSpent || 0],
      );
      return await manager.query(`FETCH ALL FROM "cur_spending_rep"`);
    });
  }

  // ===========================================================================
  // BTL2 MỤC 2.4 & 3.3: GỌI FUNCTIONS TÍNH TOÁN (CURSOR & LOOP)
  // ===========================================================================

  async calculateUserLoyaltyVoucherViaFunction(userId: string): Promise<{ userId: string; discountPercent: number }> {
    const result = await this.userRepository.query(
      `SELECT fn_calculate_user_loyalty_voucher($1) AS "discountPercent"`,
      [userId],
    );
    const discountPercent = result[0]?.discountPercent ?? 0;
    return { userId, discountPercent: Number(discountPercent) };
  }
}
