<template>
    <div class="comic-list">
        <h1>漫画阅读器</h1>

        <div v-if="loading" class="loading">加载中...</div>

        <div v-else>
            <section class="comic-section">
                <h2>哔咔漫画 ({{ bikaComics.length }})</h2>
                <div class="comic-grid">
                    <div v-for="comic in bikaComics" :key="comic.folderName" class="comic-card"
                        @click="openComic(comic)">
                        <img :src="comic.coverPath" :alt="getTitle(comic)" class="cover" />
                        <div class="info">
                            <h3>{{ getTitle(comic) }}</h3>
                            <p class="author">{{ getAuthor(comic) }}</p>
                            <p class="stats">{{ getChapterCount(comic) }} 章</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="comic-section">
                <h2>禁漫漫画 ({{ jmComics.length }})</h2>
                <div class="comic-grid">
                    <div v-for="comic in jmComics" :key="comic.folderName" class="comic-card" @click="openComic(comic)">
                        <img :src="comic.coverPath" :alt="getTitle(comic)" class="cover" />
                        <div class="info">
                            <h3>{{ getTitle(comic) }}</h3>
                            <p class="author">{{ getAuthor(comic) }}</p>
                            <p class="stats">{{ getChapterCount(comic) }} 章</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { scanComics, type ComicItem } from '../utils/comicScanner'
import type { BikaInfo } from '../type/bika'
import type { JmInfo } from '../type/jm'

const bikaComics = ref<ComicItem[]>([])
const jmComics = ref<ComicItem[]>([])
const loading = ref(true)

const emit = defineEmits<{
    openComic: [comic: ComicItem]
}>()

onMounted(async () => {
    const comics = await scanComics()
    bikaComics.value = comics.bika
    jmComics.value = comics.jm
    loading.value = false
})

function getTitle(comic: ComicItem): string {
    if (comic.type === 'bika') {
        return (comic.displayInfo as BikaInfo).comic.title
    } else {
        return (comic.displayInfo as JmInfo).name
    }
}

function getAuthor(comic: ComicItem): string {
    if (comic.type === 'bika') {
        return (comic.displayInfo as BikaInfo).comic.author || '未知'
    } else {
        const authors = (comic.displayInfo as JmInfo).author
        return authors && authors.length > 0 ? authors.join(', ') : '未知'
    }
}

function getChapterCount(comic: ComicItem): number {
    if (comic.type === 'bika') {
        return (comic.displayInfo as BikaInfo).eps.docs.length
    } else {
        return (comic.displayInfo as JmInfo).series.length
    }
}

function openComic(comic: ComicItem) {
    emit('openComic', comic)
}
</script>

<style scoped>
.comic-list {
    padding: 20px;
    max-width: 1400px;
    margin: 0 auto;
}

h1 {
    text-align: center;
    margin-bottom: 30px;
    color: #333;
}

.loading {
    text-align: center;
    padding: 50px;
    font-size: 18px;
    color: #666;
}

.comic-section {
    margin-bottom: 50px;
}

.comic-section h2 {
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 2px solid #e0e0e0;
    color: #555;
}

.comic-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 20px;
}

.comic-card {
    cursor: pointer;
    border-radius: 8px;
    overflow: hidden;
    background: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s, box-shadow 0.2s;
}

.comic-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.cover {
    width: 100%;
    height: 280px;
    object-fit: cover;
    display: block;
}

.info {
    padding: 12px;
}

.info h3 {
    margin: 0 0 8px 0;
    font-size: 14px;
    font-weight: 600;
    color: #333;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    line-height: 1.4;
    min-height: 2.8em;
}

.author {
    margin: 0 0 4px 0;
    font-size: 12px;
    color: #666;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.stats {
    margin: 0;
    font-size: 12px;
    color: #999;
}
</style>
