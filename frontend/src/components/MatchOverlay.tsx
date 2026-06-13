import { useEffect, useRef, useState } from 'react';
import type { MatchResult } from '../types/match';
import { getAccentColor } from '../utils/accentColor';
import styles from './MatchOverlay.module.css';

interface MatchOverlayProps {
  match: MatchResult;
  me: { initials: string };
  onClose: () => void;
  onViewMatches: () => void;
}

// Confetti palette mirrors the design comp (lines 471)
const CONFETTI_PALETTE = [
  'oklch(0.70 0.16 145)',
  'oklch(0.78 0.13 70)',
  'oklch(0.66 0.15 300)',
  'oklch(0.70 0.16 30)',
  'oklch(0.72 0.12 180)',
];

interface ConfettiPiece {
  left: string;
  size: number;
  bg: string;
  dur: string;
  delay: string;
  radius: string;
}

function buildConfetti(): ConfettiPiece[] {
  return Array.from({ length: 18 }).map((_, i) => ({
    left: `${(i * 5.4 + 2).toFixed(1)}%`,
    size: 8 + (i % 3) * 4,
    bg: CONFETTI_PALETTE[i % CONFETTI_PALETTE.length],
    dur: `${(1.5 + (i % 4) * 0.3).toFixed(2)}s`,
    delay: `${((i % 6) * 0.12).toFixed(2)}s`,
    radius: i % 2 ? '50%' : '2px',
  }));
}

const confettiPieces = buildConfetti();

export function MatchOverlay({ match, me, onClose, onViewMatches }: MatchOverlayProps) {
  const [toast, setToast] = useState<string | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Auto-dismiss toast after 2 seconds
  useEffect(() => {
    if (toast) {
      if (toastTimer.current) clearTimeout(toastTimer.current);
      toastTimer.current = setTimeout(() => setToast(null), 2000);
    }
    return () => {
      if (toastTimer.current) clearTimeout(toastTimer.current);
    };
  }, [toast]);

  const handleCopy = () => {
    const handle = match.contactInfo;
    navigator.clipboard.writeText(handle).catch(() => {
      // Fallback for browsers without clipboard API
    });
    setToast(`Copied ${handle}`);
  };

  const matchAccent = getAccentColor(match.matchedEmployeeId);
  const fullName = `${match.firstName} ${match.lastName}`;

  return (
    <>
      <div className={styles.overlay} role="dialog" aria-modal="true" aria-label="It's a match!">
        {/* Confetti */}
        {confettiPieces.map((piece, i) => (
          <div
            key={i}
            className={styles.confettiPiece}
            style={{
              left: piece.left,
              width: piece.size,
              height: piece.size,
              background: piece.bg,
              borderRadius: piece.radius,
              animation: `dlConfetti ${piece.dur} ease-in ${piece.delay} forwards`,
            }}
          />
        ))}

        {/* Modal card */}
        <div className={styles.modal}>
          <div className={styles.matchLabel}>It's a match</div>
          <div className={styles.compatibleTitle}>You're compatible!</div>

          {/* Overlapping avatars */}
          <div className={styles.avatars}>
            <div
              className={styles.avatar}
              style={{ background: 'oklch(0.70 0.16 145)' }}
              aria-label={`Your avatar: ${me.initials}`}
            >
              {me.initials}
            </div>
            <div
              className={`${styles.avatar} ${styles.avatarMatch}`}
              style={{ background: matchAccent }}
              aria-label={`${fullName}'s avatar: ${match.initials}`}
            >
              {match.initials}
            </div>
          </div>

          <div className={styles.matchName}>You and {fullName}</div>
          <div className={styles.score}>{match.score}%</div>
          <div className={styles.compatibleLabel}>compatible</div>

          <p className={styles.shareSummary}>
            Because you share{' '}
            <span className={styles.shareSummaryBold}>{match.shareSummary}</span>.
          </p>

          {/* Contact card */}
          <div className={styles.contactCard}>
            <div className={styles.contactInfo}>
              <div className={styles.contactLabel}>Reach out on</div>
              <div className={styles.contactHandle}>{match.contactInfo}</div>
            </div>
            <button type="button" className={styles.copyBtn} onClick={handleCopy}>
              Copy
            </button>
          </div>

          {/* Action buttons */}
          <div className={styles.actions}>
            <button type="button" className={styles.keepSwipingBtn} onClick={onClose}>
              Keep swiping
            </button>
            <button type="button" className={styles.viewMatchesBtn} onClick={onViewMatches}>
              View matches
            </button>
          </div>
        </div>
      </div>

      {/* Toast */}
      {toast && (
        <div className={styles.toast} role="status" aria-live="polite">
          {toast}
        </div>
      )}
    </>
  );
}

