/// Icon keys the dashboard stores in a service's `icon` field, mapped to 24×24 stroke paths.
/// Kept identical to the website so a service looks the same on every surface.
const Map<String, String> serviceIconPaths = {
  'design': 'M12 2.5a1.6 1.6 0 1 0 0 3.2 1.6 1.6 0 0 0 0-3.2zM11 5.4L5.5 20.5M13 5.4l5.5 15.1M8.2 14.5h7.6',
  'blueprint': 'M4 4.5h16v15H4zM4 9.5h16M9.5 9.5v10M13 13.5h4',
  'building': 'M5 21V5l9-2v18M14 8h5v13M3.5 21h17M9 8h1M9 12h1M9 16h1',
  'villa': 'M3.5 11L12 4l8.5 7M6 9.5V20h12V9.5M10 20v-5h4v5',
  'interior': 'M5 11V8a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v3M3 13a2 2 0 0 1 4 0v1h10v-1a2 2 0 0 1 4 0v5H3zM6 18v2M18 18v2',
  'supervision':
      'M3.5 17.5h17M5.5 17.5v-3a6.5 6.5 0 0 1 13 0v3M12 8V4.5M9 11.5V8.5',
  'construction': 'M6 21V3l12 4M6 6h13M18 7v5M17 12h2v2h-2zM3 21h6',
  'survey': 'M3.5 16.5l13-13 4 4-13 13zM7 13l2 2M10 10l2 2M13 7l2 2',
  'model3d': 'M12 3l8 4.5v9L12 21l-8-4.5v-9zM12 12l8-4.5M12 12L4 7.5M12 12v9',
  'landscape': 'M12 21v-6M12 3.5c3 0 5 2.2 5 4.8 1.3.8 2 2 2 3.4 0 2.3-2 4.3-4.5 4.3h-5C7 16 5 14 5 11.7c0-1.4.7-2.6 2-3.4 0-2.6 2-4.8 5-4.8z',
  'planning':
      'M3.5 6.5l5.5-2 6 2 5.5-2v13l-5.5 2-6-2-5.5 2zM9 4.5v13M15 6.5v13',
  'consulting': 'M4 5.5h16v10H12l-4.5 4v-4H4zM8 10h8',
  'estimate': 'M6 3.5h12v17H6zM8.5 6.5h7v3h-7zM9 13h.01M12 13h.01M15 13h.01M9 16.5h.01M12 16.5h.01M15 16.5h.01',
  'renovation': 'M20.5 6.8l-3.2 3.2-2.3-.7-.7-2.3 3.2-3.2a4.5 4.5 0 0 0-5.8 5.8L4 16.5a1.8 1.8 0 0 0 2.5 2.5l6.9-6.9a4.5 4.5 0 0 0 7.1-5.3z',
  'lighting': 'M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z',
  'structure': 'M4 8l8-4 8 4M5.5 8v10M10 8v10M14 8v10M18.5 8v10M3.5 20.5h17',
  'permit': 'M7 3.5h8l4 4v13H7zM15 3.5v4h4M9.5 12h6M9.5 15.5h6',
  'electrical': 'M13 2.5L5 13.5h6l-1 8 8-11h-6z',
  'plumbing': 'M12 3.5s6 6.2 6 10.5a6 6 0 0 1-12 0c0-4.3 6-10.5 6-10.5z',
  'management': 'M3.5 8h17v11h-17zM9 8V5.5h6V8M3.5 13h17',
};

String? serviceIconPath(String? key) =>
    key == null ? null : serviceIconPaths[key];
