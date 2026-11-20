import { useEffect } from 'react';

const SITE = 'MyWorksApp';

export function usePageMeta(title: string, description: string, noindex = false) {
  useEffect(() => {
    const previousTitle = document.title;
    document.title = title.includes(SITE) ? title : `${title} — ${SITE}`;
    let meta = document.querySelector('meta[name="description"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'description');
      document.head.appendChild(meta);
    }
    const previousDescription = meta.getAttribute('content');
    meta.setAttribute('content', description);
    const og = document.querySelector('meta[property="og:description"]');
    const previousOg = og?.getAttribute('content') ?? null;
    if (og) og.setAttribute('content', description);
    let robots = document.querySelector('meta[name="robots"]');
    if (noindex) {
      if (!robots) {
        robots = document.createElement('meta');
        robots.setAttribute('name', 'robots');
        document.head.appendChild(robots);
      }
      robots.setAttribute('content', 'noindex');
    } else if (robots) {
      robots.remove();
    }
    return () => {
      document.title = previousTitle;
      if (previousDescription == null) meta.remove();
      else meta.setAttribute('content', previousDescription);
      if (og) {
        if (previousOg == null) og.removeAttribute('content');
        else og.setAttribute('content', previousOg);
      }
    };
  }, [title, description, noindex]);
}
