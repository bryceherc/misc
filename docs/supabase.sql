-- Blue Mountains packing list: run this once in Supabase → SQL Editor → New query → Run.
-- It only creates the two packing_* tables and three packing_* functions, and it only opens
-- them to the one trip ID in config.js. Nothing else in your project is touched.

create table if not exists public.packing_trips (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint packing_trips_size check (pg_column_size(data) < 50000)
);

create table if not exists public.packing_items (
  trip_id    text not null references public.packing_trips (id) on delete cascade,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (trip_id, id),
  constraint packing_items_size check (pg_column_size(data) < 20000),
  constraint packing_items_name check (length(coalesce(data ->> 'name', '')) between 1 and 80)
);

-- Access: anyone with the page (the public anon/publishable key) can read and edit this one trip.
alter table public.packing_trips enable row level security;
alter table public.packing_items enable row level security;

drop policy if exists packing_trips_this_trip on public.packing_trips;
create policy packing_trips_this_trip on public.packing_trips
  for all to anon, authenticated
  using (id = 'bm-1ev8e183qete') with check (id = 'bm-1ev8e183qete');

drop policy if exists packing_items_this_trip on public.packing_items;
create policy packing_items_this_trip on public.packing_items
  for all to anon, authenticated
  using (trip_id = 'bm-1ev8e183qete') with check (trip_id = 'bm-1ev8e183qete');

grant select, insert, update, delete on public.packing_trips, public.packing_items to anon, authenticated;

-- Merge nested objects (e.g. who has packed an "Everyone" item) so two people editing at
-- once don't overwrite each other's changes.
create or replace function public.packing_deep_merge(a jsonb, b jsonb)
returns jsonb language plpgsql immutable set search_path = '' as $$
declare
  k text;
  v jsonb;
  r jsonb := a;
begin
  if jsonb_typeof(a) is distinct from 'object' or jsonb_typeof(b) is distinct from 'object' then
    return b;
  end if;
  for k, v in select * from jsonb_each(b) loop
    r := jsonb_set(r, array[k], case when r ? k then public.packing_deep_merge(r -> k, v) else v end);
  end loop;
  return r;
end $$;

create or replace function public.packing_merge_trip(p_trip text, p_patch jsonb)
returns void language plpgsql set search_path = '' as $$
begin
  insert into public.packing_trips as t (id, data) values (p_trip, p_patch)
  on conflict (id) do update
    set data = public.packing_deep_merge(t.data, excluded.data), updated_at = now();
end $$;

create or replace function public.packing_merge_item(p_trip text, p_id text, p_patch jsonb)
returns void language plpgsql set search_path = '' as $$
begin
  -- Update first: a partial patch (e.g. just a tick) has no name, so it can't go through INSERT.
  update public.packing_items
    set data = public.packing_deep_merge(data, p_patch), updated_at = now()
    where trip_id = p_trip and id = p_id;
  if not found then
    insert into public.packing_items (trip_id, id, data) values (p_trip, p_id, p_patch);
  end if;
end $$;

-- Creates the trip and its starter items the first time anyone opens the page.
-- Safe if several people open it at the same moment.
create or replace function public.packing_seed(p_trip text, p_trip_data jsonb, p_items jsonb)
returns void language plpgsql set search_path = '' as $$
begin
  insert into public.packing_trips (id, data) values (p_trip, p_trip_data)
  on conflict (id) do nothing;
  if found then
    insert into public.packing_items (trip_id, id, data)
    select p_trip, e ->> 'id', e - 'id' from jsonb_array_elements(p_items) e
    on conflict do nothing;
  end if;
end $$;

grant execute on function public.packing_deep_merge(jsonb, jsonb),
  public.packing_merge_trip(text, jsonb),
  public.packing_merge_item(text, text, jsonb),
  public.packing_seed(text, jsonb, jsonb) to anon, authenticated;

-- Live updates: tell Supabase Realtime to broadcast changes to these two tables.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and tablename = 'packing_trips') then
    alter publication supabase_realtime add table public.packing_trips;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and tablename = 'packing_items') then
    alter publication supabase_realtime add table public.packing_items;
  end if;
end $$;
