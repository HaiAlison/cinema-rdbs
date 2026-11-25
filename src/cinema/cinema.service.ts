import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OnModuleInit } from '@nestjs/common';
import { CinemaEntity } from 'src/entities/cinema.entity';

@Injectable()
export class CinemaService implements OnModuleInit {
    constructor(
        @InjectRepository(CinemaEntity)
        private readonly cinemaRepository: Repository<CinemaEntity>,
    ) {}

    async onModuleInit(): Promise<void> {
        await this.seedCinemas()
    }

    async seedCinemas(): Promise<void> {
        const cinemas = this.cinemaRepository.create([
            { name: 'CGV Hùng Vương Plaza', address: '126 Hồng Bàng, Phường 12, Quận 5, Thành Phố Hồ Chí Minh', phone: '02838562099', ward: 'Phường 12', city: 'Thành Phố Hồ Chí Minh', is_active: true, lat: 10.756973, long: 106.667417 },
            { name: 'CGV Nguyễn Trãi', address: '126 Nguyễn Trãi, Phường Bến Thành, Quận 1, Thành Phố Hồ Chí Minh', phone: '02838562099', ward: 'Phường Bến Thành', city: 'Thành Phố Hồ Chí Minh', is_active: true, lat: 10.762207, long: 106.695216 },
        ]);

        for (const cinema of cinemas) {
            const existing = await this.cinemaRepository.findOneBy({ name: cinema.name });
            if (!existing) {
                await this.cinemaRepository.save(cinema);
            }
        }
    }

    async findAll(): Promise<CinemaEntity[]> {
        return await this.cinemaRepository.find();
    }
}
