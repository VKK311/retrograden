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
  email TEXT,
  birth_date TEXT NOT NULL,
  birth_time TEXT,
  birth_city TEXT NOT NULL,
  birth_lat NUMERIC(9,6) NOT NULL,
  birth_lon NUMERIC(9,6) NOT NULL,
  natal_chart JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Покани за комбинация
CREATE TABLE combination_invites (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  inviter_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
  inviter_name TEXT NOT NULL,
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
  result_json JSONB NOT NULL,
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
