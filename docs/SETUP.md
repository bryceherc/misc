# Blue Mountains packing list: setup

The page is `docs/index.html`. It works right away in **preview mode**, where changes save only on
your own device. To share one live list with everyone, connect it to a free Firebase database and
publish it with GitHub Pages. This takes about 10 minutes.

## 1. Create the Firebase database (free)

1. Go to <https://console.firebase.google.com> and click **Create a project**. Name it something
   like `blue-mountains-trip`. You can turn Google Analytics off.
2. In the left menu open **Build → Firestore Database** and click **Create database**.
   - Location: `australia-southeast1 (Sydney)`.
   - Start in **production mode**.
3. Open the **Rules** tab, replace everything with the contents of [`firestore.rules`](firestore.rules),
   and click **Publish**.
4. Go to **Project settings** (the gear icon) → **Your apps** → click the **`</>` (Web)** icon.
   Give it any nickname, leave Firebase Hosting unticked, and click **Register app**.
5. Copy the `firebaseConfig = { ... }` object it shows you.

## 2. Paste the config into the page

Open [`config.js`](config.js) and replace `null` with the object you copied:

```js
export const FIREBASE_CONFIG = {
  apiKey: "AIza...",
  authDomain: "blue-mountains-trip.firebaseapp.com",
  projectId: "blue-mountains-trip",
  storageBucket: "blue-mountains-trip.appspot.com",
  messagingSenderId: "...",
  appId: "..."
};
```

This config isn't a secret. It only identifies the project, and `firestore.rules` controls what
can be read or written. Commit and push the change.

## 3. Publish with GitHub Pages

1. On GitHub, open the repo's **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to *Deploy from a branch*, set the branch to
   `main` and the folder to `/docs`, then click **Save**.
3. After a minute or so the site is live at **https://bryceherc.github.io/misc/**.

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
- **Offline.** The page keeps a copy on each phone. If you lose signal in the valleys, it still
  opens, and your changes sync once you're back in range.
- **Starting over.** Delete the `trips` collection in the Firestore console. The next visit
  creates a fresh starter list.
- **Trip dates and names.** Tap the gear icon on the page to set the dates, rename the trip, or
  add and remove people. When you remove someone, their items go back to Unassigned.
