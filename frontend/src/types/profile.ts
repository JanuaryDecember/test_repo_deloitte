export interface CatalogItem {
  id: number;
  name: string;
}

export interface CatalogResponse {
  interests: CatalogItem[];
  competencies: CatalogItem[];
}

export interface UserProfile {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  serviceLine: string;
  roleFamily: string;
  contactInfo: string;
  initials: string;
}

export interface SelectionsResponse {
  interestIds: number[];
  competencyIds: number[];
}

export interface SelectionsRequest {
  interestIds: number[];
  competencyIds: number[];
}
