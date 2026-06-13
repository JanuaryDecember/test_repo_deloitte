export interface CandidateCard {
  id: number;
  firstName: string;
  lastName: string;
  initials: string;
  roleFamily: string;
  serviceLine: string;
  contactInfo: string;
  sharedInterests: string[];
  sharedCompetencies: string[];
}

export interface SwipeRequest {
  candidateId: number;
  liked: boolean;
}

import type { MatchResult } from './match';

export interface SwipeResponse {
  success: boolean;
  match: MatchResult | null;
}

