import { Routes } from '@angular/router';

import { profileGuard } from './core/profile.guard';
import { AboutComponent } from './pages/about/about.component';
import { HomeComponent } from './pages/home/home.component';
import { ProjectDetailComponent } from './pages/project-detail/project-detail.component';
import { ProjectsComponent } from './pages/projects/projects.component';
import { ServicesComponent } from './pages/services/services.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'about', component: AboutComponent },
  { path: 'services', component: ServicesComponent },
  { path: 'projects', component: ProjectsComponent },
  { path: 'projects/:slug', component: ProjectDetailComponent },
  {
    path: 'profile',
    canActivate: [profileGuard],
    loadComponent: () => import('./pages/profile/profile.component').then((m) => m.ProfileComponent),
  },
];

