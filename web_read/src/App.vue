<script setup lang="ts">
import { ref } from 'vue'
import ComicList from './components/ComicList.vue'
import ComicReader from './components/ComicReader.vue'
import type { ComicItem } from './utils/comicScanner'

const currentView = ref<'list' | 'reader'>('list')
const selectedComic = ref<ComicItem | null>(null)

function openComic(comic: ComicItem) {
  selectedComic.value = comic
  currentView.value = 'reader'
}

function backToList() {
  currentView.value = 'list'
  selectedComic.value = null
}
</script>

<template>
  <div class="app">
    <ComicList v-if="currentView === 'list'" @open-comic="openComic" />
    <ComicReader v-else-if="currentView === 'reader' && selectedComic" :comic="selectedComic" @back="backToList" />
  </div>
</template>

<style>
* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

.app {
  min-height: 100vh;
  background: #f5f5f5;
}
</style>
