-- ============================================================
-- РЕТРОГРАДЕН v1.5 · Supabase схема
--
-- Стъпки (еднократно, ръчно):
--   1. https://supabase.com → New Project, име: retrograden,
--      регион: eu-west-1 (Ирландия)
--   2. SQL Editor → пусни целия този файл
--   3. Project Settings → API → копирай Project URL и anon public key
--   4. Постави ги в retrograden.html (константите SUPABASE_URL и
--      SUPABASE_ANON_KEY в <head>)
--
-- Без тези стъпки приложението продължава да работи изцяло локално;
-- само облачният sync и „Космическа комбинация" между устройства
-- са изключени.
-- ============================================================

-- Потребители
CREATE TABLE profiles (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  display_name TEXT NOT NULL,
  gender TEXT,
  email TEXT,
  birth_date TEXT NOT NULL,
  birth_time TEXT,
  birth_city TEXT NOT NULL,
  birth_lat NUMERIC(9,6) NOT NULL,
  birth_lon NUMERIC(9,6) NOT NULL,
  natal_chart JSONB,
  avatar TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Покани за комбинация
CREATE TABLE combination_invites (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  inviter_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
  inviter_name TEXT NOT NULL,
  inviter_gender TEXT,
  code TEXT UNIQUE NOT NULL,
  inviter_chart JSONB NOT NULL,
  used_by TEXT REFERENCES profiles(id),
  used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Запазени комбинации
CREATE TABLE combinations (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_a_id TEXT REFERENCES profiles(id),
  user_b_id TEXT REFERENCES profiles(id),
  user_a_name TEXT,
  user_b_name TEXT,
  context TEXT,
  result_json JSONB NOT NULL,
  chart_a JSONB,          -- снимка на наталните карти в момента на
  chart_b JSONB,          -- комбинацията (за дневните индикатори на двойката)
  is_saved BOOLEAN NOT NULL DEFAULT false,
  saved_at TIMESTAMPTZ,
  inviter_gender TEXT,
  invitee_gender TEXT,
  relationship_detail TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE combination_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE combinations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Insert own profile" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Update own profile" ON profiles FOR UPDATE USING (true);
CREATE POLICY "Public read invites by code" ON combination_invites FOR SELECT USING (true);
CREATE POLICY "Insert invite" ON combination_invites FOR INSERT WITH CHECK (true);
CREATE POLICY "Update invite" ON combination_invites FOR UPDATE USING (true);
CREATE POLICY "Public read combinations" ON combinations FOR SELECT USING (true);
CREATE POLICY "Insert combination" ON combinations FOR INSERT WITH CHECK (true);
CREATE POLICY "Update combination" ON combinations FOR UPDATE USING (true);

-- ============================================================
-- МИГРАЦИЯ v1.7 · Пол + контекст на четенето
-- Ако базата вече съществува (създадена преди тази версия), пусни
-- само блока по-долу в SQL Editor — идемпотентен е (IF NOT EXISTS),
-- безопасен за повторно изпълнение.
-- ============================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE combination_invites ADD COLUMN IF NOT EXISTS inviter_gender TEXT;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS context TEXT;

-- ============================================================
-- МИГРАЦИЯ v1.8 · Запазени двойки + поправка на RLS
-- Идемпотентен блок — безопасен за повторно изпълнение.
-- ПРИЛОЖЕНА към живата база на 09.07.2026 (през Supabase MCP).
-- ============================================================
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS is_saved BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS saved_at TIMESTAMPTZ;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS chart_a JSONB;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS chart_b JSONB;
-- ПОПРАВКА: combinations нямаше UPDATE policy — update({context}) от
-- v1.7 тихо не правеше нищо (0 засегнати реда, без грешка от RLS).
-- Без нея и запазването/премахването на двойка нямаше да работи.
DROP POLICY IF EXISTS "Update combination" ON combinations;
CREATE POLICY "Update combination" ON combinations FOR UPDATE USING (true);

-- ============================================================
-- МИГРАЦИЯ v1.10 · Аватар (снимка на потребителя)
-- Съхранява се като Base64 data URL (~100px JPEG, качество 0.7).
-- Идемпотентен блок — безопасен за повторно изпълнение.
-- ============================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar TEXT;

-- ============================================================
-- МИГРАЦИЯ v1.11 · Семейни връзки + родова корекция
-- inviter_gender/invitee_gender: полът на двамата в комбинацията,
-- записан в момента на приемане на поканата (за родовата корекция
-- на текстовете спрямо читателя — viewerGender).
-- relationship_detail: под-тип на роднинската връзка ("mother",
-- "father", "brother", "sister", "child", "grandparent", "kum",
-- "other") — попълва се само когато context е "family", иначе NULL.
-- Идемпотентен блок — безопасен за повторно изпълнение.
-- ============================================================
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS inviter_gender TEXT;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS invitee_gender TEXT;
ALTER TABLE combinations ADD COLUMN IF NOT EXISTS relationship_detail TEXT;
