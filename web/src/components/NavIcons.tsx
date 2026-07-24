import type { ReactNode } from "react";

const iconClass = "h-5 w-5";

function Svg({ children }: { children: ReactNode }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={iconClass}
      aria-hidden
    >
      {children}
    </svg>
  );
}

export const NavIcons = {
  open: (
    <Svg>
      <rect x="4" y="3" width="16" height="18" rx="2" />
      <path d="M8 8h8M8 12h8M8 16h5" />
    </Svg>
  ),
  chat: (
    <Svg>
      <path d="M5 18.5V7a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H9l-4 2.5z" />
    </Svg>
  ),
  schedule: (
    <Svg>
      <rect x="3.5" y="5" width="17" height="15" rx="2" />
      <path d="M8 3.5v3M16 3.5v3M3.5 10h17" />
    </Svg>
  ),
  roster: (
    <Svg>
      <circle cx="9" cy="8" r="2.5" />
      <circle cx="16" cy="9" r="2" />
      <path d="M4.5 18c.6-2.4 2.4-3.5 4.5-3.5s3.9 1.1 4.5 3.5" />
      <path d="M13.5 18c.3-1.5 1.3-2.4 2.5-2.4 1.4 0 2.4 1 2.7 2.4" />
    </Svg>
  ),
  id: (
    <Svg>
      <rect x="3.5" y="6" width="17" height="12" rx="2" />
      <circle cx="9" cy="12" r="2" />
      <path d="M13 10.5h4.5M13 13.5h3" />
    </Svg>
  ),
  leave: (
    <Svg>
      <path d="M7 4v16M7 8h7l-1.5 3L14 14H7" />
    </Svg>
  ),
  profile: (
    <Svg>
      <circle cx="12" cy="8" r="3" />
      <path d="M5.5 19c1.2-3 3.4-4.5 6.5-4.5s5.3 1.5 6.5 4.5" />
    </Svg>
  ),
  clients: (
    <Svg>
      <circle cx="9" cy="9" r="3" />
      <path d="M3.5 19c.8-2.8 2.8-4.2 5.5-4.2" />
      <circle cx="16.5" cy="10" r="2.5" />
      <path d="M12.5 19c.5-2 1.9-3.2 4-3.2S20.5 17 21 19" />
    </Svg>
  ),
} as const;
