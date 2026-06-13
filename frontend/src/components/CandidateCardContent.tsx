import type { CandidateCard } from '../types/discover';
import { getAccentColor } from '../utils/accentColor';
import styles from './CandidateCardContent.module.css';

interface Props {
  card: CandidateCard;
}

export function CandidateCardContent({ card }: Props) {
  return (
    <>
      {/* Gradient header with avatar */}
      <div className={styles.cardHeader}>
        <div
          className={styles.avatar}
          style={{ background: getAccentColor(card.id) }}
        >
          {card.initials}
        </div>
      </div>

      {/* Info section */}
      <div className={styles.cardInfo}>
        <h2 className={styles.candidateName}>
          {card.firstName} {card.lastName}
        </h2>
        <p className={styles.candidateMeta}>
          {card.roleFamily} · {card.serviceLine}
        </p>
        <p className={styles.candidateOffice}>📍 {card.contactInfo}</p>

        {(card.sharedInterests.length > 0 || card.sharedCompetencies.length > 0) && (
          <>
            <p className={styles.sharedLabel}>You both share</p>
            <div className={styles.chips}>
              {card.sharedInterests.map((tag) => (
                <span key={tag} className={styles.interestChip}>{tag}</span>
              ))}
              {card.sharedCompetencies.map((c) => (
                <span key={c} className={styles.competencyChip}>{c}</span>
              ))}
            </div>
          </>
        )}
      </div>
    </>
  );
}
