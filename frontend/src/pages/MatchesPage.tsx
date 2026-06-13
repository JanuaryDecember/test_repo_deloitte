import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router';
import { fetchMatches } from '../api/client';
import type { MatchItem } from '../types/match';
import { useMatchCount } from '../contexts/MatchContext';
import { useAuth } from '../auth/useAuth';
import { getAccentColor } from '../utils/accentColor';
import styles from './MatchesPage.module.css';

export function MatchesPage() {
  const navigate = useNavigate();
  const { setMatchCount } = useMatchCount();
  const { user } = useAuth();

  const [matches, setMatches] = useState<MatchItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  // Increment to trigger a reload (initial load + retry)
  const [fetchKey, setFetchKey] = useState(0);

  const retry = useCallback(() => {
    setLoading(true);
    setError(null);
    setFetchKey((k) => k + 1);
  }, []);

  // All setState calls happen asynchronously (in .then/.catch) — satisfies the lint rule
  useEffect(() => {
    let cancelled = false;
    fetchMatches()
      .then((data) => {
        if (!cancelled) {
          setMatches(data);
          setMatchCount(data.length);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setError('Could not load matches. Please try again.');
          setLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [fetchKey, setMatchCount]);

  useEffect(() => {
    document.title = 'Deloitter — Matches';
  }, []);

  const openTeamsChat = useCallback((matchEmail: string) => {
    const users = user?.email
      ? `${encodeURIComponent(user.email)},${encodeURIComponent(matchEmail)}`
      : encodeURIComponent(matchEmail);
    const url = `https://teams.microsoft.com/l/chat/0/0?users=marroman@deloittece.com`;
    window.open(url, '_blank');
  }, [user]);

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>Your matches</h1>
      <p className={styles.subtitle}>
        When you both like each other, the compatibility score and contact details unlock.
      </p>

      {loading && (
        <div className={styles.skeletonGrid}>
          {[0, 1, 2].map((i) => (
            <div key={i} className={styles.skeletonCard}>
              <div className={styles.skeletonAvatar} />
              <div className={styles.skeletonLine} />
              <div className={`${styles.skeletonLine} ${styles.skeletonLineShort}`} />
              <div className={styles.skeletonLine} />
            </div>
          ))}
        </div>
      )}

      {error && (
        <div className={styles.errorCard}>
          <p className={styles.errorTitle}>Something went wrong</p>
          <p className={styles.errorMsg}>{error}</p>
          <button className={styles.retryBtn} onClick={retry}>
            Retry
          </button>
        </div>
      )}

      {!loading && !error && matches.length === 0 && (
        <div className={styles.emptyCard}>
          <div className={styles.emptyEmoji} aria-hidden="true">💚</div>
          <h2 className={styles.emptyTitle}>No matches yet</h2>
          <p className={styles.emptySubtitle}>
            Keep swiping in Discover — matches show up here.
          </p>
          <button className={styles.emptyBtn} onClick={() => navigate('/discover')}>
            Start swiping
          </button>
        </div>
      )}

      {!loading && !error && matches.length > 0 && (
        <div className={styles.grid}>
          {matches.map((m) => (
            <div key={m.matchId} className={styles.matchCard}>
              {/* Top row: avatar + name/role + score badge */}
              <div className={styles.topRow}>
                <div
                  className={styles.avatar}
                  style={{ background: getAccentColor(m.matchedEmployeeId) }}
                >
                  {m.initials}
                </div>
                <div className={styles.nameBlock}>
                  <p className={styles.cardName}>
                    {m.firstName} {m.lastName}
                  </p>
                  <p className={styles.cardRole}>
                    {m.roleFamily} · {m.serviceLine}
                  </p>
                </div>
                <div className={styles.scoreBadge}>
                  <div className={styles.scoreNum}>{m.score}%</div>
                  <div className={styles.scoreLabel}>match</div>
                </div>
              </div>

              {/* Shared interest / competency chips */}
              {(m.sharedInterests.length > 0 || m.sharedCompetencies.length > 0) && (
                <div className={styles.chips}>
                  {m.sharedInterests.map((tag) => (
                    <span key={tag} className={styles.chip}>{tag}</span>
                  ))}
                  {m.sharedCompetencies.map((c) => (
                    <span key={c} className={styles.chip}>{c}</span>
                  ))}
                </div>
              )}

              <hr className={styles.divider} />

              {/* Contact row */}
              <div className={styles.contactRow}>
                <span aria-hidden="true">💬</span>
                <span className={styles.contactHandle}>{m.contactInfo}</span>
              </div>

              {/* Message button */}
              <button
                type="button"
                className={styles.messageBtn}
                onClick={() => openTeamsChat(m.contactInfo)}
              >
                Message on Teams
              </button>
            </div>
          ))}
        </div>
      )}

    </div>
  );
}



