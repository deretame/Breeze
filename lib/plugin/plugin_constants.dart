const String kBikaPluginUuid = '0a0e5858-a467-4702-994a-79e608a4589d';
const String kJmPluginUuid = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';

const Map<String, String> kBuiltinRuntimeNameByUuid = {
  kBikaPluginUuid: 'bikaComic',
  kJmPluginUuid: 'jmComic',
};

String sanitizePluginId(String raw) {
  return raw.trim();
}
