-- Swap Luke for Maddie. Already run on 2026-09-24.
do $$
declare
  luke text;
begin
  -- 1. Remove Luke and put anything he claimed back to Unassigned.
  select p.key into luke
    from public.packing_trips t, jsonb_each(t.data -> 'people') p
   where t.id = 'bm-1ev8e183qete' and lower(p.value ->> 'name') = 'luke'
     and coalesce((p.value ->> 'removed')::boolean, false) = false;
  if luke is not null then
    perform public.packing_merge_trip('bm-1ev8e183qete',
      jsonb_build_object('people', jsonb_build_object(luke, jsonb_build_object('removed', true))));
    update public.packing_items
       set data = data || jsonb_build_object('owner', null, 'packed', false,
                    'ownerChangedBy', '', 'ownerChangedAt', (extract(epoch from now()) * 1000)::bigint),
           updated_at = now()
     where trip_id = 'bm-1ev8e183qete' and data ->> 'owner' = luke;
  end if;

  -- 2. Add Maddie (skipped if she's already on the list).
  if not exists (
    select 1 from public.packing_trips t, jsonb_each(t.data -> 'people') p
     where t.id = 'bm-1ev8e183qete' and lower(p.value ->> 'name') = 'maddie'
       and coalesce((p.value ->> 'removed')::boolean, false) = false
  ) then
    perform public.packing_merge_trip('bm-1ev8e183qete', jsonb_build_object('people',
      jsonb_build_object('p' || substr(md5(random()::text), 1, 12),
        jsonb_build_object('name', 'Maddie', 'removed', false,
          'joinedAt', (extract(epoch from now()) * 1000)::bigint))));
  end if;
end $$;

-- Who's coming now
select string_agg(p.value ->> 'name', ', ' order by (p.value ->> 'joinedAt')::bigint) as people
  from public.packing_trips t, jsonb_each(t.data -> 'people') p
 where t.id = 'bm-1ev8e183qete' and coalesce((p.value ->> 'removed')::boolean, false) = false;
