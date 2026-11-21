# Shelf

A reading list for small book clubs. Members pick the next book, track progress and talk about it.

## Scope

- Clubs with up to 30 members, invite by link.
- A shared list of books, with votes for the next one.
- Reading progress per member.

## Out of scope

- Public profiles and following people.
- Selling books.

## Business rules

- A member only sees the clubs they belong to. (`src/lib/db.ts:18`)
- A vote closes when the club admin picks the next book. (`src/lib/votes.ts:42`)

## Architecture

- Next.js App Router with server actions, because the app is small and has one team. (2026-11-02)
- Postgres with Drizzle, migrations forward only. (2026-11-02)

## Direction

- Reading goals per club
- Email digest on Sundays
