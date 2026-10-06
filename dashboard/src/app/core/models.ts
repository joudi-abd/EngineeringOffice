export interface PageMeta {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export interface AuthUser {
  id: number;
  name: string;
  email: string;
  status: string;
  roles?: { id: number; name: string }[];
}

export interface ProjectCategory {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  is_active: boolean;
}

export interface Service {
  id: number;
  name: string;
  slug: string;
  short_description: string | null;
  description: string | null;
  icon: string | null;
  image_url: string | null;
  is_active: boolean;
}

export interface ProjectImage {
  id: number;
  project_id: number;
  image_path: string;
  image_url: string | null;
  alt_text: string | null;
}

export interface Project {
  id: number;
  title: string;
  slug: string;
  short_description: string | null;
  description: string | null;
  location: string | null;
  area: string | number | null;
  year: number | null;
  status: 'planning' | 'in_progress' | 'completed';
  cover_image: string | null;
  is_featured: boolean;
  published_at: string | null;
  category?: ProjectCategory | null;
  images?: ProjectImage[];
  services?: Service[];
}

export interface TeamMember {
  id: number;
  name: string;
  job_title: string;
  bio: string | null;
  image: string | null;
  image_url: string | null;
  is_active: boolean;
}

export interface Testimonial {
  id: number;
  project_id: number | null;
  client_name: string;
  content: string;
  rating: number;
  project?: { id: number; title: string } | null;
}

export interface ContactMessage {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  subject: string;
  message: string;
  status: 'new' | 'read';
  created_at: string;
}

export interface Setting {
  id: number;
  key: string;
  value: string | null;
  type: string;
}
