(() => {
  const {
    Headers,
    AbortController,
    AbortSignal,
    Request,
    Response,
    fetch,
    fs,
    FSError,
    native,
    wasi,
    console,
    bridge,
    URL,
    URLSearchParams,
    Blob,
    File,
    FormData,
    crypto,
    uuidv4,
    TextEncoder,
    TextDecoder,
    Buffer,
  } = globalThis.__web;

  globalThis.Headers = Headers;
  globalThis.AbortController = AbortController;
  globalThis.AbortSignal = AbortSignal;
  globalThis.Request = Request;
  globalThis.Response = Response;
  globalThis.fetch = fetch;
  globalThis.fs = fs;
  globalThis.FSError = FSError;
  globalThis.native = native;
  globalThis.wasi = wasi;
  globalThis.console = console;
  globalThis.bridge = bridge;
  globalThis.URL = URL;
  globalThis.URLSearchParams = URLSearchParams;
  globalThis.Blob = Blob;
  globalThis.File = File;
  globalThis.FormData = FormData;
  globalThis.crypto = crypto;
  globalThis.uuidv4 = uuidv4;
  globalThis.TextEncoder = TextEncoder;
  globalThis.TextDecoder = TextDecoder;
  globalThis.Buffer = Buffer;
})();
