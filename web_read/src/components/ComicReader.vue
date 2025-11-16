<template>
    <div class="comic-reader">
        <div class="header">
            <button @click="goBack" class="back-btn">← 返回</button>
            <h2>{{ title }}</h2>
            <div class="spacer"></div>
        </div>

        <div class="controls">
            <div class="chapter-selector">
                <button @click="prevChapter" :disabled="currentChapter === 0" class="nav-btn">
                    上一章
                </button>
                <select v-model="currentChapter" @change="onChapterChange" class="chapter-select">
                    <option v-for="(chapter, index) in chapters" :key="index" :value="index">
                        {{ getChapterTitle(chapter) }}
                    </option>
                </select>
                <button @click="nextChapter" :disabled="currentChapter === chapters.length - 1" class="nav-btn">
                    下一章
                </button>
            </div>

            <div class="page-info">
                第 {{ currentPage + 1 }} / {{ totalPages }} 页
            </div>
        </div>

        <div class="reader-content" @click="nextPage">
            <img v-if="currentImagePath" :src="currentImagePath" :alt="`Page ${currentPage + 1}`" class="page-image"
                @error="onImageError" />
            <div v-else class="no-image">
                图片加载失败
            </div>
        </div>

        <div class="page-controls">
            <button @click="prevPage" :disabled="currentPage === 0" class="page-btn">
                上一页
            </button>
            <button @click="nextPage" :disabled="currentPage === totalPages - 1" class="page-btn">
                下一页
            </button>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { getChapterImagePath, type ComicItem } from '../utils/comicScanner'
import type { BikaInfo, EpsDoc } from '../type/bika'
import type { JmInfo, Series } from '../type/jm'

const props = defineProps<{
    comic: ComicItem
}>()

const emit = defineEmits<{
    back: []
}>()

const currentChapter = ref(0)
const currentPage = ref(0)

const title = computed(() => {
    if (props.comic.type === 'bika') {
        return (props.comic.displayInfo as BikaInfo).comic.title
    } else {
        return (props.comic.displayInfo as JmInfo).name
    }
})

const chapters = computed(() => {
    if (props.comic.type === 'bika') {
        return (props.comic.displayInfo as BikaInfo).eps.docs
    } else {
        return (props.comic.displayInfo as JmInfo).series
    }
})

const totalPages = computed(() => {
    if (props.comic.type === 'bika') {
        const chapter = (props.comic.processedInfo as BikaInfo).eps.docs[currentChapter.value]
        return chapter?.pages.docs.length || 0
    } else {
        const chapter = (props.comic.processedInfo as JmInfo).series[currentChapter.value]
        return chapter?.info?.images.length || 0
    }
})

const currentImagePath = computed(() => {
    return getChapterImagePath(
        props.comic.type,
        props.comic.folderName,
        props.comic.processedInfo,
        currentChapter.value,
        currentPage.value
    )
})

function getChapterTitle(chapter: EpsDoc | Series): string {
    if (props.comic.type === 'bika') {
        return (chapter as EpsDoc).title
    } else {
        return (chapter as Series).name
    }
}

function prevChapter() {
    if (currentChapter.value > 0) {
        currentChapter.value--
        currentPage.value = 0
    }
}

function nextChapter() {
    if (currentChapter.value < chapters.value.length - 1) {
        currentChapter.value++
        currentPage.value = 0
    }
}

function prevPage() {
    if (currentPage.value > 0) {
        currentPage.value--
    } else if (currentChapter.value > 0) {
        prevChapter()
        currentPage.value = totalPages.value - 1
    }
}

function nextPage() {
    if (currentPage.value < totalPages.value - 1) {
        currentPage.value++
    } else if (currentChapter.value < chapters.value.length - 1) {
        nextChapter()
    }
}

function onChapterChange() {
    currentPage.value = 0
}

function goBack() {
    emit('back')
}

function onImageError() {
    console.error('Image load error:', currentImagePath.value)
}

// 键盘导航
function handleKeyPress(event: KeyboardEvent) {
    if (event.key === 'ArrowLeft') {
        prevPage()
    } else if (event.key === 'ArrowRight') {
        nextPage()
    }
}

// 添加键盘事件监听
if (typeof window !== 'undefined') {
    window.addEventListener('keydown', handleKeyPress)
}
</script>

<style scoped>
.comic-reader {
    min-height: 100vh;
    background: #f5f5f5;
    display: flex;
    flex-direction: column;
}

.header {
    background: #fff;
    padding: 15px 20px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    gap: 20px;
}

.back-btn {
    padding: 8px 16px;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background 0.2s;
}

.back-btn:hover {
    background: #f5f5f5;
}

.header h2 {
    margin: 0;
    font-size: 18px;
    color: #333;
    flex: 1;
}

.spacer {
    width: 80px;
}

.controls {
    background: #fff;
    padding: 15px 20px;
    border-bottom: 1px solid #e0e0e0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 15px;
}

.chapter-selector {
    display: flex;
    gap: 10px;
    align-items: center;
}

.nav-btn {
    padding: 8px 16px;
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background 0.2s;
}

.nav-btn:hover:not(:disabled) {
    background: #45a049;
}

.nav-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
}

.chapter-select {
    padding: 8px 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 14px;
    min-width: 200px;
}

.page-info {
    font-size: 14px;
    color: #666;
}

.reader-content {
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 20px;
    cursor: pointer;
    overflow: auto;
}

.page-image {
    max-width: 100%;
    max-height: calc(100vh - 200px);
    object-fit: contain;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.no-image {
    padding: 50px;
    text-align: center;
    color: #999;
    font-size: 16px;
}

.page-controls {
    background: #fff;
    padding: 15px 20px;
    border-top: 1px solid #e0e0e0;
    display: flex;
    justify-content: center;
    gap: 20px;
}

.page-btn {
    padding: 10px 30px;
    background: #2196F3;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background 0.2s;
}

.page-btn:hover:not(:disabled) {
    background: #0b7dda;
}

.page-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
}
</style>
