-- ═══════════════════════════════════════════════════════════════
--  FHZ ART FEST — SUPABASE DATABASE SETUP
--  Run this entire script in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. RESULTS TABLE
-- Stores each programme result with 1st/2nd/3rd prize details
CREATE TABLE IF NOT EXISTS results (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  programme_name   text NOT NULL,
  category         text,
  emoji            text DEFAULT '🎭',
  banner_url       text,

  -- 1st Prize
  first_name            text,
  first_team_id         integer,
  first_grade           text,
  first_chest_numbers   text,   -- comma-separated: "101,102"

  -- 2nd Prize
  second_name           text,
  second_team_id        integer,
  second_grade          text,
  second_chest_numbers  text,

  -- 3rd Prize
  third_name            text,
  third_team_id         integer,
  third_grade           text,
  third_chest_numbers   text,

  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- 2. STUDENTS TABLE
-- Stores participant info; scores are auto-computed from results
CREATE TABLE IF NOT EXISTS students (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name           text NOT NULL,
  chest_number   text NOT NULL UNIQUE,
  class          text,
  team_id        integer,
  extra_score    integer DEFAULT 0,   -- manual bonus points
  notes          text,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- 3. AUTO-UPDATE updated_at TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER results_updated_at
  BEFORE UPDATE ON results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER students_updated_at
  BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. ROW LEVEL SECURITY (RLS)
-- Enable RLS on both tables
ALTER TABLE results  ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- PUBLIC: Anyone can READ results and students (for the public results page)
CREATE POLICY "Public can read results"
  ON results FOR SELECT USING (true);

CREATE POLICY "Public can read students"
  ON students FOR SELECT USING (true);

-- PUBLIC: Anyone can INSERT/UPDATE/DELETE (admin pages use password protection in JS)
-- Note: For production, use Supabase Auth instead. For a school fest, JS password is fine.
CREATE POLICY "Anyone can insert results"
  ON results FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update results"
  ON results FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete results"
  ON results FOR DELETE USING (true);

CREATE POLICY "Anyone can insert students"
  ON students FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update students"
  ON students FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete students"
  ON students FOR DELETE USING (true);

-- 5. REALTIME
-- Enable realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE results;
ALTER PUBLICATION supabase_realtime ADD TABLE students;

-- ───────────────────────────────────────────────────────────────
-- OPTIONAL: Insert sample data to test
-- ───────────────────────────────────────────────────────────────
INSERT INTO students (name, chest_number, class, team_id) VALUES
  ('Ahmed Ali',       '101', '10A', 1),
  ('Fatima Zahra',    '102', '9B',  2),
  ('Mohammed Salim',  '103', '10B', 1),
  ('Aisha Noor',      '104', '8A',  3),
  ('Ibrahim Hassan',  '105', '9A',  4),
  ('Zainab Fathima',  '106', '10A', 2)
ON CONFLICT (chest_number) DO NOTHING;

INSERT INTO results (programme_name, category, emoji, first_name, first_team_id, first_grade, first_chest_numbers, second_name, second_team_id, second_grade, second_chest_numbers, third_name, third_team_id, third_grade, third_chest_numbers) VALUES
  ('Solo Dance',   'Dance',    '💃', 'Ahmed Ali',      1, 'A', '101', 'Fatima Zahra',  2, 'B', '102', 'Aisha Noor',     3, 'C', '104'),
  ('Elocution',    'Literary', '🎤', 'Fatima Zahra',   2, 'A', '102', 'Ibrahim Hassan',4, 'A', '105', 'Mohammed Salim', 1, 'B', '103'),
  ('Drawing',      'Art',      '🎨', 'Zainab Fathima', 2, 'A', '106', 'Ahmed Ali',     1, 'B', '101', NULL, NULL, NULL, NULL)
;
