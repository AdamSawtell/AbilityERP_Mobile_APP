export interface WorkerUser {
  adUserId: number;
  adClientId: number;
  cBPartnerId: number;
  name: string;
  email: string;
  roles: string[];
}

export interface AuthResponse {
  token: string;
  user: WorkerUser;
}

export interface ApiError {
  error: string;
}
