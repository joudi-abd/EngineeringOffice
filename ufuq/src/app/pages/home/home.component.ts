import { Component, HostListener } from '@angular/core';

interface MenuLink {
  label: string;
  href: string;
}

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss',
})
export class HomeComponent {
  readonly aboutLinks: MenuLink[] = [
    { label: 'The complex', href: '#about' },
    { label: 'Architecture', href: '#architecture' },
    { label: 'Location', href: '#location' },
    { label: 'Amenities', href: '#amenities' },
  ];

  readonly apartmentTypes = [
    'Studio',
    '1 Bedroom',
    '2 Bedrooms',
    '3 Bedrooms',
    'Penthouse',
  ];

  readonly stages = [
    { index: '01', name: 'Foundations', state: 'Complete' },
    { index: '02', name: 'Structure', state: 'In progress' },
    { index: '03', name: 'Facade', state: 'Scheduled' },
    { index: '04', name: 'Interiors', state: 'Scheduled' },
  ];

  aboutOpen = false;
  apartmentsOpen = false;
  menuOpen = false;
  saved = false;
  scrolled = false;
  selectedType: string | null = null;

  toggleAbout(event: Event): void {
    event.stopPropagation();
    this.aboutOpen = !this.aboutOpen;
    this.apartmentsOpen = false;
  }

  toggleApartments(event: Event): void {
    event.stopPropagation();
    this.apartmentsOpen = !this.apartmentsOpen;
    this.aboutOpen = false;
  }

  toggleMenu(event: Event): void {
    event.stopPropagation();
    this.menuOpen = !this.menuOpen;
    this.aboutOpen = false;
    this.apartmentsOpen = false;
  }

  toggleSaved(): void {
    this.saved = !this.saved;
  }

  chooseApartment(type: string): void {
    this.selectedType = type;
    this.apartmentsOpen = false;
    this.menuOpen = false;
  }

  follow(event: Event, href: string): void {
    event.preventDefault();
    this.aboutOpen = false;
    this.apartmentsOpen = false;
    this.menuOpen = false;
    document.getElementById(href.slice(1))?.scrollIntoView({ behavior: 'smooth' });
  }

  closeOverlays(): void {
    this.aboutOpen = false;
    this.apartmentsOpen = false;
    this.menuOpen = false;
  }

  scrollNext(): void {
    document.getElementById('about')?.scrollIntoView({ behavior: 'smooth' });
  }

  @HostListener('document:click')
  onDocumentClick(): void {
    this.aboutOpen = false;
    this.apartmentsOpen = false;
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    this.closeOverlays();
  }

  @HostListener('window:scroll')
  onWindowScroll(): void {
    this.scrolled = window.scrollY > 24;
  }
}
