import type { BikaInfo } from "../type/bika";
import type { JmInfo } from "../type/jm";

export interface ComicItem {
  type: "bika" | "jm";
  folderName: string; // 存储编码后的文件夹名 (e.g., %E6%97%A0%E6%B3%95...)
  displayInfo: BikaInfo | JmInfo;
  processedInfo: BikaInfo | JmInfo;
  coverPath: string;
}

/**
 * 统一的漫画扫描函数
 */
export async function scanComics(): Promise<{
  bika: ComicItem[];
  jm: ComicItem[];
}> {
  const bikaComics: ComicItem[] = [];
  const jmComics: ComicItem[] = [];

  try {
    const response = await fetch("/api/list-comics");
    if (!response.ok) {
      throw new Error(
        `Failed to fetch /api/list-comics: ${response.statusText}`
      );
    }

    const manifest = (await response.json()) as {
      bika: string[];
      jm: string[];
    };

    console.log("Manifest:", manifest);

    for (const folder of manifest.bika) {
      try {
        const encodedFolder = encodeURIComponent(folder);

        const [displayInfo, processedInfo] = await Promise.all([
          fetchComicInfo(
            `/comics/bika/${encodedFolder}/comic_info.json`,
            `/comics/bika/${encodedFolder}/comic_info_string.json`
          ),
          fetchComicInfo(
            `/comics/bika/${encodedFolder}/processed_comic_info.json`,
            `/comics/bika/${encodedFolder}/processed_comic_info_string.json`
          ),
        ]);

        if (displayInfo && processedInfo) {
          const coverPath = getCoverPath("bika", encodedFolder);
          bikaComics.push({
            type: "bika",
            folderName: encodedFolder, // [!code focus] 存储编码后的名称
            displayInfo: displayInfo as BikaInfo,
            processedInfo: processedInfo as BikaInfo,
            coverPath,
          });
        } else {
          console.warn(`[Bika] Missing info files for: ${folder}`, {
            hasDisplayInfo: !!displayInfo,
            hasProcessedInfo: !!processedInfo,
          });
        }
      } catch (e) {
        console.warn(`Failed to load bika comic: ${folder}`, e);
      }
    }

    for (const folder of manifest.jm) {
      try {
        const encodedFolder = encodeURIComponent(folder);

        const [displayInfo, processedInfo] = await Promise.all([
          fetchComicInfo(`/comics/jm/${encodedFolder}/comic_info.json`),
          fetchComicInfo(
            `/comics/jm/${encodedFolder}/processed_comic_info.json`
          ),
        ]);

        if (displayInfo && processedInfo) {
          const coverPath = getCoverPath("jm", encodedFolder);
          jmComics.push({
            type: "jm",
            folderName: encodedFolder, // [!code focus]
            displayInfo: displayInfo as JmInfo,
            processedInfo: processedInfo as JmInfo,
            coverPath,
          });
        } else {
          console.warn(`[JM] Missing info files for: ${folder}`, {
            hasDisplayInfo: !!displayInfo,
            hasProcessedInfo: !!processedInfo,
          });
        }
      } catch (e) {
        console.warn(`Failed to load jm comic: ${folder}`, e);
      }
    }
  } catch (error) {
    console.error("Failed to scan comics:", error);
  }

  return { bika: bikaComics, jm: jmComics };
}

async function fetchComicInfo(
  primaryPath: string,
  fallbackPath?: string
): Promise<BikaInfo | JmInfo | null> {
  try {
    const response = await fetch(primaryPath);
    if (response.ok) {
      return await response.json();
    }
  } catch (e) {
    console.log(`[Fetch] Primary error: ${primaryPath}`, e);
  }

  if (fallbackPath) {
    try {
      const response = await fetch(fallbackPath);
      if (response.ok) {
        return await response.json();
      }
    } catch (e) {
      console.log(`[Fetch] Fallback error: ${fallbackPath}`, e);
    }
  }
  return null;
}

function getCoverPath(type: "bika" | "jm", folderName: string): string {
  if (type === "bika") {
    return `/comics/bika/${folderName}/cover/cover.jpg`;
  } else {
    return `/comics/jm/${folderName}/cover/cover.jpg`;
  }
}

export function getChapterImagePath(
  type: "bika" | "jm",
  folderName: string,
  processedInfo: BikaInfo | JmInfo,
  chapterIndex: number,
  pageIndex: number
): string {
  if (type === "bika") {
    const bikaInfo = processedInfo as BikaInfo;
    const chapter = bikaInfo.eps.docs[chapterIndex];
    if (!chapter) return "";
    const page = chapter.pages.docs[pageIndex];
    if (!page) return "";
    const fileName = page.media.originalName;
    return `/comics/bika/${folderName}/eps/${chapter.title}/${fileName}`;
  } else {
    const jmInfo = processedInfo as JmInfo;
    const chapter = jmInfo.series[chapterIndex];
    if (!chapter || !chapter.info) return "";
    const fileName = chapter.info.images[pageIndex];
    if (!fileName) return "";
    return `/comics/jm/${folderName}/eps/${chapter.name}/${fileName}`;
  }
}
