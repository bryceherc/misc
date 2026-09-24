-- Already run on 2026-09-24.
-- Simplify the list: the Airbnb kitchen is equipped.
-- Only removes items nobody has claimed yet, so nothing a friend signed up for disappears.

-- 1. Remove unclaimed kitchen gear, plus extras the Airbnb will already have.
delete from public.packing_items
where trip_id = 'bm-1ev8e183qete'
  and (data ->> 'owner') is null
  and lower(data ->> 'name') <> 'esky'
  and (data ->> 'category' = 'Kitchen & BBQ'
       or lower(data ->> 'name') in (
         'cooking oil, salt & pepper', 'butter, spreads & sauces', 'hand soap & sanitiser',
         'tissues', 'extra toilet paper', 'power board / extension cord', 'bread & wraps for lunches',
         'lunch fillings', 'chips & dips', 'hot chocolate', 'soft drinks & sparkling water',
         'party card game', 'fruit'));

-- 2. Keep the esky, filed under Food & Drinks.
update public.packing_items
set data = jsonb_set(data, '{category}', '"Food & Drinks"'), updated_at = now()
where trip_id = 'bm-1ev8e183qete' and lower(data ->> 'name') = 'esky';

-- 3. Add a few shared meals and extras for anyone to claim (skips anything already there).
with new_items as (select v.*, row_number() over () as rn from (values
  ('Food & Drinks',       'Friday night dinner',     'for 10', 'Something easy after the drive'),
  ('Food & Drinks',       'Saturday lunch',          'for 10', 'Sandwich stuff or a pub lunch'),
  ('Food & Drinks',       'Sunday brunch',           'for 10', ''),
  ('Food & Drinks',       'Cheese & crackers',       '',       ''),
  ('Food & Drinks',       'Saturday night dessert',  'for 10', ''),
  ('Entertainment',       'Outdoor games',           '',       'Frisbee, footy'),
  ('Toiletries & Health', 'Painkillers & hydralyte', '',       '')
) as v(category, name, qty, note)), numbered as (
  select n.* from new_items n
  where not exists (select 1 from public.packing_items i
                    where i.trip_id = 'bm-1ev8e183qete' and lower(i.data ->> 'name') = lower(n.name))
)
insert into public.packing_items (trip_id, id, data)
select 'bm-1ev8e183qete', 'std-' || lpad(rn::text, 3, '0') || '-' || substr(md5(random()::text), 1, 6),
  jsonb_build_object('name', name, 'category', category, 'qty', qty, 'note', note,
    'owner', null, 'packed', false, 'packedBy', '{}'::jsonb,
    'ownerChangedBy', '', 'ownerChangedAt', 0,
    'createdAt', (extract(epoch from now()) * 1000)::bigint + rn)
from numbered;

-- 4. Show the shared list now (personal "Everyone" items not shown).
select data ->> 'category' as category, data ->> 'name' as item,
       case when data ->> 'owner' is null then 'Unassigned' else 'Claimed' end as status
from public.packing_items
where trip_id = 'bm-1ev8e183qete' and coalesce(data ->> 'owner', '') <> '*'
order by array_position(array['Food & Drinks','Kitchen & BBQ','Clothing','Hiking Gear','Entertainment','Toiletries & Health','Misc'], data ->> 'category'),
         (data ->> 'createdAt')::bigint;
