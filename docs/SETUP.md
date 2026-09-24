# Blue Mountains packing list: setup

The page is `docs/index.html`. It works right away in **preview mode**, where changes save only on
your own device. To share one live list with everyone, connect it to Supabase and publish it with
GitHub Pages. This takes about 10 minutes.

## 1. Set up the Supabase database

**Pick a project.** The free plan allows two active projects. If you have a free slot, create a new
project for the trip at <https://supabase.com/dashboard> (choose the **Sydney** region). You can
also use your existing project: everything this creates is named `packing_*`, and the page's key
can only reach those tables and only this trip. Nothing else in your project is exposed.

1. In the project, open **SQL Editor → New query**.
2. Paste the whole of [`supabase.sql`](supabase.sql) and click **Run**. You should see
   "Success. No rows returned". It's safe to run again.
3. Open **Project Settings → API Keys** (on older dashboards, **Settings → API**) and copy:
   - the **Project URL**, e.g. `https://abcdefghijkl.supabase.co`
   - the **publishable** key (`sb_publishable_...`), or on older projects the **anon public** key.

   **Never** use the `secret` / `service_role` key. It bypasses all the access rules.

## 2. Paste the details into the page

Edit [`config.js`](config.js):

```js
export const SUPABASE_URL = "https://abcdefghijkl.supabase.co";
export const SUPABASE_KEY = "sb_publishable_...";
```

The publishable/anon key is designed to be public. What anyone can do with it is limited by the
access rules in `supabase.sql`. Commit and push the change.

## 3. Publish with GitHub Pages

1. Merge this branch into `main`.
2. On GitHub, open the repo's **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to *Deploy from a branch*, set the branch to
   `main` and the folder to `/docs`, then click **Save**.
4. After a minute or so the site is live at **https://bryceherc.github.io/misc/**.

GitHub Pages is free for public repos. For a private repo you need a paid GitHub plan.

## 4. Share it

The first person to open the page creates the list, with a starter set of items. Paste something
like this into the group chat:

> 🏔️ Packing list for the Blue Mountains: https://bryceherc.github.io/misc/
> 1. Pick your name (or add yourself).
> 2. Tap **I'll bring it** on anything in *Unassigned* you can bring.
> 3. Use **My list** to tick things off as you pack.
> Anyone can add items or reassign them. Tap an item to edit it.

## Good to know

- **No logins.** Anyone with the link can edit, so only share it with the group.
- **Offline.** Each phone keeps the last copy, so the list still opens without signal. Changes
  need a connection.
- **Free-plan pausing.** Supabase pauses free projects after about a week with no activity. If
  the page stops loading, open the project in the Supabase dashboard and click **Restore**.
  If you use your existing, active project, this won't happen.
- **Starting over.** Run `delete from packing_trips;` in the SQL Editor. The next visit creates a
  fresh starter list.
- **Removing it completely** when the trip's over:
  ```sql
  drop table if exists packing_items, packing_trips;
  drop function if exists packing_seed, packing_merge_item, packing_merge_trip, packing_deep_merge;
  ```
- **Trip dates and names.** Tap the gear icon on the page to set the dates, rename the trip, or
  add and remove people. When you remove someone, their items go back to Unassigned.
