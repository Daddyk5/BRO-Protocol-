import { HOME_MODES } from "@/lib/modes";

import { ModeCard } from "./ModeCard";

/** 2 columns on phones (BANTER spans both), 3 from 768px. */
export function ModeGrid() {
  return (
    <section aria-labelledby="modes-heading" className="flex flex-col gap-2">
      <h2 id="modes-heading" className="text-xs font-semibold tracking-wide text-muted uppercase">
        Pick your play
      </h2>
      <div className="grid grid-cols-2 gap-2 sm:gap-4 md:grid-cols-3">
        {HOME_MODES.map((mode, i) => (
          <ModeCard key={mode.id} mode={mode} index={i} primary={i === 0} />
        ))}
      </div>
    </section>
  );
}
