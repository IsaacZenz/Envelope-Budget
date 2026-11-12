# Envelope Budget

A phone-first envelope budget. It's a static site (HTML, CSS and JS, with no build step) that uses Supabase for accounts and data.

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app |
| `config.js` | Your Supabase project URL and anon key |
| `schema.sql` | Tables, security rules and live-update setup. Run it once, for a brand-new project. |
| `migration-goals-and-order.sql` | Adds savings goals and custom order to an existing project. Already included in `schema.sql`. |
| `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`, `favicon-32.png`, `manifest.webmanifest` | Home-screen icon and app name ("Envelopes") |

## Setup

Menu names below match Supabase's dashboard as of late 2026. They may shift slightly.

1. **Create a Supabase project** at supabase.com.
2. **Run the schema.** Go to SQL Editor, click New query, paste in `schema.sql`, then click Run.
3. **Turn on email + password sign-in with confirmation.** Go to Authentication, then Sign In / Providers, then Email.
   - Make sure Email is enabled.
   - Turn **Confirm email** on.
   - Set the minimum password length to **8**, which matches the app.
4. **Set redirect URLs.** Go to Authentication, then URL Configuration.
   - Set **Site URL** to your live address, for example `https://yourname.github.io/envelope-budget/`.
   - Add that address under **Redirect URLs**. Add `http://localhost:8000/` too, for local testing.
5. **Fill in `config.js`.** Copy the Project URL and the anon (or publishable) key from Project Settings, then API. The anon key is safe to publish. Never use the `service_role` or secret key.
6. **Deploy.** Push the folder to a GitHub repo, then turn on Settings, then Pages, and deploy from the `main` branch root. Netlify, Vercel and Cloudflare Pages also work. Point any of them at the repo with no build command.

## Add it to your iPhone home screen

Open the site in **Safari**, tap **Share**, then **Add to Home Screen**. It opens full-screen with the pixel icon. If you added it before the icon existed, delete the old one and add it again, because iPhone keeps the old icon.

## Email sending

Supabase's built-in email only sends to members of your Supabase organization, and only about 2 emails an hour. That's fine while you test with your own address. Before anyone else signs up, connect a custom SMTP provider such as Resend under Authentication, then Emails, then SMTP Settings.

## Test locally

Auth links need a real web address, so opening the file directly won't work. From this folder, run:

```
python3 -m http.server 8000
```

Then open http://localhost:8000/.

## Test checklist

- [ ] Create an account. The "Check your email" screen appears.
- [ ] Sign in before confirming. The app asks you to confirm and offers to resend the link.
- [ ] Click the email link. You land in the app, signed in.
- [ ] Use a wrong password. You see "Email or password is incorrect."
- [ ] Use "Forgot password?". Its email link opens "Choose a new password", and the new password works.
- [ ] Add a transaction on your phone. It appears on your computer within a few seconds, or when you switch back to the tab.
- [ ] Sign out. The budget is gone from the screen. Sign back in and it reloads.
- [ ] Create a second test account. It sees none of the first account's data.
- [ ] In the SQL editor, run the "test oracle" query at the bottom of `schema.sql`. It returns zero rows.
- [ ] Create a **Savings goal** category ($500). It shows gold with a progress bar; assigning more than the goal is blocked.
- [ ] Tap **Fund $X**. The goal fills, turns chartreuse and says "Goal met!". Spending from it turns it gold again.
- [ ] **Make it a goal** on an existing category, **Edit goal**, then **Make it a regular category**. The money and history don't change.
- [ ] Tap **Reorder**, drag rows by their grips, tap **Done**. The order stays after a refresh and on your other devices.
