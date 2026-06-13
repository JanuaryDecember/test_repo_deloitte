export interface MatchResult {
  matchId: number;
  matchedEmployeeId: number;
  firstName: string;
  lastName: string;
  initials: string;
  roleFamily: string;
  serviceLine: string;
  contactInfo: string;
  score: number;
  sharedInterests: string[];
  sharedCompetencies: string[];
  shareSummary: string;
}

export interface MatchItem {
  matchId: number;
  matchedEmployeeId: number;
  firstName: string;
  lastName: string;
  initials: string;
  roleFamily: string;
  serviceLine: string;
  contactInfo: string;
  score: number;
  sharedInterests: string[];
  sharedCompetencies: string[];
}

