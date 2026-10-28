-- TODO: ตรวจสอบ policy ทั้งหมดก่อนใช้งานจริง
create function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

alter table profiles        enable row level security;
alter table categories      enable row level security;
alter table issues          enable row level security;
alter table issue_images    enable row level security;
alter table issue_followers enable row level security;
alter table issue_updates   enable row level security;
alter table feedback        enable row level security;

-- profiles: เห็น/แก้ได้เฉพาะของตัวเอง (แก้ role ไม่ได้), admin เห็นทั้งหมด
create policy profiles_select on profiles for select using (id = auth.uid() or is_admin());
create policy profiles_update on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from profiles where id = auth.uid()));

create policy categories_read on categories for select using (true);

-- issues: ผู้ใช้ไม่ select ตารางตรง ให้อ่านผ่าน view public_issues (ไม่มี reporter_id)
create policy issues_select_own_or_admin on issues for select
  using (reporter_id = auth.uid() or is_admin());
create policy issues_insert on issues for insert with check (reporter_id = auth.uid());
create policy issues_update_admin on issues for update using (is_admin());

-- view รันด้วยสิทธิ์เจ้าของ (ข้าม RLS ของ issues) จึงเปิดเผยเฉพาะคอลัมน์ที่เลือกไว้
create view public_issues with (security_invoker = false) as
  select id, category_id, title, description, urgency, status, location,
         address_text, report_count, created_at, updated_at
  from issues;
grant select on public_issues to authenticated;

create policy images_select on issue_images for select to authenticated using (true);
create policy images_insert on issue_images for insert to authenticated
  with check (
    (kind in ('report','reopen') and exists (select 1 from issues i where i.id = issue_id and i.reporter_id = auth.uid()))
    or is_admin()
  );

create policy followers_select on issue_followers for select using (user_id = auth.uid() or is_admin());
create policy followers_insert on issue_followers for insert with check (user_id = auth.uid());
create policy followers_delete on issue_followers for delete using (user_id = auth.uid());

create policy updates_select on issue_updates for select to authenticated using (true);
create policy updates_write_admin on issue_updates for insert with check (is_admin());

create policy feedback_insert on feedback for insert with check (user_id = auth.uid());
create policy feedback_select on feedback for select using (user_id = auth.uid() or is_admin());

-- Storage bucket
insert into storage.buckets (id, name, public) values ('issue-images', 'issue-images', false)
  on conflict do nothing;
create policy storage_read on storage.objects for select to authenticated
  using (bucket_id = 'issue-images');
create policy storage_upload_own on storage.objects for insert to authenticated
  with check (bucket_id = 'issue-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy storage_upload_admin on storage.objects for insert to authenticated
  with check (bucket_id = 'issue-images' and is_admin());
