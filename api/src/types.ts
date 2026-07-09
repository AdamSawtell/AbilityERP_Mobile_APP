export interface JwtPayload {
  adUserId: number;
  adClientId: number;
  cBPartnerId: number;
  name: string;
  email: string;
  roles: string[];
}

export interface AdUserRow {
  ad_user_id: number;
  ad_client_id: number;
  c_bpartner_id: number | null;
  name: string;
  email: string | null;
  password: string | null;
  isactive: string;
  islocked: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}
