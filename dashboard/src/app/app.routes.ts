import { Routes } from '@angular/router';
import { authGuard, guestGuard } from './core/auth.guard';
import { ShellComponent } from './layout/shell.component';
import { CategoriesComponent } from './pages/categories/categories.component';
import { CategoryEditorComponent } from './pages/categories/category-editor.component';
import { LoginComponent } from './pages/login/login.component';
import { MessageDetailComponent } from './pages/messages/message-detail.component';
import { MessagesComponent } from './pages/messages/messages.component';
import { OverviewComponent } from './pages/overview/overview.component';
import { ProjectEditorComponent } from './pages/projects/project-editor.component';
import { ProjectsComponent } from './pages/projects/projects.component';
import { ServiceEditorComponent } from './pages/services/service-editor.component';
import { ServicesComponent } from './pages/services/services.component';
import { SettingsComponent } from './pages/settings/settings.component';
import { TeamEditorComponent } from './pages/team/team-editor.component';
import { TeamComponent } from './pages/team/team.component';
import { TestimonialEditorComponent } from './pages/testimonials/testimonial-editor.component';
import { TestimonialsComponent } from './pages/testimonials/testimonials.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
  {
    path: '',
    component: ShellComponent,
    canActivate: [authGuard],
    children: [
      { path: '', component: OverviewComponent },
      { path: 'categories', component: CategoriesComponent },
      { path: 'categories/new', component: CategoryEditorComponent },
      { path: 'categories/:id', component: CategoryEditorComponent },
      { path: 'projects', component: ProjectsComponent },
      { path: 'projects/new', component: ProjectEditorComponent },
      { path: 'projects/:id', component: ProjectEditorComponent },
      { path: 'services', component: ServicesComponent },
      { path: 'services/new', component: ServiceEditorComponent },
      { path: 'services/:id', component: ServiceEditorComponent },
      { path: 'team', component: TeamComponent },
      { path: 'team/new', component: TeamEditorComponent },
      { path: 'team/:id', component: TeamEditorComponent },
      { path: 'testimonials', component: TestimonialsComponent },
      { path: 'testimonials/:id', component: TestimonialEditorComponent },
      { path: 'messages', component: MessagesComponent },
      { path: 'messages/:id', component: MessageDetailComponent },
      { path: 'settings', component: SettingsComponent },
    ],
  },
  { path: '**', redirectTo: '' },
];
