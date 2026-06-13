import { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate } from 'react-router';
import { fetchStack, recordSwipe } from '../api/client';
import type { CandidateCard } from '../types/discover';
import type { MatchResult } from '../types/match';
import { useAuth } from '../auth/useAuth';
import { useMatchCount } from '../contexts/MatchContext';
import { MatchOverlay } from '../components/MatchOverlay';
import { CandidateCardContent } from '../components/CandidateCardContent';
import styles from './DiscoverPage.module.css';

type SwipeStatus = 'idle' | 'animating';

export function DiscoverPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { incrementMatchCount } = useMatchCount();

  // Track mount to avoid state updates after navigating away
  const mountedRef = useRef(true);
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const [stack, setStack] = useState<CandidateCard[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  // Start as true so the initial mount shows the skeleton immediately
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [swipeStatus, setSwipeStatus] = useState<SwipeStatus>('idle');
  // Increment to trigger a reload (initial load + retry)
  const [fetchKey, setFetchKey] = useState(0);
  // Match overlay — set when a mutual match is detected
  const [pendingMatch, setPendingMatch] = useState<MatchResult | null>(null);

  // Drag state — stored in refs to avoid re-renders during pointer move
  const dragging = useRef(false);
  const startX = useRef(0);
  const startY = useRef(0);
  const dx = useRef(0);
  const dy = useRef(0);

  const cardRef = useRef<HTMLDivElement | null>(null);
  const likeBadgeRef = useRef<HTMLDivElement | null>(null);
  const passBadgeRef = useRef<HTMLDivElement | null>(null);

  // All setState calls happen asynchronously (in .then/.catch) — satisfies the lint rule
  useEffect(() => {
    let cancelled = false;
    fetchStack()
      .then((data) => {
        if (!cancelled) {
          setStack(data);
          setCurrentIndex(0);
          setError(null);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setError('Could not load candidates. Please try again.');
          setLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [fetchKey]);

  const retry = useCallback(() => {
    setLoading(true);
    setError(null);
    setFetchKey((k) => k + 1);
  }, []);

  useEffect(() => {
    document.title = 'Deloitter — Discover';
  }, []);

  const remaining = stack.length - currentIndex;
  const topCard: CandidateCard | undefined = stack[currentIndex];
  // Distinguish between "never had any candidates" (no interests selected) vs "swiped them all"
  const noSelections = !loading && !error && stack.length === 0;
  const allSwiped = !loading && !error && stack.length > 0 && remaining === 0;
  const back1Exists = remaining >= 2;
  const back2Exists = remaining >= 3;

  // ---- Gesture handlers ----

  const springBack = useCallback(() => {
    const card = cardRef.current;
    if (!card) return;
    card.style.transition = 'transform .35s cubic-bezier(.2,.8,.3,1)';
    card.style.transform = 'translate(0,0) rotate(0deg)';
    card.style.cursor = 'grab';
    if (likeBadgeRef.current) likeBadgeRef.current.style.opacity = '0';
    if (passBadgeRef.current) passBadgeRef.current.style.opacity = '0';
  }, []);

  const commitSwipe = useCallback(
    (liked: boolean, candidateId: number) => {
      setCurrentIndex((i) => i + 1);
      setSwipeStatus('idle');
      // Await response to detect mutual matches — card animation already started
      recordSwipe({ candidateId, liked })
        .then((response) => {
          if (mountedRef.current && response.match) {
            incrementMatchCount();
            setPendingMatch(response.match);
          }
        })
        .catch((err: unknown) => {
          console.error('recordSwipe failed:', err);
        });
    },
    [incrementMatchCount]
  );

  const flyOff = useCallback(
    (dir: 'like' | 'pass', candidateId: number) => {
      setSwipeStatus('animating');
      const card = cardRef.current;
      if (card) {
        const x = dir === 'like' ? window.innerWidth : -window.innerWidth;
        const rot = dir === 'like' ? 24 : -24;
        card.style.transition = 'transform .42s ease-in, opacity .42s ease-in';
        card.style.transform = `translate(${x}px,-50px) rotate(${rot}deg)`;
        card.style.opacity = '0';
      }
      setTimeout(() => {
        commitSwipe(dir === 'like', candidateId);
      }, 300);
    },
    [commitSwipe]
  );

  const onPointerDown = useCallback((e: React.PointerEvent<HTMLDivElement>) => {
    if (!topCard || swipeStatus !== 'idle' || pendingMatch) return;
    dragging.current = true;
    startX.current = e.clientX;
    startY.current = e.clientY;
    dx.current = 0;
    dy.current = 0;
    const card = cardRef.current;
    if (card) {
      card.style.transition = 'none';
      card.style.cursor = 'grabbing';
    }
    try {
      e.currentTarget.setPointerCapture(e.pointerId);
    } catch {
      // ignore
    }
  }, [topCard, swipeStatus, pendingMatch]);

  const onPointerMove = useCallback((e: React.PointerEvent<HTMLDivElement>) => {
    if (!dragging.current) return;
    const card = cardRef.current;
    if (!card) return;
    dx.current = e.clientX - startX.current;
    dy.current = e.clientY - startY.current;
    card.style.transform = `translate(${dx.current}px,${dy.current}px) rotate(${dx.current * 0.05}deg)`;
    if (likeBadgeRef.current) {
      likeBadgeRef.current.style.opacity = String(Math.max(0, Math.min(1, dx.current / 110)));
    }
    if (passBadgeRef.current) {
      passBadgeRef.current.style.opacity = String(Math.max(0, Math.min(1, -dx.current / 110)));
    }
  }, []);

  const onPointerUp = useCallback(() => {
    if (!dragging.current) return;
    dragging.current = false;
    if (!topCard) return;
    if (dx.current > 110) {
      flyOff('like', topCard.id);
    } else if (dx.current < -110) {
      flyOff('pass', topCard.id);
    } else {
      springBack();
    }
  }, [topCard, flyOff, springBack]);

  const handleLike = useCallback(() => {
    if (!topCard || swipeStatus !== 'idle' || pendingMatch) return;
    flyOff('like', topCard.id);
  }, [topCard, swipeStatus, flyOff, pendingMatch]);

  const handlePass = useCallback(() => {
    if (!topCard || swipeStatus !== 'idle' || pendingMatch) return;
    flyOff('pass', topCard.id);
  }, [topCard, swipeStatus, flyOff, pendingMatch]);

  // ---- Render ----

  const meInitials = user
    ? `${user.firstName.charAt(0)}${user.lastName.charAt(0)}`.toUpperCase()
    : '';

  return (
    <div className={styles.page}>
      {/* Header */}
      <div className={styles.headerRow}>
        <div>
          <h1 className={styles.title}>Discover colleagues</h1>
          <p className={styles.subtitle}>Ranked by what you share · score hidden until you match</p>
        </div>
      </div>

      {/* Card stack */}
      <div className={styles.stackContainer}>
        {loading && (
          <div className={styles.skeletonCard}>
            <div className={styles.skeletonHeader} />
            <div className={styles.skeletonLine} />
            <div className={`${styles.skeletonLine} ${styles.skeletonLineShort}`} />
            <div className={styles.skeletonLine} />
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

        {!loading && !error && (
          <>
            {noSelections && (
              <div className={styles.emptyDeck}>
                <div className={styles.emptyEmoji} aria-hidden="true">🌱</div>
                <h2 className={styles.emptyTitle}>Pick your interests first</h2>
                <p className={styles.emptySubtitle}>
                  Add some interests and competencies to your profile to find colleagues.
                </p>
                <button className={styles.emptyBtn} onClick={() => navigate('/profile')}>
                  Go to profile
                </button>
              </div>
            )}

            {allSwiped && (
              <div className={styles.emptyDeck}>
                <div className={styles.emptyEmoji} aria-hidden="true">🌱</div>
                <h2 className={styles.emptyTitle}>You're all caught up</h2>
                <p className={styles.emptySubtitle}>
                  You've seen everyone for now. Check who you matched with.
                </p>
                <button className={styles.emptyBtn} onClick={() => navigate('/matches')}>
                  View your matches
                </button>
              </div>
            )}

            {/* Back cards */}
            {back2Exists && <div className={`${styles.backCard} ${styles.backCard2}`} />}
            {back1Exists && (
              <div className={`${styles.backCard} ${styles.backCard1}`}>
                <CandidateCardContent card={stack[currentIndex + 1]} />
              </div>
            )}

            {/* Top card — key=currentIndex forces a fresh DOM node on each swipe,
                preventing stale opacity/transform inline styles from the fly-off animation */}
            {topCard && (
              <div
                key={currentIndex}
                ref={cardRef}
                className={styles.topCard}
                onPointerDown={onPointerDown}
                onPointerMove={onPointerMove}
                onPointerUp={onPointerUp}
                onPointerCancel={onPointerUp}
              >
                {/* LIKE badge */}
                <div
                  ref={likeBadgeRef}
                  className={styles.likeBadge}
                  aria-hidden="true"
                >
                  LIKE
                </div>
                {/* PASS badge */}
                <div
                  ref={passBadgeRef}
                  className={styles.passBadge}
                  aria-hidden="true"
                >
                  PASS
                </div>

                <CandidateCardContent card={topCard} />
              </div>
            )}
          </>
        )}
      </div>

      {topCard && !loading && !error && (
        <>
          <div className={styles.actions}>
            <button
              type="button"
              className={styles.passBtn}
              onClick={handlePass}
              disabled={swipeStatus !== 'idle' || !!pendingMatch}
              title="Pass"
            >
              ✕
            </button>
            <button
              type="button"
              className={styles.likeBtn}
              onClick={handleLike}
              disabled={swipeStatus !== 'idle' || !!pendingMatch}
              title="Like"
            >
              ♥
            </button>
          </div>
          <p className={styles.footerHint}>
            Drag the card or use the buttons · {remaining} colleague{remaining !== 1 ? 's' : ''} left
          </p>
        </>
      )}

      {/* Match overlay — shown when a mutual match is detected */}
      {pendingMatch && (
        <MatchOverlay
          match={pendingMatch}
          me={{ initials: meInitials }}
          onClose={() => setPendingMatch(null)}
          onViewMatches={() => {
            setPendingMatch(null);
            navigate('/matches');
          }}
        />
      )}
    </div>
  );
}



