"use client";

import type { ReplyOption } from "./api";
import type { ModeId } from "./modes";
import { KEYS, readJson, writeJson } from "./storage";

/** One generate request, kept so the user can pick the conversation back up. */
export interface Conversation {
  id: string;
  mode: ModeId;
  context: string;
  options: ReplyOption[];
  profileId?: string;
  at: number;
}

export interface SavedReply {
  id: string;
  text: string;
  mode: ModeId;
  at: number;
}

export interface Profile {
  id: string;
  name: string;
  notes: string;
}

/** Each entry is one request: [epoch ms, replies written]. */
export type UsageEvent = [number, number];

const RECENT_LIMIT = 20;
const EVENTS_LIMIT = 2000;

export function newId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

/** A random per-browser ID for the backend's per-device rate limit. */
export function deviceId(): string {
  const existing = readJson<string>(KEYS.deviceId, "");
  if (existing) return existing;
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  const id = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
  writeJson(KEYS.deviceId, id);
  return id;
}

export function saveConversation(conversation: Conversation): void {
  const recent = readJson<Conversation[]>(KEYS.recent, []).filter((c) => c.id !== conversation.id);
  writeJson(KEYS.recent, [conversation, ...recent].slice(0, RECENT_LIMIT));
}

export function recordUsage(replies: number): void {
  const events = readJson<UsageEvent[]>(KEYS.events, []);
  writeJson(KEYS.events, [...events, [Date.now(), replies] as UsageEvent].slice(-EVENTS_LIMIT));
}

export function repliesThisWeek(events: UsageEvent[], now = Date.now()): number {
  const weekAgo = now - 7 * 24 * 60 * 60 * 1000;
  return events.reduce((sum, [at, replies]) => (at > weekAgo ? sum + replies : sum), 0);
}

export function snippet(text: string, max = 48): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}
