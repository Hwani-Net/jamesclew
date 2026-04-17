# P-051: Prisma v7 Breaking Changes — Windows 환경

**증상**: `npx prisma migrate dev` 후 `PrismaClient()` 무인자 생성 실패, seed 설정 `package.json` 미인식

**원인**: Prisma v7에서 breaking changes 3가지:
1. `datasource.url` → `prisma.config.ts`의 `migrations` 설정으로 이동
2. `PrismaClient()` 무인자 → `@prisma/adapter-better-sqlite3` 어댑터 필수
3. seed 설정 → `package.json` 아닌 `prisma.config.ts`의 `migrations.seed` 필드

**추가 (Windows)**: `--compiler-options '{"module":"CommonJS"}'` single-quote 불가 → `tsconfig.seed.json` 별도 파일로 우회

**해결**:
```ts
// prisma.config.ts
import { defineConfig } from 'prisma/config'
import { PrismaLibSQL } from '@prisma/adapter-libsql'

export default defineConfig({
  earlyAccess: true,
  schema: './prisma/schema.prisma',
  migrations: {
    seed: 'ts-node --project tsconfig.seed.json prisma/seed.ts',
  },
})
```

```json
// tsconfig.seed.json
{
  "compilerOptions": {
    "module": "CommonJS",
    "target": "ES2020",
    "esModuleInterop": true
  }
}
```

**재발 방지**: Prisma 새 프로젝트 시작 전 `npx prisma --version` 확인. v7+ 이면 위 패턴 적용.
