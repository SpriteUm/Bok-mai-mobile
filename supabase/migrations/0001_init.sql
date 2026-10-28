create extension if not exists postgis;

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz default now()
);

create table categories (
  id serial primary key,
  code text unique not null,
  name_th text not null
);

insert into categories (code, name_th) values
  ('electric','ไฟฟ้า'), ('water','น้ำประปา'), ('road','ถนน'),
  ('waste','ขยะ'), ('other','อื่นๆ');

create table issues (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id),
  category_id int references categories(id),
  title text not null,
  description text,
  urgency text check (urgency in ('low','medium','high')) default 'medium',
  status text check (status in ('pending','in_progress','resolved')) default 'pending',
  location geography(point, 4326) not null,
  address_text text,
  report_count int default 1,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index on issues using gist (location);

create table issue_images (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  storage_path text not null,
  kind text check (kind in ('report','resolution','reopen')) default 'report'
);

create table issue_followers (
  issue_id uuid references issues(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  primary key (issue_id, user_id)
);

create table issue_updates (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  actor_id uuid references profiles(id),
  status text,
  note text,
  created_at timestamptz default now()
);

create table feedback (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  user_id uuid references profiles(id),
  rating int check (rating between 1 and 5),
  tags text[],
  comment text,
  sentiment text,
  is_urgent boolean default false,
  created_at timestamptz default now()
);

-- สร้าง profile อัตโนมัติเมื่อสมัครสมาชิก
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- นับจำนวนผู้แจ้งเมื่อกด +1 / ยกเลิก
create function sync_report_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update issues set report_count = report_count + 1, updated_at = now() where id = new.issue_id;
  elsif tg_op = 'DELETE' then
    update issues set report_count = greatest(report_count - 1, 1) where id = old.issue_id;
  end if;
  return null;
end $$;
create trigger issue_followers_count after insert or delete on issue_followers
  for each row execute function sync_report_count();

-- Realtime
alter publication supabase_realtime add table issues, issue_updates;
