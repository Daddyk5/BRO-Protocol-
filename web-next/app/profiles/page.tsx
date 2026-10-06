"use client";

import { useState, type FormEvent } from "react";
import { Plus, Trash2 } from "lucide-react";

import { newId, type Profile } from "@/lib/data";
import { KEYS, useStoredState } from "@/lib/storage";

/** Match profiles: a name and notes the replies can draw on. Stored in this browser only. */
export default function ProfilesPage() {
  const [profiles, setProfiles, ready] = useStoredState<Profile[]>(KEYS.profiles, []);
  const [name, setName] = useState("");
  const [notes, setNotes] = useState("");

  const add = (e: FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setProfiles([{ id: newId(), name: name.trim(), notes: notes.trim() }, ...profiles]);
    setName("");
    setNotes("");
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <h1 className="font-display text-3xl tracking-[0.02em] text-text">Profiles</h1>
        <p className="text-sm text-muted">Pick a profile under “For” when composing and replies can use one detail. Notes stay in this browser.</p>
      </div>

      <form onSubmit={add} className="theme-fade flex flex-col gap-4 rounded-2xl border border-border bg-surface p-4 card-shadow">
        <label className="flex flex-col gap-2 text-sm font-semibold text-text">
          Name
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={40}
            className="theme-fade min-h-11 rounded-xl border border-border bg-bg px-4 text-base font-normal text-text"
          />
        </label>
        <label className="flex flex-col gap-2 text-sm font-semibold text-text">
          Notes
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={3}
            maxLength={900}
            placeholder="Loves ramen and bouldering. Free most Sundays."
            className="theme-fade rounded-xl border border-border bg-bg p-4 text-base font-normal text-text placeholder:text-muted"
          />
        </label>
        <button
          type="submit"
          disabled={!name.trim()}
          className="bg-brand-gradient inline-flex min-h-11 items-center justify-center gap-2 self-start rounded-xl px-4 text-xl font-bold text-white disabled:opacity-50"
        >
          <Plus aria-hidden className="size-4" />
          Add profile
        </button>
      </form>

      {ready && profiles.length === 0 && <p className="text-sm text-muted">No profiles yet.</p>}
      <ul className="flex flex-col gap-2">
        {profiles.map((p) => (
          <li key={p.id} className="theme-fade flex items-start gap-2 rounded-2xl border border-border bg-surface p-4 card-shadow">
            <div className="min-w-0 flex-1">
              <p className="font-semibold text-text">{p.name}</p>
              <p className="text-sm text-muted">{p.notes || "No notes yet"}</p>
            </div>
            <button
              type="button"
              aria-label={`Delete ${p.name}`}
              onClick={() => setProfiles(profiles.filter((x) => x.id !== p.id))}
              className="-m-2 inline-flex size-11 shrink-0 items-center justify-center rounded-full text-muted hover:text-text"
            >
              <Trash2 aria-hidden className="size-4" />
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
