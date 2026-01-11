export enum AttachmentType {
  IMAGE = 'IMAGE',
  VIDEO = 'VIDEO',
  FILE = 'FILE'
}

export interface Attachment {
  id: string;
  type: AttachmentType;
  url: string; // In a real app, this would be a Supabase Storage URL
  name: string;
  createdAt: number;
}

export interface Comment {
  id: string;
  text: string;
  author: string;
  createdAt: number;
}

export enum LogAction {
  CREATED = 'CREATED',
  MOVED = 'MOVED',
  COMMENT_ADDED = 'COMMENT_ADDED',
  ATTACHMENT_ADDED = 'ATTACHMENT_ADDED',
  UPDATED = 'UPDATED'
}

export interface LogEntry {
  id: string;
  action: LogAction;
  timestamp: number;
  details: string; // e.g., "Moved from To Do to Done"
}

export interface CardData {
  id: string;
  columnId: string;
  title: string;
  description: string;
  attachments: Attachment[];
  comments: Comment[];
  history: LogEntry[];
  
  // Time Tracking
  createdAt: number;
  lastMovedAt: number; // Timestamp when it entered the current column
  timeInColumns: Record<string, number>; // Map of ColumnID -> Total Milliseconds spent
}

export interface ColumnData {
  id: string;
  title: string;
  order: number;
}

// Dynamic stage types for pipeline columns
export interface SalesStageData {
  id: string;
  title: string;
  order: number;
  color?: string;
}

export interface JobStageData {
  id: string;
  title: string;
  order: number;
  color?: string;
}

// ===== SALES PIPELINE TYPES =====
export type SalesStage = 'leads' | 'appointments' | 'presentations' | 'sales';

export const SALES_STAGES: SalesStage[] = ['leads', 'appointments', 'presentations', 'sales'];

export const SALES_STAGE_LABELS: Record<SalesStage, { en: string; pt: string }> = {
  leads: { en: 'Leads', pt: 'Leads' },
  appointments: { en: 'Appointments', pt: 'Agendamentos' },
  presentations: { en: 'Presentations', pt: 'Apresentações' },
  sales: { en: 'Sales', pt: 'Vendas' }
};

// Client type enum
export type ClientType = 'agencia' | 'produtora' | 'anunciante';

export const CLIENT_TYPE_LABELS: Record<ClientType, { en: string; pt: string }> = {
  agencia: { en: 'Agency', pt: 'Agência' },
  produtora: { en: 'Production Company', pt: 'Produtora' },
  anunciante: { en: 'Advertiser', pt: 'Anunciante' }
};

export interface ClientData {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  company?: string;
  notes?: string;
  client_type?: ClientType;
  custom_fields?: Record<string, string>;
  stage: SalesStage;
  stage_order: number;
  created_by?: string;
  created_at: string;
  updated_at: string;
  converted_at?: string;
}

// Client comments
export interface ClientComment {
  id: string;
  client_id: string;
  author_id: string;
  author_name?: string;
  author_email?: string;
  text: string;
  created_at: string;
}

// Client attachments
export interface ClientAttachment {
  id: string;
  client_id: string;
  file_name: string;
  file_url: string;
  file_type?: string;
  uploaded_by?: string;
  created_at: string;
}

// Client members (access control)
export interface ClientMember {
  id: string;
  client_id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  added_by?: string;
  added_at: string;
}

// ===== JOBS PIPELINE TYPES =====
export type JobStage = 
  | 'aprovacao' 
  | 'contrato_enviado' 
  | 'contrato_assinado' 
  | 'cadastro' 
  | 'nota_emitida' 
  | 'em_producao' 
  | 'entrega_executada' 
  | 'pagamento_efetuado';

export const JOB_STAGES: JobStage[] = [
  'aprovacao',
  'contrato_enviado',
  'contrato_assinado',
  'cadastro',
  'nota_emitida',
  'em_producao',
  'entrega_executada',
  'pagamento_efetuado'
];

export const JOB_STAGE_LABELS: Record<JobStage, { en: string; pt: string }> = {
  aprovacao: { en: 'Approval', pt: 'Aprovação' },
  contrato_enviado: { en: 'Contract Sent', pt: 'Contrato Enviado' },
  contrato_assinado: { en: 'Contract Signed', pt: 'Contrato Assinado' },
  cadastro: { en: 'Registration', pt: 'Cadastro' },
  nota_emitida: { en: 'Invoice Issued', pt: 'Nota Emitida' },
  em_producao: { en: 'In Production', pt: 'Em Produção' },
  entrega_executada: { en: 'Delivery Done', pt: 'Entrega Executada' },
  pagamento_efetuado: { en: 'Payment Made', pt: 'Pagamento Efetuado' }
};

export interface JobData {
  id: string;
  client_id?: string;
  client?: ClientData;
  project_id?: string;
  title: string;
  description?: string;
  value?: number;
  agencia?: string;
  produtora?: string;
  stage: JobStage;
  stage_order: number;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

// Job members (access control)
export interface JobMember {
  id: string;
  job_id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  added_by?: string;
  added_at: string;
}

// Job comments
export interface JobComment {
  id: string;
  job_id: string;
  author_id: string;
  author_name?: string;
  author_email?: string;
  text: string;
  created_at: string;
}

// Job attachments
export interface JobAttachment {
  id: string;
  job_id: string;
  file_name: string;
  file_url: string;
  file_type?: string;
  uploaded_by?: string;
  created_at: string;
}

// ===== SERVICES TYPES =====
export type ServiceStatus = 'pending' | 'in_progress' | 'completed';

export const SERVICE_STATUS_LABELS: Record<ServiceStatus, { en: string; pt: string }> = {
  pending: { en: 'Pending', pt: 'Pendente' },
  in_progress: { en: 'In Progress', pt: 'Em Progresso' },
  completed: { en: 'Completed', pt: 'Concluído' }
};

export interface ServiceData {
  id: string;
  job_id: string;
  name: string;
  description?: string;
  project_id?: string;
  project_name?: string;
  status: ServiceStatus;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface ProjectMember {
  id: string;
  project_id: string;
  user_id: string;
  role: 'admin' | 'team' | 'client';
  added_at: string;
  user_email?: string;
  user_name?: string;
}
