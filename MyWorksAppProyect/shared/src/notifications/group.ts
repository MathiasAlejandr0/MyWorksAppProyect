export interface GroupableNotice {
  id: string;
  title: string;
  body: string;
  createdAt: string;
  read: boolean;
  relatedId: string | null;
}

export interface NoticeFolder<T extends GroupableNotice> {
  key: string;
  title: string;
  unreadCount: number;
  latestAt: string;
  items: T[];
}

const GENERAL = 'generales';

function time(value: string): number {
  const n = Date.parse(value);
  return Number.isFinite(n) ? n : 0;
}

/** Carpetas por trabajo. El aviso más reciente queda arriba, dentro y entre grupos. */
export function groupNoticesByJob<T extends GroupableNotice>(
  items: T[],
  jobTitles: Record<string, string> = {},
): NoticeFolder<T>[] {
  const buckets = new Map<string, T[]>();
  for (const item of items) {
    const related = item.relatedId?.trim() ?? '';
    const key = related.length > 0 ? related : GENERAL;
    const list = buckets.get(key);
    if (list) list.push(item);
    else buckets.set(key, [item]);
  }

  const folders: NoticeFolder<T>[] = [];
  for (const [key, list] of buckets) {
    const sorted = [...list].sort((a, b) => time(b.createdAt) - time(a.createdAt));
    const named = jobTitles[key]?.trim();
    folders.push({
      key,
      title: key === GENERAL ? 'Generales' : (named && named.length > 0 ? named : 'Pedido'),
      unreadCount: sorted.filter((item) => !item.read).length,
      latestAt: sorted[0]?.createdAt ?? '',
      items: sorted,
    });
  }

  folders.sort((a, b) => time(b.latestAt) - time(a.latestAt));
  return folders;
}
