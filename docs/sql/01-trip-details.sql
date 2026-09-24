-- Trip details for Medlow Bath, 25–27 Sep 2026: name, dates and the group. Already run on 2026-09-24.
do $$
declare
  n text;
  i int := 0;
  ppl jsonb;
begin
  select coalesce(data -> 'people', '{}'::jsonb) into ppl
    from public.packing_trips where id = 'bm-1ev8e183qete';

  foreach n in array array['Bryce','Sophie A','Sophie W','George','Fridge','Luke','Lizzie','Will','Lauren','Cesar'] loop
    i := i + 1;
    -- skip anyone already on the list (e.g. you added yourself)
    if not exists (
      select 1 from jsonb_each(ppl) p
      where lower(p.value ->> 'name') = lower(n)
        and coalesce((p.value ->> 'removed')::boolean, false) = false
    ) then
      perform public.packing_merge_trip('bm-1ev8e183qete', jsonb_build_object('people',
        jsonb_build_object('p' || substr(md5(random()::text), 1, 12),
          jsonb_build_object('name', n, 'removed', false,
            'joinedAt', (extract(epoch from now()) * 1000)::bigint + i))));
    end if;
  end loop;

  perform public.packing_merge_trip('bm-1ev8e183qete',
    '{"name": "Medlow Bath Weekend", "start": "2026-09-25", "end": "2026-09-27"}');
end $$;

select data ->> 'name' as trip, data ->> 'start' as leaving, data ->> 'end' as home,
       (select string_agg(p.value ->> 'name', ', ' order by (p.value ->> 'joinedAt')::bigint)
          from jsonb_each(data -> 'people') p
         where coalesce((p.value ->> 'removed')::boolean, false) = false) as people
  from public.packing_trips where id = 'bm-1ev8e183qete';
